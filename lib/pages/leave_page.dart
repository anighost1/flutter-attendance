import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final DBHelper _dbHelper = DBHelper();
  Map<String, int> balances = {"SL": 0, "CL": 0, "PL": 0};

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    final data = await _dbHelper.getRemainingBalances();
    setState(() => balances = data);
  }

  // Dialog to edit the Total Quota
  void _showEditQuotaDialog(String type, String label) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Total $label"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Enter Total Yearly Quota",
            hintText: "e.g. 12",
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
              int? newQuota = int.tryParse(controller.text);
              if (newQuota != null) {
                await _dbHelper.updateTotalQuota(type, newQuota);
                Navigator.pop(context);
                _loadBalances(); // Refresh UI
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leave Balance"), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _loadBalances,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0, left: 4),
              child: Text(
                "Remaining Days",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            _buildCard("SL", "Sick Leave", balances['SL']!, Colors.orange),
            _buildCard("CL", "Casual Leave", balances['CL']!, Colors.blue),
            _buildCard("PL", "Privileged Leave", balances['PL']!, Colors.green),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Tip: Click the edit icon to change your total yearly quota.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String type, String label, int count, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Remaining balance"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$count",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.grey),
              onPressed: () => _showEditQuotaDialog(type, label),
            ),
          ],
        ),
      ),
    );
  }
}
