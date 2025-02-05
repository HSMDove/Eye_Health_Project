import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'face_detection_manager.dart';

class CameraManager {
  late CameraController _cameraController;
  final FaceDetectionManager _faceDetectionManager;
  final CameraDescription frontCamera;
  bool _isProcessing = false;
  bool faceDetect = false;

  CameraManager(this._faceDetectionManager, this.frontCamera);

  CameraController get controller => _cameraController;

  Future<void> initializeCamera() async {
    _cameraController = CameraController(frontCamera, ResolutionPreset.high);
    await _cameraController.initialize();
  }

  Future<void> startImageStream(Function(List<Face>) onFacesDetected) async {
    if (!_cameraController.value.isStreamingImages) {
      _cameraController.startImageStream((CameraImage image) async {
        if (_isProcessing) return;
        _isProcessing = true;

        try {
          List<Face> faces = await _faceDetectionManager.detectFaces(image, _cameraController.description);
          debugPrint("📸 عدد الأوجه المكتشفة: ${faces.length}");
          faces.length == 0 ? faceDetect = false : faceDetect = true;
          onFacesDetected(faces);
        } catch (e) {
          debugPrint("❌ خطأ في تحليل الصورة: $e");
        } finally {
          _isProcessing = false;
        }
      });
    }
  }

  Future<void> stopImageStream() async {
    if (_cameraController.value.isStreamingImages) {
      await _cameraController.stopImageStream();
    }
  }

  void disposeCamera() {
    _cameraController.dispose();
    _faceDetectionManager.dispose();
  }

  bool get isInitialized => _cameraController.value.isInitialized;
}
