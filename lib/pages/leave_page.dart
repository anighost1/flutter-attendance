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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getRemainingBalances();
    setState(() {
      balances = data;
      _isLoading = false;
    });
  }

  void _editQuota(String type) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Yearly $type Quota"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter total days"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _dbHelper.updateTotalQuota(
                  type,
                  int.parse(controller.text),
                );
                Navigator.pop(context);
                _loadBalances();
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
      backgroundColor: const Color(0xFFF3F6F9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 80,
                  pinned: true,
                  backgroundColor: const Color(0xFFF3F6F9),
                  title: const Text(
                    "Leave Balances",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    _leaveCard(
                      "SL",
                      "Sick Leave",
                      balances['SL']!,
                      Colors.orange,
                    ),
                    _leaveCard(
                      "CL",
                      "Casual Leave",
                      balances['CL']!,
                      Colors.blue,
                    ),
                    _leaveCard(
                      "PL",
                      "Privileged Leave",
                      balances['PL']!,
                      Colors.green,
                    ),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _leaveCard(String type, String label, int count, Color col) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Remaining Balance",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: col,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _editQuota(type),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
