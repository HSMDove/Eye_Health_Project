import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../management/camera_manager.dart';
//import '../management/face_detection_manager.dart';
import '../widgets/face_contour_painter.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class CameraScreen extends StatefulWidget {
  final CameraManager cameraManager;
  CameraScreen({required this.cameraManager});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCameraInitialized = false;
  List<Face> _faces = [];
  Size? _previewSize;
  List<String> debugMessages = [];
  bool showDebugMessages = false; // ✅ متغير للتحكم في عرض رسائل التتبع

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
          if (showDebugMessages) {
            debugMessages.add("✅ اكتشفنا ${faces.length} وجه!");
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          /// ✅ **عرض الكاميرا بعد عكسها**
          Center(
            child: _isCameraInitialized
                ? Transform.scale(
              scaleX: -1,
              child: CameraPreview(widget.cameraManager.controller),
            )
                : CircularProgressIndicator(),
          ),

          /// ✅ **إضافة `CustomPaint` فوق الكاميرا**
          if (_faces.isNotEmpty && _previewSize != null)
            Positioned.fill(
              child: CustomPaint(
                painter: FaceContourPainter(
                  faces: _faces,
                  screenSize: screenSize,
                  previewSize: _previewSize!,
                ),
              ),
            ),

          /// ✅ **عرض رسائل التتبع فقط إذا كان `showDebugMessages` مفعل**
          if (showDebugMessages)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: debugMessages.map((msg) => Text(
                    msg,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  )).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
