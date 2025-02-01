import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:ui';

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

    for (Face face in faces) {
      final contours = face.contours;
      debugPrint("✅ تم اكتشاف ${faces.length} وجه/وجوه");

      _drawContour(contours[FaceContourType.face], canvas, paint..color = Colors.green, scaleX, scaleY);
      _drawContour(contours[FaceContourType.leftEye], canvas, paint..color = Colors.blue, scaleX, scaleY);
      _drawContour(contours[FaceContourType.rightEye], canvas, paint..color = Colors.blue, scaleX, scaleY);
      _drawContour(contours[FaceContourType.noseBottom], canvas, paint..color = Colors.purple, scaleX, scaleY);
      _drawContour(contours[FaceContourType.upperLipTop], canvas, paint..color = Colors.red, scaleX, scaleY);
      _drawContour(contours[FaceContourType.lowerLipBottom], canvas, paint..color = Colors.red, scaleX, scaleY);
    }
  }

  void _drawContour(FaceContour? contour, Canvas canvas, Paint paint, double scaleX, double scaleY) {
    if (contour == null || contour.points.isEmpty) {
      debugPrint("⚠ لا توجد نقاط متاحة لهذا المعلم: $contour");
      return;
    }

    for (int i = 0; i < contour.points.length - 1; i++) {
      final p1 = contour.points[i];
      final p2 = contour.points[i + 1];

      // ✅ **عكس X لجعل الرسم متطابقًا مع الكاميرا المعكوسة**
      final adjustedP1 = Offset((screenSize.width - (p1.x * scaleX)), p1.y * scaleY);
      final adjustedP2 = Offset((screenSize.width - (p2.x * scaleX)), p2.y * scaleY);

      debugPrint("🎯 نقطة مرسومة: (${adjustedP1.dx}, ${adjustedP1.dy}) -> (${adjustedP2.dx}, ${adjustedP2.dy})");

      canvas.drawLine(adjustedP1, adjustedP2, paint);
    }
  }


  @override
  bool shouldRepaint(FaceContourPainter oldDelegate) {
    return true;
  }
}
