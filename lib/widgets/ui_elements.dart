import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../management/camera_manager.dart';
import '../management/blink_evaluator_service.dart';
import 'settings_screen.dart';

class CameraScreen extends StatefulWidget {
  final CameraManager cameraManager;
  const CameraScreen({super.key, required this.cameraManager});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCameraInitialized = false;
  late BlinkEvaluatorService blinkEvaluatorService;
  String blinkStatus = "";
  bool darkMode = false;
  bool isBlinking = true;
  late CameraManager cm;

  @override
  void initState() {
    super.initState();
    cm = widget.cameraManager;
    blinkEvaluatorService = BlinkEvaluatorService.instance;

    _initializeCamera();
    _loadSettings();

    blinkEvaluatorService.blinkEvaluator.onEvaluationComplete = (String status) {
      if (mounted) {
        setState(() {
          blinkStatus = status;
        });
      }
    };

    blinkEvaluatorService.startEvaluation();
  }

  Future<void> _initializeCamera() async {
    await widget.cameraManager.initializeCamera();
    setState(() {
      _isCameraInitialized = widget.cameraManager.isInitialized;
    });

    await widget.cameraManager.startImageStream((faces) {
      if (mounted && isBlinking) {
        if (faces.isNotEmpty) {
          final face = faces.first;
          blinkEvaluatorService.blinkEvaluator.blinkCounter.updateBlinkCount(face);
        }
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF002134) : const Color.fromARGB(255, 145, 195, 209),
      appBar: AppBar(
        backgroundColor: darkMode ? const Color(0xFF002134) : const Color(0xff79a7b4),
        centerTitle: true,
        title: Image.asset('assets/images/Icon.png', height: 50),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _navigateToSettings,
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
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 800),
            child: Text(
              "no_face_detected".tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "try_facing_camera".tr(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
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
              width: widget.cameraManager.controller.value.previewSize?.height ?? 200,
              height: widget.cameraManager.controller.value.previewSize?.width ?? 200,
              child: CameraPreview(widget.cameraManager.controller),
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
            "${"start_evaluation_soon".tr()} ${blinkEvaluatorService.blinkEvaluator.evaluationDurationSeconds - blinkEvaluatorService.blinkEvaluator.elapsedSeconds}\n"
                "${"blink_count".tr()} ${blinkEvaluatorService.blinkEvaluator.blinkCounter.blinkCount}\n"
                "${"blink_average".tr()} ${blinkEvaluatorService.blinkEvaluator.averageBlinks.toStringAsFixed(2)}",
          ),
          _buildInfoBox("${"blink_status".tr()} $blinkStatus"),
          _buildInfoBox(
            cm.faceDetect
                ? "${"right_eye".tr()} ${blinkEvaluatorService.blinkEvaluator.blinkCounter.rightEyeStatus.tr()}\n"
                "${"left_eye".tr()} ${blinkEvaluatorService.blinkEvaluator.blinkCounter.leftEyeStatus.tr()}"
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
              backgroundColor: isBlinking
                  ? (darkMode ? const Color(0xFFffa08c) : const Color(0xff79a7b4))
                  : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: isBlinking ? 10 : 2,
            ),
            onPressed: _toggleBlinking,
            child: Text(
              isBlinking ? "power_off".tr() : "startUsingApp".tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
      blinkEvaluatorService.startEvaluation();
      await widget.cameraManager.startImageStream((faces) {
        if (mounted) {
          if (faces.isNotEmpty) {
            final face = faces.first;
            blinkEvaluatorService.blinkEvaluator.blinkCounter.updateBlinkCount(face);
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.play_arrow, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text("blinking_resumed".tr())),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      blinkEvaluatorService.stopEvaluation();
      await widget.cameraManager.stopImageStream();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.pause, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text("blinking_paused".tr())),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _navigateToSettings() async {
    bool? result = await Navigator.of(context).push(_createRoute());
    if (result != null) {
      setState(() {
        darkMode = result;
      });
    }
  }

  Route<bool> _createRoute() {
    return PageRouteBuilder<bool>(
      pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
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
