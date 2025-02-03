import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../management/camera_manager.dart';
import '../widgets/face_contour_painter.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../management/blink_counter.dart'; // ✅ استيراد كود حساب الرمشات

class CameraScreen extends StatefulWidget {
  final CameraManager cameraManager;
  const CameraScreen({super.key, required this.cameraManager});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCameraInitialized = false;
  List<Face> _faces = [];
  Size? _previewSize;
  BlinkCounter blinkCounter = BlinkCounter(); // ✅ إضافة كود حساب الرمشات
  String rightEyeStatus = "مفتوحة";
  String leftEyeStatus = "مفتوحة";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await widget.cameraManager.initializeCamera();
    setState(() {
      _isCameraInitialized = widget.cameraManager.isInitialized;
      _previewSize = widget.cameraManager.controller.value.previewSize;
    });

    widget.cameraManager.startImageStream((faces) {
      if (mounted) {
        setState(() {
          _faces = faces;

          if (faces.isNotEmpty) {
            final face = faces.first;
            final rightEyeOpenProb = face.rightEyeOpenProbability ?? 1.0;
            final leftEyeOpenProb = face.leftEyeOpenProbability ?? 1.0;

            rightEyeStatus = rightEyeOpenProb < 0.1 ? "مغلقة" : "مفتوحة";
            leftEyeStatus = leftEyeOpenProb < 0.1 ? "مغلقة" : "مفتوحة";

            // ✅ استخدام `BlinkCounter` لحساب الرمشات
            blinkCounter.updateBlinkCount(face);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 57, 57, 57),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            /// ✅ **عرض الكاميرا بعد عكسها**
            Center(
              child: _isCameraInitialized
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 10, color: const Color.fromARGB(255, 0, 0, 0)), // Border color
                        borderRadius: BorderRadius.circular(50), // Rounded corners
                      ),
                      width: 200,
                      height: 300,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40), // Apply the same radius
                        child: Transform.scale(
                          scaleX: -1, // Flip the camera horizontally
                          child: CameraPreview(widget.cameraManager.controller), // Display camera preview
                        ),
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),

            /// ✅ **مربع بيانات الرمشات أسفل الشاشة**
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("👁 حالة العين اليمنى: $rightEyeStatus",
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                    Text("👁 حالة العين اليسرى: $leftEyeStatus",
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                    Text(" عدد الرمشات: ${blinkCounter.blinkCount}",
                        style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)), // ✅ استخدام BlinkCounter هنا
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
