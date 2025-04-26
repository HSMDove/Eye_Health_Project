import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';

class BlinkCounter {
  int blinkCount = 0; // عدد الرمشات المسجلة
  bool isBothEyesClosed = false;
  int blinkCooldown = 0; // تأخير بسيط بين الرمشات

  String rightEyeStatus = "-"; // حالة العين اليمنى مبدئيًا
  String leftEyeStatus = "-"; // حالة العين اليسرى مبدئيًا

  double previousLeftEyeOpen = 1.0;
  double previousRightEyeOpen = 1.0;

  bool allowSingleEyeBlink = true; // تحكم إذا نحسب رمشة عين واحدة أو عينتين
  double blinkThreshold = 0.15; // 🔥 أفضل قيمة للكشف عن الإغلاق

  /// تحديث عدد الرمشات بناءً على بيانات الوجه من الكاميرا
  void updateBlinkCount(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;

    // تحديث حالة العينين بدون ترجمة
    rightEyeStatus = rightEyeOpen < blinkThreshold ? "closed" : "open";
    leftEyeStatus  = leftEyeOpen  < blinkThreshold ? "closed" : "open";

    // Debugging لمراقبة القيم أثناء الفتح والإغلاق
    debugPrint('Left eye open: $leftEyeOpen, Right eye open: $rightEyeOpen');

    final bool areEyesClosed = (leftEyeOpen < blinkThreshold && rightEyeOpen < blinkThreshold);
    final bool isSingleEyeClosed = (leftEyeOpen < blinkThreshold || rightEyeOpen < blinkThreshold);
    final bool areEyesOpen = (leftEyeOpen > 0.6 && rightEyeOpen > 0.6);

    if (allowSingleEyeBlink) {
      if (isSingleEyeClosed) {
        isBothEyesClosed = true;
      } else if (isBothEyesClosed && areEyesOpen && blinkCooldown == 0) {
        blinkCount++;
        isBothEyesClosed = false;
        blinkCooldown = 2; // فترة راحة بعد كل رمشة
        debugPrint("🔵 عدد الرمشات: $blinkCount");
      }
    } else {
      if (areEyesClosed) {
        isBothEyesClosed = true;
      } else if (isBothEyesClosed && areEyesOpen && blinkCooldown == 0) {
        blinkCount++;
        isBothEyesClosed = false;
        blinkCooldown = 2;
        debugPrint("🟢 عدد الرمشات: $blinkCount");
      }
    }

    if (blinkCooldown > 0) {
      blinkCooldown--;
    }

    previousLeftEyeOpen = leftEyeOpen;
    previousRightEyeOpen = rightEyeOpen;
  }

  /// إعادة ضبط العداد عند الحاجة
  void resetCounter() {
    blinkCount = 0;
    isBothEyesClosed = false;
    rightEyeStatus = "-";
    leftEyeStatus = "-";
    previousLeftEyeOpen = 1.0;
    previousRightEyeOpen = 1.0;
    blinkCooldown = 0;
  }
}
