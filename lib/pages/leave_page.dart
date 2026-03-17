import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final DBHelper _dbHelper = DBHelper();

  // Local variables to hold counts
  int slCount = 0;
  int clCount = 0;
  int plCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshBalances();
  }

  // Fetch data from Database
  Future<void> _refreshBalances() async {
    setState(() => isLoading = true);
    final balances = await _dbHelper.getAllLeaveBalances();
    setState(() {
      slCount = balances['SL'] ?? 0;
      clCount = balances['CL'] ?? 0;
      plCount = balances['PL'] ?? 0;
      isLoading = false;
    });
  }

  // Show dialog to edit the number
  void _showEditDialog(String typeKey, String displayName, int currentCount) {
    final TextEditingController controller = TextEditingController(
      text: currentCount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $displayName"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Remaining Leaves",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              int? newValue = int.tryParse(controller.text);
              if (newValue != null) {
                await _dbHelper.updateLeaveBalance(typeKey, newValue);
                Navigator.pop(context);
                _refreshBalances(); // Reload from DB
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leave Management"), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Leave Balances",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _buildLeaveCard("SL", "Sick Leave", slCount, Colors.orange),
                  _buildLeaveCard("CL", "Casual Leave", clCount, Colors.blue),
                  _buildLeaveCard(
                    "PL",
                    "Privileged Leave",
                    plCount,
                    Colors.green,
                  ),

                  const Spacer(),
                  const Center(
                    child: Text(
                      "Updates are saved automatically to the database.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLeaveCard(String typeKey, String label, int count, Color color) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.beach_access, color: color),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "$count Days Available",
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_note, color: Colors.grey),
          onPressed: () => _showEditDialog(typeKey, label, count),
        ),
      ),
    );
  }
}
