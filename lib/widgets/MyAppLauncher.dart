import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eye_health/widgets/ui_elements.dart'; // CameraScreen
import 'package:eye_health/widgets/onboarding_screen.dart'; // OnboardingScreen
import '../management/camera_manager.dart';

class MyAppLauncher extends StatelessWidget {
  final bool hasSeenOnboarding;
  final CameraManager cameraManager;

  const MyAppLauncher({
    super.key,
    required this.hasSeenOnboarding ,
    required this.cameraManager,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blink App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Tajawal',
        brightness: Brightness.dark,
      ),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: hasSeenOnboarding
          ? CameraScreen(cameraManager: cameraManager)
          : OnboardingScreen(cameraManager: cameraManager),

    );
  }
}
