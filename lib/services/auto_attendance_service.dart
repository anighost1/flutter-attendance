import 'dart:async';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import 'wifi_service.dart';
import 'notification_service.dart';

class AutoAttendanceService {
  static Timer? _timer;
  static final DBHelper _dbHelper = DBHelper();

  static const Duration interval = Duration(seconds: 15);

  static void start() {
    _timer?.cancel();

    _timer = Timer.periodic(interval, (_) async {
      await _checkAndMark();
    });
  }

  static void stop() {
    _timer?.cancel();
  }

  static Future<void> _checkAndMark() async {
    try {
      bool isOffice = await WifiService.isConnectedToOffice();

      if (!isOffice) return;

      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      //Check if already marked
      final data = await _dbHelper.getAttendance();

      bool alreadyMarked = data.any((row) {
        DateTime date = DateTime.parse(row['attendance_date']);
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      });

      if (alreadyMarked) return;

      //Mark attendance automatically
      await _dbHelper.markAttendance(today, "present");
      await NotificationService.showAttendanceMarked();

      print(
        "✅ Auto attendance marked for ${DateFormat('yyyy-MM-dd').format(today)}",
      );
    } catch (e) {
      print("❌ Auto attendance error: $e");
    }
  }
}
