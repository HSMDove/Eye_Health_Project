import 'package:flutter/cupertino.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class BlinkCounter {
  int blinkCount = 0; // عدد الرمشات المسجلة
  bool isBothEyesClosed = false; // متغير لمعرفة إذا كانت العينان مغلقتين تمامًا
  int blinkCooldown = 0; // يستخدم لمنع تسجيل رمشات متتالية خاطئة

  String rightEyeStatus = "مفتوحة"; // حالة العين اليمنى حاليًا
  String leftEyeStatus = "مفتوحة"; // حالة العين اليسرى حاليًا

  double previousLeftEyeOpen = 1.0; // تتبع حالة العين اليسرى من الإطار السابق
  double previousRightEyeOpen = 1.0; // تتبع حالة العين اليمنى من الإطار السابق

  bool allowSingleEyeBlink = true; // ✅ متغير للتحكم في احتساب رمشة العين الواحدة

  /// تحديث عدد الرمشات بناءً على بيانات الوجه اللي تجي من الكاميرا
  void updateBlinkCount(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0; // نسبة فتح العين اليسرى
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0; // نسبة فتح العين اليمنى

    // تحديث حالة كل عين بناءً على نسبة الفتح
    rightEyeStatus = leftEyeOpen < 0.15 ? "مغلقة" : "مفتوحة";
    leftEyeStatus = rightEyeOpen < 0.15 ? "مغلقة" : "مفتوحة";

    // التحقق مما إذا كانت **العينان مغلقتين بالكامل** أو **عين واحدة مغلقة**
    final bool areEyesClosed = (leftEyeOpen < 0.15 && rightEyeOpen < 0.15);
    final bool isSingleEyeClosed = (leftEyeOpen < 0.15 || rightEyeOpen < 0.15);
    final bool areEyesOpen = (leftEyeOpen > 0.6 && rightEyeOpen > 0.6);

    // مقارنة الإطار الحالي مع السابق لتحسين دقة الحساب
    final bool wasEyesOpenBefore = (previousLeftEyeOpen > 0.6 && previousRightEyeOpen > 0.6);
    final bool isClosingNow = (previousLeftEyeOpen > 0.6 && leftEyeOpen < 0.15) ||
        (previousRightEyeOpen > 0.6 && rightEyeOpen < 0.15);

    // احتساب الرمشات حسب الإعداد
    if (allowSingleEyeBlink) {
      // ✅ الوضع: احتساب الرمشات حتى لو كانت بعين واحدة
      if (isSingleEyeClosed) {
        isBothEyesClosed = true;
      } else if (isBothEyesClosed && areEyesOpen && blinkCooldown == 0) {
        blinkCount++;
        isBothEyesClosed = false;
        blinkCooldown = 2;
        debugPrint("عدد الرمشات: $blinkCount");
      }
    } else {
      // ✅ الوضع الطبيعي: احتساب الرمشات فقط إذا كانت **العينان مغلقتين**
      if (areEyesClosed) {
        isBothEyesClosed = true;
      } else if (isBothEyesClosed && areEyesOpen && blinkCooldown == 0) {
        blinkCount++;
        isBothEyesClosed = false;
        blinkCooldown = 2;
        debugPrint("عدد الرمشات: $blinkCount");
      }
    }

    // تقليل فترة التبريد بعد كل تحديث لتجنب الحساب الخاطئ
    if (blinkCooldown > 0) {
      blinkCooldown--;
    }

    // تحديث القيم السابقة للعينين للإطار القادم
    previousLeftEyeOpen = leftEyeOpen;
    previousRightEyeOpen = rightEyeOpen;
  }

  /// إعادة تعيين العداد وإرجاع القيم لوضعها الافتراضي
  void resetCounter() {
    blinkCount = 0;
    isBothEyesClosed = false;
    rightEyeStatus = "مفتوحة";
    leftEyeStatus = "مفتوحة";
    previousLeftEyeOpen = 1.0;
    previousRightEyeOpen = 1.0;
    blinkCooldown = 0;
  }
}
