import 'package:eye_health/widgets/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'management/notification_manager.dart';
import 'widgets/onboarding_screen.dart';
import 'management/camera_manager.dart';
import 'management/face_detection_manager.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //  تهيئة الإشعارات
  await NotificationManager.initNotifications();

  //  تجهيز الكاميرا
  final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
  );

  FaceDetectionManager faceDetectionManager = FaceDetectionManager();
  CameraManager cameraManager = CameraManager(faceDetectionManager, frontCamera);

  // هنا نتحقق هل المستخدم قد شاف شاشة الترحيب او لا ؟
  final prefs = await SharedPreferences.getInstance();
  bool hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  hasSeenOnboarding = false; // هذي عشان شاشة الترحيب تطلع كل ما شغلنا التطبيق عشان نقدر نختبرها

  ///  تشغيل التطبيق
  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding, cameraManager: cameraManager));

  /// نشغل دالة ان التطبيق يشتغل في الخلفية بعد 3 ثواني من تشغيل التطبيق
  Future.delayed(const Duration(seconds: 3), () {
    startForegroundTask();
  });

  /// نختبر الاشعات لعد 5 ثواني من تشغيل التطبيقٍ
  Future.delayed(const Duration(seconds: 5), () {
    NotificationManager.sendNotification(" اختبار الإشعارات", "الاشعارات تم تفعيلها");
  });
}
// نهايو الدالة حق اختبار الاشعارات

// دالة عشان تشغل التطبيق في الخلفية (ماهي شغالة الحين)
void startForegroundTask() async {
  // عشان نتأكد هل قد تم تفعيل ميزة ان التطبيق يشتغل في الخلفية من قبل او لا
  bool isRunning = await FlutterForegroundTask.isRunningService; // ✅ استدعاء الدالة بشكل صحيح

  if (!isRunning) {
    //  تشغيل الخدمة الأمامية
    var result = await FlutterForegroundTask.startService(
      notificationTitle: ' Running Service',
      notificationText: 'Foreground service is active.',
    );

    print("🔹 Foreground Task Result: $result");

    if (result.toString() == "ServiceRequestResult.success") { //
      print(" Foreground service started successfully.");
    } else {
      print(" Failed to start foreground service. Reason: $result");
    }
  } else {
    print(" Foreground service is already running.");
  }
}
// نهاية دالة التشغيل في الخلفية

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  final CameraManager cameraManager;

  const MyApp({super.key, required this.hasSeenOnboarding, required this.cameraManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: hasSeenOnboarding
          ? CameraScreen(cameraManager: cameraManager)
          : OnboardingScreen(cameraManager: cameraManager),
    );
  }
}
