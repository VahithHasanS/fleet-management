import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

import 'face_analyzer.dart';

/// Android/iOS drowsiness detector: ML Kit Face Detection with classification
/// enabled — leftEyeOpenProbability / rightEyeOpenProbability decide closure.
class FaceAnalyzerImpl implements FaceAnalyzer {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  @override
  bool get available => Platform.isAndroid || Platform.isIOS;

  @override
  Future<FaceAnalysis?> analyze(Uint8List jpegBytes) async {
    if (!available) return null;
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/monitor_frame_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(jpegBytes, flush: true);
      try {
        final inputImage = InputImage.fromFilePath(file.path);
        final faces = await _detector.processImage(inputImage);
        if (faces.isEmpty) {
          return const FaceAnalysis(
              faceFound: false, eyesClosed: false, confidence: 0.6);
        }
        final face = faces.first;
        final left = face.leftEyeOpenProbability;
        final right = face.rightEyeOpenProbability;
        final closed = (left != null && left < 0.35) && (right != null && right < 0.35);
        final confidence = closed ? 0.9 : 0.85;
        return FaceAnalysis(
          faceFound: true,
          eyesClosed: closed,
          confidence: confidence,
        );
      } finally {
        if (await file.exists()) await file.delete();
      }
    } catch (_) {
      return null;
    }
  }
}
