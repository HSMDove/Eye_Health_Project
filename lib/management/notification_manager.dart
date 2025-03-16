import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart'; //  استيراد مكتبة الأذونات

class NotificationManager {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  //  تهيئة الإشعارات وطلب الإذن
  static Future<void> initNotifications() async {
    //  طلب إذن الإشعارات عند تشغيل التطبيق لأول مرة
    await _requestNotificationPermission();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);
  }

  //  دالة لطلب إذن الإشعارات من المستخدم
  static Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print(" تم منح إذن الإشعارات!");
    } else {
      print(" رفض المستخدم الإذن بالإشعارات.");
    }
  }

  //  دالة لإرسال الإشعار
  static Future<void> sendNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'blink_notifications',
      'إشعارات صحة العين',
      channelDescription: 'تنبيهات للحفاظ على صحة العين بناءً على معدل الرمشات',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(0, title, body, details);
  }
}
