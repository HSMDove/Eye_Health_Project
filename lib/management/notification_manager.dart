import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class NotificationManager {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Timer? _notificationTimer;
  static List<int> _blinkRecords = [];

  /// تهيئة الإشعارات + بدء المؤقت إذا كانت مفعّلة
  static Future<void> initNotifications() async {
    await _requestNotificationPermission();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);

    await _startTimerIfEnabled();
  }

  static Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print("✅ تم منح إذن الإشعارات");
    } else {
      print("❌ تم رفض إذن الإشعارات");
    }
  }

  static Future<void> _startTimerIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notificationsEnabled') ?? false;

    if (!enabled) return;

    final intervalMinutes = prefs.getDouble('notificationInterval') ?? 15;
    _startNotificationTimer(intervalMinutes);
  }

  static Future<void> updateNotificationInterval(double minutes) async {
    _notificationTimer?.cancel();
    _startNotificationTimer(minutes);
    print("📥 [NotificationManager] تم ضبط الفاصل الزمني الجديد: $minutes دقيقة");
  }

  static Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);

    print("📥 [NotificationManager] toggleNotifications = $enabled");
    if (enabled) {
      final interval = prefs.getDouble('notificationInterval') ?? 15;
      _startNotificationTimer(interval);
    } else {
      stopNotifications();
    }
  }

  static void _startNotificationTimer(double intervalMinutes) {
    print("🔁 بدء إرسال الإشعارات كل $intervalMinutes دقيقة");

    _blinkRecords.clear();

    // أول إشعار بعد أول دورة
    Future.delayed(Duration(minutes: intervalMinutes.toInt()), () {
      sendBlinkSummaryNotification();

      _notificationTimer = Timer.periodic(
        Duration(minutes: intervalMinutes.toInt()),
            (timer) {
          sendBlinkSummaryNotification();
        },
      );
    });
  }

  static Future<void> sendNotification(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notificationsEnabled') ?? true;

    if (!enabled) {
      print("🔕 تم تعطيل الإشعارات، لن يتم الإرسال");
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'blink_notifications',
      'إشعارات صحة العين',
      channelDescription: 'تنبيهات للحفاظ على صحة العين بناءً على معدل الرمشات',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: 'icon',
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(0, title, body, details);
  }

  static void sendBlinkSummaryNotification() {
    if (_blinkRecords.isEmpty) {
      print("⚠️ لا توجد بيانات رمشات لعرضها");
      return;
    }

    double avg = _blinkRecords.reduce((a, b) => a + b) / _blinkRecords.length;
    String statusKey;
    if (avg >= 6 && avg <= 20) {
      statusKey = "normal_blink_rate";
    } else if (avg < 6) {
      statusKey = "low_blink_rate_warning";
    } else {
      statusKey = "high_blink_rate_warning";
    }

    String translatedStatus = statusKey.tr();
    String msg = "${"blink_status".tr()} : $translatedStatus";

    sendNotification("🔔 ${"blink_status".tr()}", msg);
    _blinkRecords.clear();
  }

  static void addBlinkRecord(int count) {
    _blinkRecords.add(count);
  }

  static void stopNotifications() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    _blinkRecords.clear();
    print("🛑 تم إيقاف مؤقت الإشعارات");
  }
}
