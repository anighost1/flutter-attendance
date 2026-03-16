import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime today = DateTime.now();

  /// Dummy attendance map
  final Map<DateTime, String> attendance = {
    DateTime(2026, 3, 1): "P",
    DateTime(2026, 3, 2): "P",
    DateTime(2026, 3, 3): "A",
    DateTime(2026, 3, 4): "P",
    DateTime(2026, 3, 5): "P",
    DateTime(2026, 3, 6): "P",
    DateTime(2026, 3, 7): "P",
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final currentDate = DateFormat('dd MMM yyyy').format(now);
    final currentMonth = DateFormat('MMMM').format(now);

    /// Dummy stats
    int present = 18;
    int absent = 3;
    int late = 2;
    int leave = 1;

    int total = present + absent + late + leave;
    double percent = (present / total) * 100;

    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Dashboard")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// DATE
            Text(
              "Today: $currentDate",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Text("Month: $currentMonth"),

            const SizedBox(height: 20),

            /// STATS GRID
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                statCard("Present", present, Colors.green),
                statCard("Absent", absent, Colors.red),
                statCard("Percentage", percent, Colors.orange),
                statCard("Leave", leave, Colors.blue),
              ],
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 25),

            const Text(
              "Monthly Attendance",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            /// CALENDAR
            TableCalendar(
              focusedDay: today,
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),

              /// FIX FOR ERROR
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},

              headerStyle: const HeaderStyle(formatButtonVisible: false),

              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  for (var entry in attendance.entries) {
                    if (isSameDay(day, entry.key)) {
                      Color color = Colors.green;

                      if (entry.value == "A") color = Colors.red;

                      return Container(
                        margin: const EdgeInsets.all(6),

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
                  }

                  return null;
                },
              ),
            ),

            const SizedBox(height: 15),

            /// LEGEND
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Legend(color: Colors.green, text: "Present"),
                Legend(color: Colors.red, text: "Absent"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// STAT CARD
  Widget statCard(String title, num value, Color color) {
    return Card(
      elevation: 3,

      child: Container(
        padding: const EdgeInsets.all(16),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text(
              "$value",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 6),

            Text(title),
          ],
        ),
      ),
    );
  }
}

/// LEGEND WIDGET
class Legend extends StatelessWidget {
  final Color color;
  final String text;

  const Legend({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 6),

        Text(text),
      ],
    );
  }
}
