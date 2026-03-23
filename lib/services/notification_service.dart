import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
  }

  static Future<void> showAttendanceMarked() async {
    const androidDetails = AndroidNotificationDetails(
      'attendance_channel',
      'Attendance Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      "Attendance Marked ✅",
      "You are marked present for today",
      details,
    );
  }
}
