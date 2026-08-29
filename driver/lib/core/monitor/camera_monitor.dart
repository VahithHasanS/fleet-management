import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import 'face_analyzer.dart';
import 'face_analyzer_impl.dart';

/// Driver cabin-camera monitor.
///
/// 1. Opens the front (cabin-facing) camera at low resolution.
/// 2. Captures a JPEG frame every [interval] while a trip is active.
/// 3. Streams the frame to the backend (`video:frame`) so fleet managers can
///    watch the live cabin feed from the admin Video Telematics screen.
/// 4. Runs the platform face analyzer (MediaPipe Face Mesh on web, ML Kit on
///    Android) and turns sustained eye closure into real breach events
///    (`video:breach` → persisted camera breach + admin live alert).
class CameraMonitor {
  CameraMonitor();

  static const Duration interval = Duration(seconds: 2);
  static const Duration _eyeClosureBreachAfter = Duration(milliseconds: 2200);
  static const Duration _drowsinessBreachAfter = Duration(milliseconds: 5500);
  static const Duration _noFaceBreachAfter = Duration(seconds: 12);

  CameraController? controller;
  final FaceAnalyzerImpl _analyzer = FaceAnalyzerImpl();

  bool get initialized => controller?.value.isInitialized ?? false;
  bool get detectionAvailable => _analyzer.available;
  bool streaming = false;
  bool detecting = false;
  String? lastError;
  String? lastBreach;
  DateTime? lastFrameAt;

  bool _enabled = false;
  bool _busy = false;
  Timer? _timer;
  DateTime? _eyesClosedSince;
  bool _eyeClosureFired = false;
  bool _drowsinessFired = false;
  DateTime? _faceMissingSince;
  bool _noFaceFired = false;

  /// Set by the app state layer: pushes frames + breaches to the backend.
  Future<bool> Function(Map<String, dynamic> frame)? onFrame;
  Future<bool> Function(Map<String, dynamic> breach)? onBreach;
  VoidCallback? onStateChanged;

  Future<bool> start() async {
    if (_enabled) return true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        lastError = 'No camera available on this device';
        onStateChanged?.call();
        return false;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final cam = CameraController(front, ResolutionPreset.low, enableAudio: false);
      await cam.initialize();
      controller = cam;
      _enabled = true;
      lastError = null;
      _timer = Timer.periodic(interval, (_) => _tick());
      onStateChanged?.call();
      return true;
    } catch (e) {
      lastError = 'Camera init failed: $e';
      onStateChanged?.call();
      return false;
    }
  }

  void stop() {
    _enabled = false;
    _timer?.cancel();
    _timer = null;
    streaming = false;
    detecting = false;
    _resetEpisode();
    controller?.dispose();
    controller = null;
    onStateChanged?.call();
  }

  void _resetEpisode() {
    _eyesClosedSince = null;
    _eyeClosureFired = false;
    _drowsinessFired = false;
    _faceMissingSince = null;
    _noFaceFired = false;
  }

  Future<void> _tick() async {
    final cam = controller;
    if (!_enabled || _busy || cam == null || !cam.value.isInitialized) return;
    _busy = true;
    try {
      final file = await cam.takePicture();
      final bytes = await file.readAsBytes();
      lastFrameAt = DateTime.now();

      // 1) Live cabin feed to the admin (backend relays to the `video:` room).
      if (onFrame != null) {
        final payload = _framePayload(bytes);
        streaming = await onFrame!(payload);
      }

      // 2) Real drowsiness detection.
      if (onBreach != null) {
        final analysis = await _analyzer.analyze(bytes);
        detecting = analysis != null;
        if (analysis != null) await _evaluate(analysis, bytes);
      }
    } catch (e) {
      lastError = e.toString();
    } finally {
      _busy = false;
      onStateChanged?.call();
    }
  }

  Future<void> _evaluate(FaceAnalysis analysis, Uint8List bytes) async {
    final now = DateTime.now();
    if (!analysis.faceFound) {
      _eyesClosedSince = null;
      _faceMissingSince ??= now;
      if (!_noFaceFired && now.difference(_faceMissingSince!) > _noFaceBreachAfter) {
        _noFaceFired = true;
        await _fireBreach(
          type: 'camera_obstructed',
          severity: 'medium',
          durationMs: now.difference(_faceMissingSince!).inMilliseconds,
          confidence: analysis.confidence,
          detail: 'No face visible in the cabin camera for ${_noFaceBreachAfter.inSeconds}s',
          bytes: bytes,
        );
      }
      return;
    }
    _faceMissingSince = null;
    _noFaceFired = false;
    if (analysis.eyesClosed) {
      _eyesClosedSince ??= now;
      final closed = now.difference(_eyesClosedSince!);
      if (!_eyeClosureFired && closed >= _eyeClosureBreachAfter) {
        _eyeClosureFired = true;
        await _fireBreach(
          type: 'eye_closure',
          severity: 'high',
          durationMs: closed.inMilliseconds,
          confidence: analysis.confidence,
          ear: analysis.ear >= 0 ? analysis.ear : null,
          detail: 'Eyes closed ${closed.inMilliseconds}ms'
              '${analysis.ear >= 0 ? ' (EAR ${analysis.ear.toStringAsFixed(2)})' : ''}',
          bytes: bytes,
        );
      }
      if (!_drowsinessFired && closed >= _drowsinessBreachAfter) {
        _drowsinessFired = true;
        await _fireBreach(
          type: 'drowsiness',
          severity: 'critical',
          durationMs: closed.inMilliseconds,
          confidence: analysis.confidence,
          ear: analysis.ear >= 0 ? analysis.ear : null,
          detail: 'Driver unresponsive with eyes closed for ${closed.inSeconds}s',
          bytes: bytes,
        );
      }
    } else {
      _resetEpisode();
    }
  }

  Future<void> _fireBreach({
    required String type,
    required String severity,
    required int durationMs,
    required double confidence,
    double? ear,
    String? detail,
    Uint8List? bytes,
  }) async {
    lastBreach = type;
    final breach = <String, dynamic>{
      'breachType': type,
      'severity': severity,
      'durationMs': durationMs,
      'confidence': confidence,
      if (ear != null) 'ear': ear,
      if (detail != null) 'detail': detail,
      // Snapshot thumbnail for the admin breach list.
      if (bytes != null && bytes.length < 160_000) 'snapshot': base64Encode(bytes),
    };
    try {
      await onBreach!(breach);
    } catch (_) {
      // Breach delivery failures are non-fatal for the monitor loop.
    }
  }
}

Map<String, dynamic> _framePayload(Uint8List bytes) {
  return <String, dynamic>{
    'ts': DateTime.now().toUtc().millisecondsSinceEpoch,
    'jpg': base64Encode(bytes),
  };
}
