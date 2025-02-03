import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../management/camera_manager.dart';
import '../widgets/face_contour_painter.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../management/blink_counter.dart';

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
  BlinkCounter blinkCounter = BlinkCounter();

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
            blinkCounter.updateBlinkCount(face);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeff2f6),
      body: SafeArea(
        child: SingleChildScrollView( // تجنب مشكلة BOTTOM OVERFLOWED
          child: Column(
            children: [
              /// مربع العنوان العلوي
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7b62d3),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7b62d3).withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end, // جعل النص بمحاذاة اليمين
                        children: const [
                          Text(
                            "مرحبا",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold, // جعل الخط بولد
                              shadows: [Shadow(color: Colors.white54, blurRadius: 10)],
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "اعتنِ بعينك، فالحفاظ على معدل رمش طبيعي يقلل من جفاف العين و يمنع الإجهاد.",
                            textAlign: TextAlign.right, // محاذاة النص لليمين
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold, // جعل الخط بولد
                              shadows: [Shadow(color: Colors.white54, blurRadius: 15)],
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// زر الإعدادات في الزاوية العلوية اليسرى
                    Positioned(
                      left: 10,
                      top: 10,
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {}, // لم يتم تحديد وظيفة للزر حالياً
                      ),
                    ),
                  ],
                ),
              ),

              /// عرض الكاميرا في شكل دائرة
              Center(
                child: _isCameraInitialized
                    ? Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7b62d3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7b62d3).withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(-1.0, 1.0), // عكس الكاميرا ليظهر الوجه بشكل طبيعي
                      child: CameraPreview(widget.cameraManager.controller),
                    ),
                  ),
                )
                    : const CircularProgressIndicator(), // مؤشر تحميل في حال عدم تهيئة الكاميرا
              ),

              const SizedBox(height: 20),

              /// مربعات المعلومات المختلفة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildInfoBox("الوقت: ٥ ثواني من ٣٠ ثانية\nالدورة: ١٠ من ١٥\nعدد الرمشات: ٧ رمشات في الدقيقة"),
                    _buildInfoBox("حالة الرمشات: منخفض\nمتوسط هناك: منخفض"),
                    _buildInfoBox("👁 العين اليمنى: ${blinkCounter.rightEyeStatus}\n👁 العين اليسرى: ${blinkCounter.leftEyeStatus}\nعدد الرمشات: ${blinkCounter.blinkCount}"),
                    _buildInfoBox("هل المستشعر يعمل؟ نعم\nهل تم التعرف على العينين؟ نعم" , ),

                  ],
                ),
              ),

              /// زر إيقاف التشغيل (لا يعمل حالياً)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7b62d3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shadowColor: const Color(0xFF7b62d3).withOpacity(0.5),
                      elevation: 10,
                    ),
                    onPressed: () {}, // لم يتم تعيين وظيفة للزر بعد
                    child: const Text(
                      "إيقاف التشغيل",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold, // جعل النص بولد
                        shadows: [Shadow(color: Colors.white54, blurRadius: 10)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// دالة لإنشاء مربعات المعلومات بشكل متناسق
  Widget _buildInfoBox(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF7b62d3),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7b62d3).withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
