import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    await _startTimerIfEnabled(); // ✅ بدء المؤقت مباشرة إذا مفعّل
  }

  /// طلب إذن الإشعارات
  static Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print("✅ تم منح إذن الإشعارات");
    } else {
      print("❌ تم رفض إذن الإشعارات");
    }
  }

  /// تشغيل المؤقت الدوري إذا كانت الإشعارات مفعّلة
  static Future<void> _startTimerIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notificationsEnabled') ?? false;

    if (!enabled) return;

    final intervalMinutes = prefs.getDouble('notificationInterval') ?? 15;
    _startNotificationTimer(intervalMinutes);
  }

  /// دالة عامة لإعادة جدولة الإشعارات من الإعدادات
  static Future<void> updateNotificationInterval(double minutes) async {
    _notificationTimer?.cancel();
    _startNotificationTimer(minutes);
    print("📥 [NotificationManager] تم ضبط الفاصل الزمني الجديد: $minutes دقيقة");
  }

  /// ✅ تفعيل أو إيقاف الإشعارات من الإعدادات مباشرة
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

  /// بدء مؤقت الإشعارات
  static void _startNotificationTimer(double intervalMinutes) {
    print("🔁 بدء إرسال الإشعارات كل $intervalMinutes دقيقة");

    _blinkRecords.clear();
    _notificationTimer = Timer.periodic(
      Duration(minutes: intervalMinutes.toInt()),
          (timer) {
        _sendBlinkSummaryNotification();
      },
    );
  }

  /// إرسال إشعار فوري
  static Future<void> sendNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'blink_notifications',
      'إشعارات صحة العين',
      channelDescription: 'تنبيهات للحفاظ على صحة العين بناءً على معدل الرمشات',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: 'icon'
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(0, title, body, details);
  }

  /// إرسال إشعار متوسط الرمشات
  static void _sendBlinkSummaryNotification() {
    if (_blinkRecords.isEmpty) return;

    double avg = _blinkRecords.reduce((a, b) => a + b) / _blinkRecords.length;
    String msg;
    if (avg >= 6 && avg <= 20) {
      msg = "معدل الرمش طبيعي ✅ (${avg.toStringAsFixed(2)})";
    } else if (avg < 6) {
      msg = "⚠️ معدل الرمش منخفض (${avg.toStringAsFixed(2)})";
    } else {
      msg = "⚠️ معدل الرمش مرتفع (${avg.toStringAsFixed(2)})";
    }

    sendNotification("تقييم الرمش", msg);
    _blinkRecords.clear();
  }

  /// إضافة عدد رمشات جديد إلى القائمة
  static void addBlinkRecord(int count) {
    _blinkRecords.add(count);
  }

  /// إيقاف الإشعارات تمامًا (مثلاً إذا المستخدم ألغى التفعيل)
  static void stopNotifications() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    _blinkRecords.clear();
    print("🛑 تم إيقاف مؤقت الإشعارات");
  }
}
