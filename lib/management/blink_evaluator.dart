import 'dart:async';
import 'package:easy_localization/easy_localization.dart';

import 'blink_counter.dart';
import 'package:flutter/material.dart';
import '../management/notification_manager.dart'; //  كود الاشعارات

class BlinkEvaluator {
  final BlinkCounter _blinkCounter;
  final int intervalSeconds; // الزمن لكل دورة (مثلاً 60 ثانية)
  final int evaluationDurationSeconds; // الزمن الإجمالي للتقييم (مثلاً 2 دقيقة)
  final Function(String) onEvaluationComplete; // تمرير النتيجة

  List<int> _blinkCounts = []; // تخزين عدد الرمشات لكل 60 ثانية
  Timer? _timer;
  Timer? _secondTimer;
  int _elapsedTime = 0;
  int _currentCycleTime = 0; // لحساب الثواني تدريجيًا داخل 60 ثانية

  BlinkEvaluator({
    required this.onEvaluationComplete,
    required BlinkCounter blinkCounter,
    this.intervalSeconds = 60,
    this.evaluationDurationSeconds = 60,
  }) : _blinkCounter = blinkCounter;

  void startEvaluation() {
    _timer?.cancel();
    _secondTimer?.cancel();
    _resetEvaluation(); // إعادة ضبط القيم

    // 🔹 تحديث الثواني كل ثانية تدريجيًا
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedTime++;
      _currentCycleTime++;

      if (_currentCycleTime >= intervalSeconds) {
        _recordBlinkCount();
        _currentCycleTime = 0; // إعادة ضبط عداد الدورة
      }

      if (_elapsedTime >= evaluationDurationSeconds) {
        timer.cancel();
        _evaluateBlinks();
        Future.delayed(const Duration(seconds: 3), startEvaluation); // 🔄 إعادة التشغيل بعد 3 ثواني
      }
    });
  }

  void _recordBlinkCount() {
    int currentBlinks = _blinkCounter.blinkCount;
    _blinkCounts.add(currentBlinks);
    _blinkCounter.resetCounter();
    debugPrint(" بعد $_elapsedTime ثانية، عدد الرمشات في الدورة: $currentBlinks");
  }

  void _evaluateBlinks() {
    if (_blinkCounts.isEmpty) return;

    double avgBlinks = averageBlinks;
    debugPrint(" متوسط الرمشات خلال $_elapsedTime ثانية: ${avgBlinks.toStringAsFixed(2)}");

    String evaluationMessage = _getBlinkEvaluation(avgBlinks);
    onEvaluationComplete(evaluationMessage);

    // ✅ إرسال إشعار بناءً على التقييم
    _sendBlinkNotification(evaluationMessage);
  }

  void _resetEvaluation() {
    _elapsedTime = 0;
    _currentCycleTime = 0;
    _blinkCounts.clear();
    _blinkCounter.resetCounter();
    debugPrint("🔄 إعادة ضبط التقييم والبدء من جديد!");
  }

  String _getBlinkEvaluation(double avgBlinks) {
    if (avgBlinks >= 6 && avgBlinks <= 20) {
      return   "normal_blink_rate".tr();
    } else if (avgBlinks < 6) {
      return "low_blink_rate_warning".tr();
    } else {
      return   "high_blink_rate_warning".tr();
    }
  }

  void _sendBlinkNotification(String message) {
    NotificationManager.sendNotification(" تقييم الرمشات", message);
    debugPrint(" تم إرسال إشعار: $message");
  }

  void stopEvaluation() {
    _timer?.cancel();
    _secondTimer?.cancel();
  }

  int get elapsedSeconds => _elapsedTime;

  double get averageBlinks {
    if (_blinkCounts.isEmpty) return 0.0;
    return _blinkCounts.reduce((a, b) => a + b) / _blinkCounts.length;
  }
}
