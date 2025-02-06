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

  // قائمة الإعدادات
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
      backgroundColor: dark ? const Color(0xFF222831) : const Color.fromARGB(255, 145, 195, 209), // الخلفية في الوضح الليلي
      appBar: AppBar(
        backgroundColor: dark ? const Color(0xFF393E46) : const Color(0xff79a7b4), //  لون الـ AppBar
        centerTitle: true,
        title: Image.asset('assets/images/Icon.png', height: 50),
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
        backgroundColor: dark ? const Color(0xFF222831) : const Color.fromARGB(255, 145, 195, 209),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: dark ? const Color(0xFF393E46) : const Color(0xff79a7b4)),
              child: const Center(
                child: Text(
                  "الإعدادات",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SwitchListTile(
              activeColor: const Color(0xFF00ADB5),
              title: const Text("تفعيل الإشعارات",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              value: notifications,
              onChanged: (value) {
                setState(() {
                  notifications = value;
                });
              },
            ),
            SwitchListTile(
              activeColor: const Color(0xFF00ADB5),
              title: const Text("الوضع الليلي",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              value: dark,
              onChanged: (value) {
                setState(() {
                  dark = value;
                });
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(

            children: [
              const SizedBox(height: 20),
              Center(

                child: _isCameraInitialized
                    ? (cm.faceDetect == false
                    ? Container(
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
                    color: dark ? const Color(0xFF393E46) : const Color(0xff79a7b4),
                  ),
                  child: const Text(
                    "لا يوجد وجه \n امام الكاميرا",
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                )
                    : Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
                    color: dark ? const Color(0xFF393E46) : const Color(0xff79a7b4),
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildInfoBox("الوقت: ٥ ثواني من ٣٠ ثانية\nالدورة: ١٠ من ١٥\nعدد الرمشات: ٧ رمشات في الدقيقة"),
                    _buildInfoBox("حالة الرمشات: منخفض\nمتوسط الرمشات: منخفض"),
                    _buildInfoBox(
                        "👁 العين اليمنى: ${blinkCounter.rightEyeStatus}\n👁 العين اليسرى: ${blinkCounter.leftEyeStatus}\nعدد الرمشات: ${blinkCounter.blinkCount}"),
                    _buildInfoBox("هل المستشعر يعمل؟ نعم\nهل تم التعرف على العينين؟ نعم"),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dark ? const Color(0xFF393E46) : const Color(0xff79a7b4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: Color(0xFF00ADB5), width: 3), // هذي الحواف حق زر ايقاف التشغيل
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 10,
                    ),
                    onPressed: () {},
                    child: const Text(
                      "إيقاف التشغيل",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

  Widget _buildInfoBox(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF393E46) : const Color(0xff79a7b4),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFF00ADB5), width: 2), // الحواف
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
