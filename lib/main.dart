import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'pages/main_screen.dart';
import 'services/auto_attendance_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  await NotificationService.init(); // 👈 initialize notifications

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initAutoAttendance();
  }

  Future<void> _initAutoAttendance() async {
    // 👉 Request permissions
    await Permission.location.request();
    await Permission.notification.request(); // add this (Android 13+)

    // 👉 Start auto attendance service
    AutoAttendanceService.start();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}
