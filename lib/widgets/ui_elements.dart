import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../management/camera_manager.dart';
import '../management/blink_counter.dart';
import '../management/camera_manager.dart';

class CameraScreen extends StatefulWidget {
  final CameraManager cameraManager;
  const CameraScreen({super.key, required this.cameraManager});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCameraInitialized = false;
  BlinkCounter blinkCounter = BlinkCounter();
  
  //قائمة الأعدادات
  bool notifications = false;
  bool dark = false;

  late CameraManager cm;
  
  @override
  void initState() {
    super.initState();

    cm = widget.cameraManager;

    _initializeCamera();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark? Color(0xff002941):const Color.fromARGB(255, 145, 195, 209),
      appBar: AppBar(
        backgroundColor: dark? Color(0xFF29637e):Color(0xff79a7b4),
        centerTitle: true,
        title: Image.asset('assets/images/Icon.png', height:50), // ضع صورة هنا
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      drawer: Drawer(
        backgroundColor: dark? Color(0xff002941):const Color.fromARGB(255, 145, 195, 209),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: dark? Color(0xFF29637e):Color(0xff79a7b4)),
              child: const Center(
                child: Text(
                  "الإعدادات",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SwitchListTile(
              activeColor: Color.fromARGB(255, 94, 210, 242),
              title: const Text("تفعيل الإشعارات",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
              ),
              value: notifications,
              onChanged: (value) {
                setState(() {
                  notifications = value;
                });
              },
            ),
            SwitchListTile(
              activeColor: Color.fromARGB(255, 94, 210, 242),
              title: const Text("الوضع الليلي",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
              ),
              value: dark,
              onChanged: (value) {
                setState(() {
                  dark = value;
                });
              },
            ),
          ]),
        ),
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
                        color: dark? Color(0xFF29637e) : Color(0xff79a7b4),
                        borderRadius: BorderRadius.circular(30),
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
                  ],
                ),
              ),

              /// عرض الكاميرا في شكل دائرة
              Center(
                child: _isCameraInitialized
                  ?(cm.faceDetect == false?
                  //عند عدم وجود وجه امام الكاميرا
                  Container(                      
                    width: 200,
                    height: 200,
                    alignment: Alignment.center,
                    child: Text("لا يوجد وجه \n امام الكاميرا",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold
                    ),
                    
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(200),
                      color: dark? Color(0xFF29637e) : Color(0xff79a7b4),
                    ),
                  ) 
                  //عند وجود وجه امام الكاميرا
                  : Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(200),
                        color: dark? Color(0xFF29637e) : Color(0xff79a7b4)
                      ),
                      

                      child: ClipOval(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..scale(-1.0, 1.0), // عكس الكاميرا
                          child: SizedBox(
                            width: 200,
                            height: 200,
                            child: FittedBox(
                              fit: BoxFit.cover, // يحافظ على الجودة
                              child: SizedBox(
                                width: widget.cameraManager.controller.value.previewSize?.height ?? 200,
                                height: widget.cameraManager.controller.value.previewSize?.width ?? 200,
                                child: CameraPreview(widget.cameraManager.controller),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  )
                  : const CircularProgressIndicator(),
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
                      backgroundColor: dark? Color(0xFF29637e) : Color(0xff79a7b4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 10,
                    ),
                    onPressed: () {}, // لم يتم تعيين وظيفة للزر بعد
                    child: const Text(
                      "إيقاف التشغيل",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold, // جعل النص بولد
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
          color: dark? Color(0xFF29637e) : Color(0xff79a7b4),
          borderRadius: BorderRadius.circular(40),

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
