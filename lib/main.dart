import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'pages/main_screen.dart';
import 'services/auto_attendance_service.dart';

void main() {
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
    // 👉 Request permission (required for WiFi BSSID)
    await Permission.location.request();

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
