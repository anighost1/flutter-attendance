import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'attendance.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE attendance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            attendance_date TEXT UNIQUE,
            status TEXT,
            leave_type TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        await db.execute(
          'CREATE TABLE leaves(type TEXT PRIMARY KEY, total_quota INTEGER)',
        );
        await _seedLeaves(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          try {
            await db.execute(
              'ALTER TABLE attendance ADD COLUMN leave_type TEXT',
            );
          } catch (_) {}
          try {
            await db.execute(
              'CREATE TABLE IF NOT EXISTS leaves(type TEXT PRIMARY KEY, total_quota INTEGER)',
            );
          } catch (_) {}
          await _seedLeaves(db);
        }
      },
    );
  }

  Future<void> _seedLeaves(Database db) async {
    await db.insert("leaves", {
      "type": "SL",
      "total_quota": 6,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert("leaves", {
      "type": "CL",
      "total_quota": 6,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert("leaves", {
      "type": "PL",
      "total_quota": 12,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Map<String, int>> getRemainingBalances() async {
    final db = await database;
    final List<Map<String, dynamic>> quotaMaps = await db.query("leaves");
    final List<Map<String, dynamic>> usedMaps = await db.rawQuery('''
      SELECT leave_type, COUNT(*) as used FROM attendance 
      WHERE status = 'leave' AND leave_type IS NOT NULL GROUP BY leave_type
    ''');

    Map<String, int> balances = {};
    for (var row in quotaMaps) {
      String type = row['type'];
      int total = row['total_quota'];
      int used = 0;
      for (var u in usedMaps) {
        if (u['leave_type'] == type) used = u['used'];
      }
      balances[type] = total - used;
    }
    return balances;
  }

  Future<int> markAttendance(
    DateTime date,
    String status, {
    String? leaveType,
  }) async {
    final db = await database;
    String dateStr = date.toIso8601String().split("T")[0];

    if (status.toLowerCase() == "leave" && leaveType != null) {
      final balances = await getRemainingBalances();
      if ((balances[leaveType] ?? 0) <= 0) {
        // Check if we are just updating an existing record of the same type
        final existing = await db.query(
          "attendance",
          where: "attendance_date = ?",
          whereArgs: [dateStr],
        );
        bool isUpdate =
            existing.isNotEmpty && existing.first['leave_type'] == leaveType;
        if (!isUpdate) return -1; // Block: No balance left
      }
    }

    return db.insert("attendance", {
      "attendance_date": dateStr,
      "status": status.toLowerCase(),
      "leave_type": status.toLowerCase() == "leave" ? leaveType : null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTotalQuota(String type, int newQuota) async {
    final db = await database;
    return await db.update(
      "leaves",
      {"total_quota": newQuota},
      where: "type = ?",
      whereArgs: [type],
    );
  }

  Future<int> deleteAttendance(DateTime date) async {
    final db = await database;
    return await db.delete(
      "attendance",
      where: "attendance_date = ?",
      whereArgs: [date.toIso8601String().split("T")[0]],
    );
  }

  Future<List<Map<String, dynamic>>> getAttendance() async {
    final db = await database;
    return db.query("attendance", orderBy: "attendance_date DESC");
  }

  Future<int> clearMonthAttendance(int year, int month) async {
    final db = await database;
    String m = month.toString().padLeft(2, '0');
    return await db.delete(
      "attendance",
      where:
          "strftime('%Y', attendance_date) = ? AND strftime('%m', attendance_date) = ?",
      whereArgs: [year.toString(), m],
    );
  }
}
