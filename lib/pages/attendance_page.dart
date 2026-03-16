import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime today = DateTime.now();

  /// Attendance map
  Map<DateTime, String> attendance = {};

  /// Set attendance
  void setAttendance(DateTime day, String status) {
    setState(() {
      attendance[DateTime(day.year, day.month, day.day)] = status;
    });
  }

  /// Remove attendance
  void removeAttendance(DateTime day) {
    setState(() {
      attendance.remove(DateTime(day.year, day.month, day.day));
    });
  }

  /// Attendance selector dialog
  void showAttendanceDialog(DateTime day) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              const Text(
                "Mark Attendance",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text("Present"),
                onTap: () {
                  setAttendance(day, "P");
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text("Absent"),
                onTap: () {
                  setAttendance(day, "A");
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.event_busy, color: Colors.blue),
                title: const Text("Leave"),
                onTap: () {
                  setAttendance(day, "L");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Manager")),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TableCalendar(
              focusedDay: today,
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),

              availableCalendarFormats: const {CalendarFormat.month: 'Month'},

              headerStyle: const HeaderStyle(formatButtonVisible: false),

              onDaySelected: (selectedDay, focusedDay) {
                showAttendanceDialog(selectedDay);
              },

              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  for (var entry in attendance.entries) {
                    if (isSameDay(day, entry.key)) {
                      Color color = Colors.green;

                      if (entry.value == "A") color = Colors.red;
                      if (entry.value == "L") color = Colors.blue;

                      return GestureDetector(
                        onLongPress: () {
                          removeAttendance(day);
                        },

                        child: Container(
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
                        ),
                      );
                    }
                  }

                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            /// Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Legend(color: Colors.green, text: "Present"),
                Legend(color: Colors.red, text: "Absent"),
                Legend(color: Colors.blue, text: "Leave"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Legend widget
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
