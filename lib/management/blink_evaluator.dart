import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blink_counter.dart';
import '../management/notification_manager.dart';

class BlinkEvaluator {
  final BlinkCounter _blinkCounter;
  int intervalSeconds;
  int evaluationDurationSeconds;
  Function(String) onEvaluationComplete;

  BlinkCounter get blinkCounter => _blinkCounter;

  List<int> _blinkCounts = [];
  Timer? _secondTimer;
  int _elapsedTime = 0;
  int _currentCycleTime = 0;
  int _notificationCycleCount = 0;
  bool _isEvaluating = false;
  int notificationIntervalMinutes = 15; // ← من الإعدادات

  BlinkEvaluator({
    required this.onEvaluationComplete,
    required BlinkCounter blinkCounter,
    this.intervalSeconds = 60,
    this.evaluationDurationSeconds = 60,
  }) : _blinkCounter = blinkCounter;

  Future<void> loadTimingsFromSettings() async {
    final prefs = await SharedPreferences.getInstance();
    intervalSeconds = prefs.getDouble('blinkCalculationTime')?.toInt() ?? 60;
    evaluationDurationSeconds = intervalSeconds;
    notificationIntervalMinutes = prefs.getDouble('notificationInterval')?.toInt() ?? 15;

    debugPrint("✅ [Evaluator] تحميل الإعدادات: interval=$intervalSeconds, notif=$notificationIntervalMinutes min");
  }

  void updateTimings({required int newIntervalSeconds, required int newEvaluationDurationSeconds, required int newNotificationMinutes}) {
    intervalSeconds = newIntervalSeconds;
    evaluationDurationSeconds = newEvaluationDurationSeconds;
    notificationIntervalMinutes = newNotificationMinutes;

    debugPrint("✅ [Evaluator] تحديث يدوي: interval=$intervalSeconds, duration=$evaluationDurationSeconds, notif=$notificationIntervalMinutes min");
    stopEvaluation();
    startEvaluation();
  }

  void startEvaluation() async {
    if (_isEvaluating) {
      debugPrint("⛔ [Evaluator] يعمل مسبقًا");
      return;
    }

    await loadTimingsFromSettings();
    _isEvaluating = true;
    _resetEvaluation();

    _secondTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedTime++;
      _currentCycleTime++;

      onEvaluationComplete(
          "${"calculating".tr()} (${evaluationDurationSeconds - _elapsedTime} ${"seconds_remaining".tr()})"
      );

      if (_currentCycleTime >= intervalSeconds) {
        _recordBlinkCount();
        _currentCycleTime = 0;
        _notificationCycleCount++;
      }

      if (_notificationCycleCount >= notificationIntervalMinutes) {
        _evaluateBlinks(sendNotification: true);
        _notificationCycleCount = 0;
        _blinkCounts.clear();
      }

      if (_elapsedTime >= evaluationDurationSeconds) {
        _evaluateBlinks();
        _elapsedTime = 0;
      }
    });

    debugPrint("▶️ [Evaluator] بدأ التقييم الدوري");
  }

  void _recordBlinkCount() {
    int currentBlinks = _blinkCounter.blinkCount;
    _blinkCounts.add(currentBlinks);
    NotificationManager.addBlinkRecord(currentBlinks); // ✅ نضيفها هنا
    _blinkCounter.resetCounter();
    debugPrint("📝 [Evaluator] سجل $currentBlinks رمشات بعد $_elapsedTime ثانية");
  }

  void _evaluateBlinks({bool sendNotification = false}) {
    if (_blinkCounts.isEmpty) return;
    double avgBlinks = averageBlinks;
    debugPrint("📊 [Evaluator] متوسط الرمشات: ${avgBlinks.toStringAsFixed(2)}");

    String evaluationMessage = _getBlinkEvaluation(avgBlinks);
    onEvaluationComplete(evaluationMessage);

    if (sendNotification) {
      _sendBlinkNotification(evaluationMessage);
    }
  }

  void _resetEvaluation() {
    _elapsedTime = 0;
    _currentCycleTime = 0;
    _notificationCycleCount = 0;
    _blinkCounts.clear();
    _blinkCounter.resetCounter();
    debugPrint("🔄 [Evaluator] تم إعادة الضبط الكامل");
  }

  String _getBlinkEvaluation(double avgBlinks) {
    if (avgBlinks >= 6 && avgBlinks <= 20) {
      return "normal_blink_rate".tr();
    } else if (avgBlinks < 6) {
      return "low_blink_rate_warning".tr();
    } else {
      return "high_blink_rate_warning".tr();
    }
  }

  void _sendBlinkNotification(String message) {
    NotificationManager.sendNotification(" تقييم الرمشات", message);
    debugPrint("🔔 [Evaluator] إشعار: $message");
  }

  void stopEvaluation() {
    _secondTimer?.cancel();
    _isEvaluating = false;
    debugPrint("⏹️ [Evaluator] توقف التقييم");
  }

  int get elapsedSeconds => _elapsedTime;

  double get averageBlinks {
    if (_blinkCounts.isEmpty) return 0.0;
    return _blinkCounts.reduce((a, b) => a + b) / _blinkCounts.length;
  }
}
