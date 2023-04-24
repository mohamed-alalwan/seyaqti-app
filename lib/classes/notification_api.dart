import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationsApi {
  static final notifications = FlutterLocalNotificationsPlugin();
  static final onNotification = BehaviorSubject<String?>();

  static Future init({bool initScheduled = false}) async {
    var androidInit =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSInit = const DarwinInitializationSettings();
    var initSettings =
        InitializationSettings(android: androidInit, iOS: iOSInit);
    await notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        String? payload = details.payload;
        onNotification.add(payload);
      },
    );
  }

  static Future showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    notifications.show(
      id,
      title,
      body,
      await _notificationsDetails(),
      payload: payload,
    );
  }

  static Future showScheduledNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
    required DateTime scheduledDate,
  }) async {
    notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      await _delayedNotiDetails(),
      payload: payload,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future _notificationsDetails() async {
    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails(
      'channel_id_10',
      'Seyaqti',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: const DarwinNotificationDetails(),
    );
    return notificationDetails;
  }

  static Future _delayedNotiDetails() async {
    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails(
      'channel_id_11',
      'Seyaqti',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      sound: RawResourceAndroidNotificationSound('alarm'),
    );
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: const DarwinNotificationDetails(),
    );
    return notificationDetails;
  }
}
