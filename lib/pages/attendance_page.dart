import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/db_helper.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final DBHelper _dbHelper = DBHelper();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, String> _attendanceMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    final data = await _dbHelper.getAttendance();
    final Map<DateTime, String> freshMap = {};
    for (var row in data) {
      DateTime date = DateTime.parse(row['attendance_date']);
      freshMap[DateTime(date.year, date.month, date.day)] = row['status'];
    }
    setState(() {
      _attendanceMap = freshMap;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(
    DateTime day,
    String status, {
    String? leaveType,
  }) async {
    final result = await _dbHelper.markAttendance(
      day,
      status,
      leaveType: leaveType,
    );
    if (result == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No $leaveType balance left!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await _fetchAttendance();
  }

  void _showLeaveTypePicker(DateTime day) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Select Leave Type",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text("Sick Leave (SL)"),
            onTap: () {
              _updateStatus(day, "leave", leaveType: "SL");
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("Casual Leave (CL)"),
            onTap: () {
              _updateStatus(day, "leave", leaveType: "CL");
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("Privileged Leave (PL)"),
            onTap: () {
              _updateStatus(day, "leave", leaveType: "PL");
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showActionSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                _updateStatus(day, "present");
                Navigator.pop(context);
              },
              child: const Text("Present"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateStatus(day, "absent");
                Navigator.pop(context);
              },
              child: const Text("Absent"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showLeaveTypePicker(day);
              },
              child: const Text("Leave"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final dateKey = DateTime(day.year, day.month, day.day);
                  if (_attendanceMap.containsKey(dateKey)) {
                    final status = _attendanceMap[dateKey];
                    Color color = status == "present"
                        ? Colors.green
                        : (status == "absent" ? Colors.red : Colors.blue);
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${day.day}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
              onDaySelected: (sel, foc) {
                _showActionSheet(sel);
              },
            ),
    );
  }
}
