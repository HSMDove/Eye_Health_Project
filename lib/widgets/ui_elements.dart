import 'package:easy_localization/easy_localization.dart';
import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../management/camera_manager.dart';
import '../management/blink_counter.dart';
import '../management/blink_evaluator.dart';
import 'settings_screen.dart';

class CameraScreen extends StatefulWidget {
  final CameraManager cameraManager;

  const CameraScreen({super.key, required this.cameraManager});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isInitialized = false;
  bool _isCameraInitialized = false;
  BlinkCounter blinkCounter = BlinkCounter();
  late BlinkEvaluator blinkEvaluator;
  String _latestBlinkResult = "";
  bool darkMode = false;
  bool isBlinking = true;
  late CameraManager cm;

  int _blinkEvaluationTime = 30;
  double _notificationInterval = 15;

  final floating = Floating();

  @override
  void initState() {
    super.initState();
    cm = widget.cameraManager;
    floating.enable(OnLeavePiP(aspectRatio: Rational.vertical()));
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    await _loadSettings();
    await _initializeCamera();

    blinkEvaluator = BlinkEvaluator(
      blinkCounter: blinkCounter,
      onEvaluationComplete: (String status) {
        if (mounted && status.isNotEmpty) {
          setState(() {
            _latestBlinkResult = status;
          });
        }
      },
      intervalSeconds: _blinkEvaluationTime,
      evaluationDurationSeconds: _blinkEvaluationTime,
    );

    blinkEvaluator.startEvaluation();
    _isInitialized = true;
  }

  Future<void> _initializeCamera() async {
    try {
      debugPrint("✅ [CameraScreen] نفترض أن الصلاحية جاهزة مسبقًا");

      await cm.initializeCamera();
      setState(() {
        _isCameraInitialized = cm.isInitialized;
      });

      await cm.startImageStream((faces) {
        if (mounted && isBlinking && faces.isNotEmpty) {
          final face = faces.first;
          blinkCounter.updateBlinkCount(face);
        }
      });

      debugPrint("✅ [CameraScreen] الكاميرا بدأت بث الصور");
    } catch (e) {
      debugPrint("❌ [CameraScreen] فشل في تهيئة الكاميرا: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل في تشغيل الكاميرا: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
      _blinkEvaluationTime = prefs.getDouble('blinkCalculationTime')?.toInt() ?? 30;
      _notificationInterval = prefs.getDouble('notificationInterval') ?? 15;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PiPSwitcher(
      childWhenEnabled: _buildCameraScaffold(),
      childWhenDisabled: _buildCameraScaffold(),
    );
  }

  Widget _buildCameraScaffold() {
    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF002134) : const Color.fromARGB(255, 145, 195, 209),
      appBar: AppBar(
        backgroundColor: darkMode ? const Color(0xFF002134) : const Color(0xff79a7b4),
        centerTitle: true,
        title: Image.asset('assets/images/Icon.png', height: 50),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              bool? result = await Navigator.of(context).push(_createRoute());
              if (result != null) {
                await _loadSettings(); // ✅ إعادة تحميل الإعدادات
                setState(() {
                  darkMode = result;
                });
                blinkEvaluator.updateTimings(
                  newIntervalSeconds: _blinkEvaluationTime,
                  newEvaluationDurationSeconds: _blinkEvaluationTime,
                  newNotificationMinutes: _notificationInterval.toInt(),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: _isCameraInitialized
                  ? (cm.faceDetect == false
                  ? _buildFaceNotDetected()
                  : _buildCameraPreview())
                  : const CircularProgressIndicator(),
            ),
            const SizedBox(height: 20),
            _buildInfoSection(),
            const Spacer(),
            _buildControlButton(),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceNotDetected() {
    return Container(
      width: 200,
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(200),
        color: darkMode ? const Color(0xFF032c42) : const Color(0xff79a7b4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "no_face_detected".tr(),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "try_facing_camera".tr(),
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(200),
        color: darkMode ? const Color(0xFF002134) : const Color(0xff79a7b4),
      ),
      child: ClipOval(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0),
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: cm.controller.value.previewSize?.height ?? 200,
              height: cm.controller.value.previewSize?.width ?? 200,
              child: CameraPreview(cm.controller),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInfoBox(
              "${"start_evaluation_soon".tr()} ${blinkEvaluator.evaluationDurationSeconds - blinkEvaluator.elapsedSeconds}\n"
                  "${"blink_count".tr()} ${blinkCounter.blinkCount}\n"
                  "${"blink_average".tr()} ${blinkEvaluator.averageBlinks.toStringAsFixed(2)}\n"
                  "📊 ${"evaluation_every".tr()} ${blinkEvaluator.intervalSeconds} ${"seconds".tr()}\n"
                  "🔔 ${"notification_every".tr()} ${blinkEvaluator.notificationIntervalMinutes} ${"minutes".tr()}"),
          _buildInfoBox("${"blink_status".tr()} ${_latestBlinkResult.isNotEmpty ? _latestBlinkResult : "..."}"),
          _buildInfoBox(
            cm.faceDetect
                ? "${"right_eye".tr()} ${blinkCounter.rightEyeStatus.tr()}\n"
                "${"left_eye".tr()} ${blinkCounter.leftEyeStatus.tr()}"
                : "no_face_detected".tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: (darkMode ? const Color(0xFFffa08c) : const Color(0xff79a7b4)).withOpacity(0.35),
                blurRadius: 30,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              isBlinking ? (darkMode ? const Color(0xFFffa08c) : const Color(0xff79a7b4)) : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: isBlinking ? 10 : 2,
            ),
            onPressed: _toggleBlinking,
            child: Text(
              isBlinking ? "power_off".tr() : "startUsingApp".tr(),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBlinking() async {
    setState(() {
      isBlinking = !isBlinking;
    });
    HapticFeedback.mediumImpact();

    if (isBlinking) {
      blinkEvaluator.startEvaluation();
      await cm.startImageStream((faces) {
        if (mounted && faces.isNotEmpty) {
          final face = faces.first;
          blinkCounter.updateBlinkCount(face);
        }
      });
      _showSnackBar("blinking_resumed".tr(), Colors.green);
    } else {
      blinkEvaluator.stopEvaluation();
      await cm.stopImageStream();
      _showSnackBar("blinking_paused".tr(), Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(color == Colors.red ? Icons.pause : Icons.play_arrow, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Route<bool> _createRoute() {
    return PageRouteBuilder<bool>(
      pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  Widget _buildInfoBox(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: darkMode ? const Color(0xFF032c42) : const Color(0xff79a7b4),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
