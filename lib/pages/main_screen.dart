import 'package:flutter/material.dart';
import 'home_page.dart';
import 'attendance_page.dart';
import 'leave_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    AttendancePage(),
    LeavePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Extend body behind the navigation bar if you want a translucent effect
      extendBody: true,
      body: pages[currentIndex],

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          20,
        ), // Adds a floating effect
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },

            // --- UI ENHANCEMENTS ---
            elevation: 0,
            backgroundColor: Colors.white,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: Colors.grey.shade400,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,

            // Customizing the active icon look
            items: [
              _buildNavItem(
                Icons.dashboard_rounded,
                Icons.dashboard_outlined,
                "Home",
              ),
              _buildNavItem(
                Icons.calendar_month_rounded,
                Icons.calendar_month_outlined,
                "Attendance",
              ),
              _buildNavItem(
                Icons.event_note_rounded,
                Icons.event_note_outlined,
                "Leave",
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(inactiveIcon),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(activeIcon),
      ),
      label: label,
    );
  }
}
