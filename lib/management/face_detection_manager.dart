import 'package:flutter/cupertino.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'blink_counter.dart'; //

class FaceDetectionManager {
  final FaceDetector _faceDetector;
  final BlinkCounter _blinkCounter = BlinkCounter(); // نسوي اوبجكت من الـ BlinkCounter

  FaceDetectionManager()
      : _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      //enableContours: true, // عشان رسم ملامح الوجه
      enableClassification: true, // لحالة العين
      enableLandmarks: true, // عشان نعرف مكان العين
    ),
  );

  Future<List<Face>> detectFaces(CameraImage image, CameraDescription camera) async {
    try {
      final inputImage = _convertCameraImage(image, camera);
      final faces = await _faceDetector.processImage(inputImage);

      //  تحديث عداد الرمشات لكل وجه مكتشف
      if (faces.isNotEmpty) {
        _blinkCounter.updateBlinkCount(faces.first);
      }

      debugPrint("🧐 ML Kit تعرف على ${faces.length} وجه!");
      return faces;
    } catch (e) {
      debugPrint("❌ خطأ في كشف الوجه: $e");
      return [];
    }
  }

  // نرجع عدد الرمشات
  int getBlinkCount() {
    return _blinkCounter.blinkCount;
  }

  // دالة لإعادة ضبط الرمسات
  void resetBlinkCount() {
    _blinkCounter.resetCounter();
  }

  InputImage _convertCameraImage(CameraImage image, CameraDescription camera) {
    final allBytes = image.planes.fold<List<int>>(
      <int>[],
          (List<int> previousValue, Plane plane) => previousValue..addAll(plane.bytes),
    );

    final inputImageMetadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _rotationIntToImageRotation(camera.sensorOrientation),
      format: InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: Uint8List.fromList(allBytes),
      metadata: inputImageMetadata,
    );
  }

  bool hasEyes(List<Face> faces) {
    if (faces.isEmpty) return false;
    final Face face = faces.first;
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    return leftEye != null && rightEye != null;
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}
