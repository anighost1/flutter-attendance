import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() => _instance;
  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'attendance_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            attendance_date TEXT UNIQUE,
            status TEXT,
            leave_type TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE leave_quota (
            type TEXT PRIMARY KEY,
            total_days INTEGER
          )
        ''');
        // Initialize default quotas
        await db.insert('leave_quota', {'type': 'SL', 'total_days': 12});
        await db.insert('leave_quota', {'type': 'CL', 'total_days': 12});
        await db.insert('leave_quota', {'type': 'PL', 'total_days': 15});
      },
    );
  }

  // Mark attendance with balance check
  Future<int> markAttendance(
    DateTime date,
    String status, {
    String? leaveType,
  }) async {
    final db = await database;
    String dateStr = DateFormat('yyyy-MM-dd').format(date);

    if (status == 'leave' && leaveType != null) {
      final balances = await getRemainingBalances();
      if ((balances[leaveType] ?? 0) <= 0)
        return -1; // Error code for no balance
    }

    return await db.insert('attendance', {
      'attendance_date': dateStr,
      'status': status,
      'leave_type': leaveType,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Clear all records for a specific month
  Future<void> clearMonthAttendance(DateTime focusedDay) async {
    final db = await database;
    String monthPattern = DateFormat('yyyy-MM').format(focusedDay);
    await db.delete(
      'attendance',
      where: "attendance_date LIKE ?",
      whereArgs: ["$monthPattern%"],
    );
  }

  Future<List<Map<String, dynamic>>> getAttendance() async {
    final db = await database;
    return await db.query('attendance');
  }

  Future<void> updateTotalQuota(String type, int total) async {
    final db = await database;
    await db.insert('leave_quota', {
      'type': type,
      'total_days': total,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, int>> getRemainingBalances() async {
    final db = await database;
    final quotaData = await db.query('leave_quota');
    final attendanceData = await db.query(
      'attendance',
      where: "status = 'leave'",
    );

    Map<String, int> totals = {};
    for (var row in quotaData) {
      totals[row['type'] as String] = row['total_days'] as int;
    }

    Map<String, int> used = {"SL": 0, "CL": 0, "PL": 0};
    for (var row in attendanceData) {
      String? type = row['leave_type'] as String?;
      if (type != null && used.containsKey(type)) {
        used[type] = used[type]! + 1;
      }
    }

    return {
      "SL": (totals['SL'] ?? 0) - used['SL']!,
      "CL": (totals['CL'] ?? 0) - used['CL']!,
      "PL": (totals['PL'] ?? 0) - used['PL']!,
    };
  }
}
