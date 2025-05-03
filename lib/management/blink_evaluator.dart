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
  int _notificationCycleSeconds = 0;
  bool _isEvaluating = false;
  int notificationIntervalMinutes = 15;

  /// 🟡 جديد: لحفظ آخر نتيجة تقييم حقيقية
  String _lastEvaluationResult = "";

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

  void updateTimings({
    required int newIntervalSeconds,
    required int newEvaluationDurationSeconds,
    required int newNotificationMinutes
  }) {
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
      _notificationCycleSeconds++;

      // 🔄 كل interval: نسجل الرمشات
      if (_currentCycleTime >= intervalSeconds) {
        _recordBlinkCount();
        _currentCycleTime = 0;
      }

      // ✅ كل evaluationDuration: نقيم الحالة ونخزن النتيجة
      if (_elapsedTime >= evaluationDurationSeconds) {
        _evaluateBlinks();
        _elapsedTime = 0;
      }

      // 🔔 كل notificationInterval: إشعار عبر NotificationManager
      if (_notificationCycleSeconds >= notificationIntervalMinutes * 60) {
        _evaluateBlinks(sendNotification: true);
        _notificationCycleSeconds = 0;
        _blinkCounts.clear();
      }
    });

    debugPrint("▶️ [Evaluator] بدأ التقييم الدوري");
  }

  void _recordBlinkCount() {
    int currentBlinks = _blinkCounter.blinkCount;
    _blinkCounts.add(currentBlinks);
    NotificationManager.addBlinkRecord(currentBlinks);
    _blinkCounter.resetCounter();
    debugPrint("📝 [Evaluator] سجل $currentBlinks رمشات");
  }

  void _evaluateBlinks({bool sendNotification = false}) {
    if (_blinkCounts.isEmpty) return;

    double avgBlinks = averageBlinks;
    debugPrint("📊 [Evaluator] متوسط الرمشات: ${avgBlinks.toStringAsFixed(2)}");

    _lastEvaluationResult = _getBlinkEvaluation(avgBlinks); // 🟡 نحتفظ بها
    onEvaluationComplete(_lastEvaluationResult);

    if (sendNotification) {
      // الإشعارات تُدار من NotificationManager فقط
    }
  }

  void _resetEvaluation() {
    _elapsedTime = 0;
    _currentCycleTime = 0;
    _notificationCycleSeconds = 0;
    _blinkCounts.clear();
    _blinkCounter.resetCounter();
    _lastEvaluationResult = "";
    debugPrint("🔄 [Evaluator] تم إعادة ضبط كل المؤقتات");
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

  void stopEvaluation() {
    _secondTimer?.cancel();
    _isEvaluating = false;
    debugPrint("⏹️ [Evaluator] تم إيقاف التقييم");
  }

  int get elapsedSeconds => _elapsedTime;

  double get averageBlinks {
    if (_blinkCounts.isEmpty) return 0.0;
    return _blinkCounts.reduce((a, b) => a + b) / _blinkCounts.length;
  }

  /// 🟡 جديد: لعرض النتيجة الثابتة في واجهة المستخدم
  String get latestEvaluationResult => _lastEvaluationResult;

  /// 🟡 جديد: عد تنازلي دقيق للعرض في واجهة المستخدم
  int get timeUntilNextEvaluation => evaluationDurationSeconds - _elapsedTime;
}
