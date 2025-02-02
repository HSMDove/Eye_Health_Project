import 'package:flutter/cupertino.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class BlinkCounter {
  int blinkCount = 0;
  bool isBothEyesClosed = false; // ✅ لتتبع ما إذا كانت العينان مغلقتين مسبقًا


  /// **🔹 تحديث عدد الرمشات بناءً على بيانات العينين**
  void updateBlinkCount(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;

    // تحديد ما إذا كانت العينان مفتوحتين أو مغلقتين
    final bool areEyesClosed = (leftEyeOpen < 0.2 && rightEyeOpen < 0.2);
    final bool areEyesOpen = (leftEyeOpen > 0.5 && rightEyeOpen > 0.5); // ✅ عتبة 0.5 كما في الكود الجيد

    // ✅ منطق الكود الجيد:
    if (areEyesClosed) {
      isBothEyesClosed = true;
    } else if (isBothEyesClosed && areEyesOpen) {
      blinkCount++;
      isBothEyesClosed = false;
      debugPrint(" عدد الرمشات هي ---------------------------------------------------------- ${blinkCount}");
    }
  }

  /// **🔹 إعادة تعيين العداد**
  void resetCounter() {
    blinkCount = 0;
    isBothEyesClosed = false;
  }
}