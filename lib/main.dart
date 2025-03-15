import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'management/background_service.dart';
import 'management/notification_manager.dart';
import 'widgets/onboarding_screen.dart';
import 'widgets/ui_elements.dart';
import 'management/camera_manager.dart';
import 'management/face_detection_manager.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة الإشعارات
  await NotificationManager.initNotifications();

  // ✅ تجهيز الكاميرا
  final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
  );

  FaceDetectionManager faceDetectionManager = FaceDetectionManager();
  CameraManager cameraManager = CameraManager(faceDetectionManager, frontCamera);

  // ✅ التحقق مما إذا كان المستخدم رأى الشاشات الترحيبية
  final prefs = await SharedPreferences.getInstance();
  bool hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  // ✅ تشغيل التطبيق
  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding, cameraManager: cameraManager));

  // ✅ تشغيل الخدمة الخلفية بعد التأكد من تشغيل التطبيق
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      print("🚀 بدء تشغيل الخدمة الخلفية...");
      await initializeBackgroundService();
      print("✅ تم تشغيل الخدمة الخلفية بنجاح!");
    } catch (e) {
      print("❌ خطأ أثناء تشغيل الخدمة الخلفية: $e");
    }
  });

  // ✅ اختبار الإشعارات بعد 5 ثوانٍ
  Future.delayed(const Duration(seconds: 5), () {
    NotificationManager.sendNotification("📢 اختبار الإشعارات", "🎉 تم تفعيل الإشعارات بنجاح!");
  });
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  final CameraManager cameraManager;

  const MyApp({super.key, required this.hasSeenOnboarding, required this.cameraManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: hasSeenOnboarding
          ? CameraScreen(cameraManager: cameraManager) // ✅ إذا رأى الشاشات الترحيبية → افتح الشاشة الرئيسية
          : OnboardingScreen(cameraManager: cameraManager), // ✅ إذا لم يرها → افتح الشاشات الترحيبية
    );
  }
}
