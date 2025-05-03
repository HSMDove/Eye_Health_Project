import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'package:eye_health/widgets/onboarding_screen.dart';
import 'package:eye_health/widgets/ui_elements.dart';
import 'package:eye_health/management/notification_manager.dart';
import 'package:eye_health/management/camera_manager.dart';
import 'package:eye_health/management/face_detection_manager.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:eye_health/management/permission_manager.dart';

late CameraDescription frontCamera;

void main() async {
  print("⏳ [main] بدء التهيئة...");
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  print("✅ [main] EasyLocalization جاهز");

  // ✅ طلب صلاحيات الإشعارات، الكاميرا، المايكروفون
  await _requestAllPermissions();

  // ✅ الكاميرات
  final cameras = await availableCameras();
  print("✅ [main] تم جلب الكاميرات: ${cameras.length}");
  frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
  );
  print("✅ [main] تم اختيار الكاميرا الأمامية");

  // ✅ Shared Preferences
  final prefs = await SharedPreferences.getInstance();
  bool hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  print("✅ [main] SharedPreferences جاهز - hasSeenOnboarding = $hasSeenOnboarding");

  // ✅ تشغيل التطبيق
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/tr',
      fallbackLocale: const Locale('en'),
      child: MyApp(
        hasSeenOnboarding: hasSeenOnboarding,
        cameraManager: CameraManager(FaceDetectionManager(), frontCamera),
      ),
    ),
  );

  print("🚀 [main] تم تشغيل runApp");

  // ✅ تشغيل الخدمة الخلفية بعد 3 ثواني
  Future.delayed(const Duration(seconds: 3), () {
    print("🕒 [main] محاولة تشغيل foreground service...");
    startForegroundTask();
  });

  // 🛑 حذفنا الإشعار التجريبي هنا لأنه غير ضروري ويسبب لخبطة
}

Future<void> _requestAllPermissions() async {
  try {
    await NotificationManager.initNotifications();
    await PermissionManager.requestCameraPermission(); // يتضمن المايك أيضًا
    print("✅ [main] تم منح جميع الصلاحيات المطلوبة");
  } catch (e) {
    print("❌ [main] فشل في طلب الصلاحيات: $e");
  }
}

void startForegroundTask() async {
  bool isRunning = await FlutterForegroundTask.isRunningService;

  if (!isRunning) {
    print("⚙️ [foreground] الخدمة غير مفعّلة، نحاول تشغيلها...");
    var result = await FlutterForegroundTask.startService(
      notificationTitle: 'Running Service',
      notificationText: 'Foreground service is active.',
    );

    if (result.toString() == "ServiceRequestResult.success") {
      print("✅ [foreground] تم تشغيل foreground service بنجاح.");
    } else {
      print("❌ [foreground] فشل تشغيل foreground service. السبب: $result");
    }
  } else {
    print("🔄 [foreground] foreground service تعمل بالفعل.");
  }
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  final CameraManager cameraManager;

  const MyApp({
    Key? key,
    required this.hasSeenOnboarding,
    required this.cameraManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("🏗️ [MyApp] بناء واجهة التطبيق");
    return MaterialApp(
      title: 'Blink App',
      debugShowCheckedModeBanner: false,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: ThemeData(fontFamily: 'Tajawal'),
      home: hasSeenOnboarding
          ? CameraScreen(cameraManager: cameraManager)
          : OnboardingScreen(cameraManager: cameraManager),
    );
  }
}
