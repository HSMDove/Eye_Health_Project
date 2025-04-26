// ----- استيراد الحزم والملفات اللازمة ----- //
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../management/camera_manager.dart';
import '../management/blink_counter.dart';
import '../management/blink_evaluator.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraScreen extends StatefulWidget {
  final CameraManager cameraManager;

  const CameraScreen({super.key, required this.cameraManager});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

// ----- حالة واجهة الكاميرا (State) ----- //
class _CameraScreenState extends State<CameraScreen> {
  bool _isCameraInitialized = false;
  BlinkCounter blinkCounter = BlinkCounter();
  late BlinkEvaluator blinkEvaluator;
  String blinkStatus =   "";
  bool darkMode = false;
  late CameraManager cm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (blinkStatus.isEmpty) {
      setState( () {
        blinkStatus = "calculating".tr();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    cm = widget.cameraManager;
    _initializeCamera();
    _loadSettings();
    blinkEvaluator = BlinkEvaluator(
      blinkCounter: blinkCounter,
      onEvaluationComplete: (String status) {
        setState(() {
          blinkStatus = status;
        });
      },
    );
    blinkEvaluator.startEvaluation();
  }

  Future<void> _initializeCamera() async {
    await widget.cameraManager.initializeCamera();
    setState(() {
      _isCameraInitialized = widget.cameraManager.isInitialized;
    });

    widget.cameraManager.startImageStream((faces) {
      if (mounted) {
        setState(() {
          if (faces.isNotEmpty) {
            final face = faces.first;
            blinkCounter.updateBlinkCount(face);
          }
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  // تفعيل الوضع الليلي
  Future<void> _navigateToSettings() async {
    bool? result = await Navigator.of(context).push(_createRoute());
    if (result != null) {
      setState(() {
        darkMode = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF002134) : const Color.fromARGB(255, 145, 195, 209),
      appBar: AppBar(
        backgroundColor: darkMode ? const Color(0xFF002134) : const Color(0xff79a7b4),
        centerTitle: true,
        title: Image.asset('assets/images/Icon.png', height: 50),

        //  زر الإعدادات
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

            // ----- عرض الكاميرا أو النص البديل ----- //
            Center(
              child: _isCameraInitialized
                  ? (cm.faceDetect == false
                  ? Container(
                width: 200,
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(200),
                  color: darkMode ? const Color(0xFF032c42) : const Color(0xff79a7b4),
                ),
                child:  Text(
                  "no_face_detected".tr(),
                  style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                ),
              )
                  : Container(
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
                    child: SizedBox(
                      width: 200,
                      height: 200,
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
                ),
              ))
                  : const CircularProgressIndicator(),
            ),

            const SizedBox(height: 20),

            // ----- المعلومات والبيانات ----- //
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildInfoBox(
                      "${"start_evaluation_soon".tr()
                          + "${blinkEvaluator.evaluationDurationSeconds - blinkEvaluator.elapsedSeconds}"
                      }\n"
                          "${"blink_count".tr() +"${blinkCounter.blinkCount}"}\n"
                          "${"blink_average".tr() +"${blinkEvaluator.averageBlinks.toStringAsFixed(2)}"}"
                  ),
                  _buildInfoBox("${"blink_status".tr() + "${blinkStatus}"}"),
                  _buildInfoBox("${"right_eye".tr()+ " ${blinkCounter.rightEyeStatus}\n"+
                                    "left_eye".tr()+ " ${blinkCounter.leftEyeStatus}" }"),

                ],
              ),
            ),
            Spacer(flex: 1,),
            // زر ايقاف التشغيل
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7, // تقليل عرض الزر
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: (darkMode ? const Color(0xFFffa08c) : const Color(0xff79a7b4))
                            .withOpacity(0.35), // إضافة وهج بنفس لون الزر
                        blurRadius: 30,
                        spreadRadius: 1,
                        //offset: const Offset(0, 5), // اتجاه الظل للأسفل
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkMode ? const Color(0xFFffa08c) : const Color(0xff79a7b4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 10, //
                    ),
                    onPressed: () {
                      debugPrint("تم الضغط على زر إيقاف التشغيل");
                    },
                    child:  Text(
                      "power_off".tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Spacer(flex: 1,),
          ],
        ),
      ),
    );
  }

  //  تحسين التعديل على الإعدادات وإصلاح الخطأ
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

  // ----- ودجت بناء المربع الي نكتب فيه المعلومات ----- //
  Widget _buildInfoBox(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: darkMode ? const Color(0xFF032c42) : const Color(0xff79a7b4),
          borderRadius: BorderRadius.circular(40),
          //border: Border.all(color: const Color(0xFF00ADB5), width: 2),
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