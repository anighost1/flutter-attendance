import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    await _fetchAttendance();
  }

  // --- UPDATED LOGIC: Auto-fill past days as ABSENT ---
  Future<void> _fillMonth() async {
    setState(() => _isLoading = true);

    // Limits the fill to the currently viewed month
    DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    DateTime lastDayOfMonth = DateTime(
      _focusedDay.year,
      _focusedDay.month + 1,
      0,
    );

    // Current date for comparison (Today at 00:00:00)
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < lastDayOfMonth.day; i++) {
      DateTime day = firstDayOfMonth.add(Duration(days: i));

      // Rule: Only older than today AND not a weekend AND not already marked
      if (day.isBefore(today)) {
        if (day.weekday != DateTime.saturday &&
            day.weekday != DateTime.sunday) {
          final dateKey = DateTime(day.year, day.month, day.day);
          if (!_attendanceMap.containsKey(dateKey)) {
            await _dbHelper.markAttendance(day, "absent");
          }
        }
      }
    }
    await _fetchAttendance();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Past missing days marked as Absent")),
    );
  }

  Future<void> _clearMonth() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Month?"),
        content: const Text("Delete all records for this month?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      await _dbHelper.clearMonthAttendance(_focusedDay);
      await _fetchAttendance();
    }
  }

  void _showActionSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EEE, MMM dd').format(day),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionIcon(Icons.check_circle, "Present", Colors.green, () {
                  _updateStatus(day, "present");
                  Navigator.pop(context);
                }),
                _actionIcon(Icons.cancel, "Absent", Colors.red, () {
                  _updateStatus(day, "absent");
                  Navigator.pop(context);
                }),
                _actionIcon(Icons.beach_access, "Leave", Colors.blue, () {
                  Navigator.pop(context);
                  _showLeavePicker(day);
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon(
    IconData icon,
    String label,
    Color col,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: col, size: 40),
          onPressed: onTap,
        ),
        Text(
          label,
          style: TextStyle(color: col, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showLeavePicker(DateTime day) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ["SL", "CL", "PL"]
            .map(
              (type) => ListTile(
                title: Text(
                  type == "SL"
                      ? "Sick Leave"
                      : type == "CL"
                      ? "Casual Leave"
                      : "Privileged Leave",
                ),
                leading: const Icon(Icons.circle, color: Colors.blueAccent),
                onTap: () {
                  _updateStatus(day, "leave", leaveType: type);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 80,
                  pinned: true,
                  backgroundColor: const Color(0xFFF3F6F9),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      "Attendance",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 10),
                            ],
                          ),
                          child: TableCalendar(
                            focusedDay: _focusedDay,
                            firstDay: DateTime(2020),
                            lastDay: DateTime(2030),
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                            ),
                            onDaySelected: (sel, foc) => _showActionSheet(sel),
                            onPageChanged: (foc) =>
                                setState(() => _focusedDay = foc),
                            calendarBuilders: CalendarBuilders(
                              defaultBuilder: (context, day, focusedDay) {
                                final dateKey = DateTime(
                                  day.year,
                                  day.month,
                                  day.day,
                                );
                                if (_attendanceMap.containsKey(dateKey)) {
                                  final status = _attendanceMap[dateKey];
                                  Color c = status == "present"
                                      ? Colors.green
                                      : (status == "absent"
                                            ? Colors.red
                                            : Colors.blue);
                                  return Center(
                                    child: Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: c.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: c),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${day.day}",
                                          style: TextStyle(
                                            color: c,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _bulkBtn(
                                Icons.flash_on,
                                "Auto-Fill",
                                Colors.blueGrey,
                                _fillMonth,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _bulkBtn(
                                Icons.delete_sweep,
                                "Clear",
                                Colors.redAccent,
                                _clearMonth,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _bulkBtn(IconData icon, String label, Color col, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: col.withOpacity(0.1),
        foregroundColor: col,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
