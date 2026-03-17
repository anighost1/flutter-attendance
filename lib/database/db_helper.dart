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
      version: 2, // Version 2 to include Leave Table
      onCreate: (db, version) async {
        // Create Attendance Table
        await db.execute('''
          CREATE TABLE attendance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            attendance_date TEXT UNIQUE,
            status TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Create Leaves Table
        await db.execute('''
          CREATE TABLE leaves(
            type TEXT PRIMARY KEY, 
            balance INTEGER
          )
        ''');

        // Initialize default leave values
        await _seedLeaves(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // If user is upgrading from version 1, add the leaves table
          await db.execute('''
            CREATE TABLE leaves(
              type TEXT PRIMARY KEY, 
              balance INTEGER
            )
          ''');
          await _seedLeaves(db);
        }
      },
    );
  }

  /// Helper to insert initial leave records
  Future<void> _seedLeaves(Database db) async {
    await db.insert("leaves", {
      "type": "SL",
      "balance": 6,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert("leaves", {
      "type": "CL",
      "balance": 6,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert("leaves", {
      "type": "PL",
      "balance": 12,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // ==========================================
  // LEAVE MANAGEMENT METHODS
  // ==========================================

  /// Get all leave balances as a Map (e.g., {"SL": 6, "CL": 5})
  Future<Map<String, int>> getAllLeaveBalances() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query("leaves");

    return {
      for (var item in maps) item['type'] as String: item['balance'] as int,
    };
  }

  /// Update a specific leave balance
  Future<int> updateLeaveBalance(String type, int newBalance) async {
    final db = await database;
    return await db.update(
      "leaves",
      {"balance": newBalance},
      where: "type = ?",
      whereArgs: [type],
    );
  }

  // ==========================================
  // ATTENDANCE METHODS (EXISTING)
  // ==========================================

  /// Mark or Update Attendance
  Future<int> markAttendance(DateTime date, String status) async {
    final db = await database;
    String dateStr = date.toIso8601String().split("T")[0]; // YYYY-MM-DD

    return db.insert("attendance", {
      "attendance_date": dateStr,
      "status": status,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Remove Attendance
  Future<int> deleteAttendance(DateTime date) async {
    final db = await database;
    String dateStr = date.toIso8601String().split("T")[0];
    return await db.delete(
      "attendance",
      where: "attendance_date = ?",
      whereArgs: [dateStr],
    );
  }

  /// Get All Data
  Future<List<Map<String, dynamic>>> getAttendance() async {
    final db = await database;
    return db.query("attendance", orderBy: "attendance_date DESC");
  }

  /// Delete all records for a specific month and year
  Future<int> clearMonthAttendance(int year, int month) async {
    final db = await database;
    String monthStr = month.toString().padLeft(2, '0');

    return await db.delete(
      "attendance",
      where:
          "strftime('%Y', attendance_date) = ? AND strftime('%m', attendance_date) = ?",
      whereArgs: [year.toString(), monthStr],
    );
  }
}
