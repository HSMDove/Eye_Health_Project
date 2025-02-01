import 'package:flutter/material.dart';
import 'management/permission_manager.dart';
import 'management/face_detection_manager.dart';
import 'management/camera_manager.dart';
import 'widgets/ui_elements.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PermissionManager.requestCameraPermission();

  // 🔹 الحصول على قائمة الكاميرات المتاحة
  final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front);

  // 🔹 إنشاء كائنات FaceDetectionManager و CameraManager وتمرير الكاميرا الأمامية
  FaceDetectionManager faceDetectionManager = FaceDetectionManager();
  CameraManager cameraManager = CameraManager(faceDetectionManager, frontCamera);

  runApp(MyApp(cameraManager: cameraManager));
}

class MyApp extends StatelessWidget {
  final CameraManager cameraManager;
  MyApp({required this.cameraManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraScreen(cameraManager: cameraManager), // ✅ تمرير CameraManager إلى الـ UI
    );
  }
}
