import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';

class NotificationManager {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _notificationsEnabled = false;
  static int _notificationIntervalMinutes = 30; // الافتراضي 30 دقيقة
  static Timer? _notificationTimer;

  /// 🔵 تهيئة الإشعارات
  static Future<void> initNotifications() async {
    if (_initialized) return;

    await _requestNotificationPermission();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);
    _initialized = true;
  }

  /// 🟢 طلب إذن الإشعارات
  static Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print("✅ Notification permission granted");
    } else {
      print("⚠️ Notification permission denied");
    }
  }

  /// ✅ تفعيل أو تعطيل الإشعارات مع جدولة
  static void toggleNotifications(bool enabled) {
    _notificationsEnabled = enabled;
    if (enabled) {
      _startNotificationTimer();
    } else {
      _stopNotificationTimer();
      _notificationsPlugin.cancelAll();
    }
  }

  /// 🔄 تحديث الفاصل الزمني وإعادة جدولة المؤقت
  static void updateNotificationInterval(double minutes) {
    _notificationIntervalMinutes = minutes.toInt();
    print("⏱️ Notification interval updated to $_notificationIntervalMinutes minutes");
    if (_notificationsEnabled) {
      _startNotificationTimer();
    }
  }

  /// 🕰️ بدء جدولة الإشعارات حسب الفاصل الزمني
  static void _startNotificationTimer() {
    _notificationTimer?.cancel();
    if (!_notificationsEnabled) return;

    print("🔔 Starting notification timer every $_notificationIntervalMinutes minutes");

    _notificationTimer = Timer.periodic(
      Duration(minutes: _notificationIntervalMinutes),
          (timer) {
        sendNotification(
          "eye_health_reminder".tr(),
          "remember_to_blink".tr(),
        );
      },
    );
  }

  /// 🛑 إيقاف المؤقت
  static void _stopNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    print("🛑 Notification timer stopped");
  }

  /// 🛎️ إرسال إشعار فوري
  static Future<void> sendNotification(String title, String body) async {
    if (!_notificationsEnabled) {
      print("⚠️ Notifications disabled. Skipping notification.");
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'blink_notifications',
      'Eye Health Notifications',
      channelDescription: 'Notifications to help maintain eye health based on blinking rate',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      title.tr(),
      body.tr(),
      notificationDetails,
    );

    print("🔔 Notification sent: $title - $body");
  }
}
