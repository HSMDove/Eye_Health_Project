import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceContourPainter extends CustomPainter {
  final List<Face> faces;
  final Size screenSize;
  final Size previewSize;

  FaceContourPainter({
    required this.faces,
    required this.screenSize,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = screenSize.width / previewSize.height; // عكس العرض والطول بسبب الكاميرا
    final double scaleY = screenSize.height / previewSize.width; // التصحيح حسب حجم الشاشة

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.green;

    if (faces.isEmpty) {
      debugPrint("❌ لا توجد وجوه مكتشفة!");
      return;
    }
  }


  @override
  bool shouldRepaint(FaceContourPainter oldDelegate) {
    return true;
  }
}
