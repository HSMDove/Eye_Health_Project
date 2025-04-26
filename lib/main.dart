import 'package:eye_health/widgets/MyAppLauncher.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:camera/camera.dart';
import 'package:eye_health/management/camera_manager.dart';
import 'package:eye_health/management/face_detection_manager.dart';
import 'package:eye_health/widgets/onboarding_screen.dart';
import 'package:eye_health/widgets/ui_elements.dart'; // فيه CameraScreen
import 'package:shared_preferences/shared_preferences.dart';

late CameraDescription frontCamera;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final cameras = await availableCameras();
  frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
  );

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/tr',
      fallbackLocale: const Locale('en'),
      child: MyAppLauncher (
        hasSeenOnboarding: hasSeenOnboarding,
        cameraManager: CameraManager(FaceDetectionManager(), frontCamera),
      ),
    ),
  );
}
