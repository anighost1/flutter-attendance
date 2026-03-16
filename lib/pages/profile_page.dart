import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    /// Dummy profile data
    const String name = "Anil Tigga";
    const String employeeId = "EMP1023";
    const String department = "Software Development";
    const String designation = "Full Stack Developer";
    const String email = "anil.tigga@example.com";
    const String phone = "+91 9876543210";

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            /// PROFILE HEADER
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(designation),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// PROFILE DETAILS
            profileTile(Icons.badge, "Employee ID", employeeId),
            profileTile(Icons.apartment, "Department", department),
            profileTile(Icons.work, "Designation", designation),
            profileTile(Icons.email, "Email", email),
            profileTile(Icons.phone, "Phone", phone),

            const SizedBox(height: 20),

            /// LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),

                onPressed: () {
                  /// Later connect logout logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logout clicked")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// PROFILE INFO TILE
  Widget profileTile(IconData icon, String title, String value) {
    return Card(
      elevation: 2,

      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
