import 'dart:typed_data';

/// Result of analyzing one camera frame for drowsiness signals.
class FaceAnalysis {
  final bool faceFound;
  final bool eyesClosed;
  /// Detection confidence 0..1.
  final double confidence;
  /// Eye-aspect-ratio when available (MediaPipe), else -1.
  final double ear;
  const FaceAnalysis({
    required this.faceFound,
    required this.eyesClosed,
    required this.confidence,
    this.ear = -1,
  });
}

/// Platform face analyzer:
/// - Web: MediaPipe FaceLandmarker (Face Mesh, 478 landmarks) → EAR.
/// - Android/iOS: ML Kit Face Detection → eye-open probabilities.
///
/// Returns null when the platform detector is unavailable (the camera stream
/// itself still works — only breach detection is disabled).
abstract class FaceAnalyzer {
  Future<FaceAnalysis?> analyze(Uint8List jpegBytes);
  bool get available;
}
