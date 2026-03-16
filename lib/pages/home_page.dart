import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/db_helper.dart'; // Ensure path is correct

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DBHelper _dbHelper = DBHelper();
  DateTime _today = DateTime.now();
  Map<DateTime, String> _attendanceMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Calculate Stats for current month
    int present = _attendanceMap.entries
        .where((e) => e.key.month == now.month && e.value == "present")
        .length;
    int absent = _attendanceMap.entries
        .where((e) => e.key.month == now.month && e.value == "absent")
        .length;
    int leave = _attendanceMap.entries
        .where((e) => e.key.month == now.month && e.value == "leave")
        .length;

    int totalWorkingDays = present + absent + leave;
    double percentage = totalWorkingDays > 0
        ? (present / totalWorkingDays) * 100
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(now),
                  const SizedBox(height: 24),
                  _buildStatsGrid(present, absent, leave, percentage),
                  const SizedBox(height: 32),
                  const Text(
                    "Recent Activity",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildCalendarCard(),
                  const SizedBox(height: 20),
                  _buildLegend(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(DateTime now) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, dd MMMM').format(now),
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const Text(
          "Welcome back, Anil!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(int p, int a, int l, double pct) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _statCard(
          "Present",
          p.toString(),
          Colors.green,
          Icons.check_circle_outline,
        ),
        _statCard("Absent", a.toString(), Colors.red, Icons.highlight_off),
        _statCard("Leaves", l.toString(), Colors.blue, Icons.highlight_off),
        _statCard(
          "Attendance",
          "${pct.toStringAsFixed(1)}%",
          Colors.orange,
          Icons.analytics_outlined,
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TableCalendar(
        focusedDay: _today,
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        calendarFormat: CalendarFormat.month,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final dateKey = DateTime(day.year, day.month, day.day);
            if (_attendanceMap.containsKey(dateKey)) {
              final status = _attendanceMap[dateKey];
              Color color = status == "present"
                  ? Colors.green
                  : (status == "absent" ? Colors.red : Colors.blue);

              return Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    "${day.day}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendItem(color: Colors.green, label: "P"),
        SizedBox(width: 16),
        _LegendItem(color: Colors.red, label: "A"),
        SizedBox(width: 16),
        _LegendItem(color: Colors.blue, label: "L"),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
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
