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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE attendance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            attendance_date TEXT UNIQUE,
            status TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

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
