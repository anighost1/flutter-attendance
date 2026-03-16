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

  /// Sync local map with SQLite data
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

  /// Auto-Fill logic (Up to today, Saturday included, Sunday skipped)
  Future<void> _generateDefaultAttendance() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    DateTime endDay;
    if (_focusedDay.year == now.year && _focusedDay.month == now.month) {
      endDay = DateTime(now.year, now.month, now.day);
    } else {
      endDay = lastDayOfMonth;
    }

    for (int i = 0; i < endDay.day; i++) {
      final currentDay = firstDay.add(Duration(days: i));
      final dateKey = DateTime(
        currentDay.year,
        currentDay.month,
        currentDay.day,
      );

      if (!_attendanceMap.containsKey(dateKey) &&
          currentDay.weekday != DateTime.sunday) {
        await _dbHelper.markAttendance(currentDay, "absent");
      }
    }

    await _fetchAttendance();
  }

  Future<void> _clearMonthAttendance() async {
    setState(() => _isLoading = true);
    await _dbHelper.clearMonthAttendance(_focusedDay.year, _focusedDay.month);
    await _fetchAttendance();
  }

  Future<void> _updateStatus(DateTime day, String status) async {
    await _dbHelper.markAttendance(day, status);
    await _fetchAttendance();
  }

  Future<void> _removeStatus(DateTime day) async {
    await _dbHelper.deleteAttendance(day);
    await _fetchAttendance();
  }

  // --- REDESIGNED ACTION SHEET ---
  void _showActionSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Mark Attendance",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              "${day.day} ${_getMonthName(day.month)} ${day.year}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statusButton(
                  Icons.check_circle_rounded,
                  Colors.green,
                  "Present",
                  () => _updateStatus(day, "present"),
                ),
                _statusButton(
                  Icons.cancel_rounded,
                  Colors.red,
                  "Absent",
                  () => _updateStatus(day, "absent"),
                ),
                _statusButton(
                  Icons.event_busy_rounded,
                  Colors.blue,
                  "Leave",
                  () => _updateStatus(day, "leave"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(
    IconData icon,
    Color color,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REDESIGNED CONFIRMATION DIALOG ---
  void _showConfirmDialog(
    String title,
    String content,
    VoidCallback onConfirm, {
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            Icon(
              isDestructive
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline_rounded,
              color: isDestructive ? Colors.red : Colors.blue,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          content,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDestructive
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: Text(isDestructive ? "Confirm" : "Continue"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Manager"),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'gen')
                _showConfirmDialog(
                  "Auto-Fill",
                  "Mark empty weekdays and Saturdays as absent?",
                  _generateDefaultAttendance,
                );
              if (value == 'clear')
                _showConfirmDialog(
                  "Reset Month",
                  "Delete all records for this month?",
                  _clearMonthAttendance,
                  isDestructive: true,
                );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'gen',
                child: Text("Fill Missing Days"),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text("Clear Month", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildCalendar(),
                  const SizedBox(height: 16),
                  _buildLegend(),
                  const SizedBox(height: 24),
                  _buildMonthlySummary(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: TableCalendar(
        focusedDay: _focusedDay,
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() => _focusedDay = focusedDay);
          _showActionSheet(selectedDay);
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final dateKey = DateTime(day.year, day.month, day.day);
            if (_attendanceMap.containsKey(dateKey)) {
              final status = _attendanceMap[dateKey];
              Color color = status == "present"
                  ? Colors.green
                  : (status == "absent" ? Colors.red : Colors.blue);
              return GestureDetector(
                onLongPress: () => _removeStatus(day),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${day.day}",
                      style: const TextStyle(
                        color: Colors.white,
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
    );
  }

  Widget _buildLegend() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LegendItem(color: Colors.green, text: "Present"),
        SizedBox(width: 20),
        LegendItem(color: Colors.red, text: "Absent"),
        SizedBox(width: 20),
        LegendItem(color: Colors.blue, text: "Leave"),
      ],
    );
  }

  Widget _buildMonthlySummary() {
    int p = _attendanceMap.entries
        .where(
          (e) =>
              e.key.month == _focusedDay.month &&
              e.key.year == _focusedDay.year &&
              e.value == "present",
        )
        .length;
    int a = _attendanceMap.entries
        .where(
          (e) =>
              e.key.month == _focusedDay.month &&
              e.key.year == _focusedDay.year &&
              e.value == "absent",
        )
        .length;
    int l = _attendanceMap.entries
        .where(
          (e) =>
              e.key.month == _focusedDay.month &&
              e.key.year == _focusedDay.year &&
              e.value == "leave",
        )
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _statCard("Present", p.toString(), Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _statCard("Absent", a.toString(), Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _statCard("Leave", l.toString(), Colors.blue)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
