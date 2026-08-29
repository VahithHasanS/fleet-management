@JS()
library face_analyzer_mediapipe;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'face_analyzer.dart';

@JS('FilesetResolver.forVisionTasks')
external JSPromise<JSObject> _forVisionTasks(String wasmPath);

@JS('FaceLandmarker.createFromOptions')
external JSPromise<FaceLandmarker> _createFromOptions(
    JSObject filesetResolver, JSObject options);

/// MediaPipe FaceLandmarker instance (static interop view).
extension type FaceLandmarker._(JSObject _) implements JSObject {
  external FaceLandmarkerResult detect(JSObject imageSource);
}

extension type FaceLandmarkerResult._(JSObject _) implements JSObject {
  external JSArray<JSArray<Landmark>> get faceLandmarks;
}

extension type Landmark._(JSObject _) implements JSObject {
  external double get x;
  external double get y;
}

/// Web drowsiness detector: MediaPipe FaceLandmarker (Face Mesh) loaded from
/// the CDN (script tags in web/index.html). Eye closure is decided from the
/// eye-aspect-ratio (EAR) over the 6 landmarks of each eye.
class FaceAnalyzerImpl implements FaceAnalyzer {
  static const List<int> _leftEye = [33, 160, 158, 133, 153, 144];
  static const List<int> _rightEye = [362, 385, 387, 263, 373, 380];
  static const double _earClosedThreshold = 0.19;

  FaceLandmarker? _landmarker;
  bool _failed = false;

  @override
  bool get available => !_failed && _landmarker != null;

  Future<void> _ensure() async {
    if (_landmarker != null || _failed) return;
    try {
      final vision = await _forVisionTasks(
              'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/wasm')
          .toDart;
      _landmarker = await _createFromOptions(
          vision as JSObject, {
        'baseOptions': {
          'modelAssetPath':
              'https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task',
          'delegate': 'GPU',
        }.jsify(),
        'runningMode': 'IMAGE'.toJS,
        'numFaces': 1.toJS,
      }.jsify() as JSObject).toDart;
    } catch (_) {
      _failed = true;
    }
  }

  @override
  Future<FaceAnalysis?> analyze(Uint8List jpegBytes) async {
    await _ensure();
    final landmarker = _landmarker;
    if (landmarker == null) return null;
    final completer = Completer<FaceAnalysis?>();
    try {
      final blob = web.Blob(
        [jpegBytes.toJS].toJS,
        web.BlobPropertyBag(type: 'image/jpeg'),
      );
      final url = web.URL.createObjectURL(blob);
      final img = web.ImageElement();
      void done(FaceAnalysis? value) {
        if (!completer.isCompleted) completer.complete(value);
        web.URL.revokeObjectURL(url);
      }

      img.addEventListener(
        'load',
        (() {
          try {
            final result = landmarker.detect(img);
            final faces = result.faceLandmarks.toDart;
            if (faces.isEmpty) {
              done(const FaceAnalysis(
                  faceFound: false, eyesClosed: false, confidence: 0.6));
              return;
            }
            final landmarks = faces.first.toDart;
            double dist(int a, int b) {
              final dx = landmarks[b].x - landmarks[a].x;
              final dy = landmarks[b].y - landmarks[a].y;
              return dx * dx + dy * dy;
            }

            double earOf(List<int> idx) {
              final vertical = dist(idx[1], idx[5]) + dist(idx[2], idx[4]);
              final horizontal = 2 * dist(idx[0], idx[3]);
              return horizontal == 0 ? 0.5 : vertical / horizontal;
            }

            final ear = (earOf(_leftEye) + earOf(_rightEye)) / 2;
            done(FaceAnalysis(
              faceFound: true,
              eyesClosed: ear < _earClosedThreshold,
              confidence: 0.9,
              ear: ear,
            ));
          } catch (_) {
            done(null);
          }
        }).toJS,
      );
      img.addEventListener('error', (() => done(null)).toJS);
      img.src = url;
      Timer(const Duration(seconds: 3), () => done(null));
    } catch (_) {
      return null;
    }
    return completer.future;
  }
}
