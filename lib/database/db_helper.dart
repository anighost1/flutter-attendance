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

  /// MARK ATTENDANCE
  Future<int> markAttendance(String status) async {
    final db = await database;

    String today = DateTime.now().toIso8601String().split("T")[0];

    return db.insert("attendance", {
      "attendance_date": today,
      "status": status,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// GET ALL ATTENDANCE
  Future<List<Map<String, dynamic>>> getAttendance() async {
    final db = await database;

    return db.query("attendance", orderBy: "attendance_date DESC");
  }

  /// CHECK IF TODAY IS MARKED
  Future<bool> isTodayMarked() async {
    final db = await database;

    String today = DateTime.now().toIso8601String().split("T")[0];

    var result = await db.query(
      "attendance",
      where: "attendance_date=?",
      whereArgs: [today],
    );

    return result.isNotEmpty;
  }

  /// GET MONTHLY STATS
  Future<Map<String, int>> getMonthlyStats(int year, int month) async {
    final db = await database;

    String monthStr = month.toString().padLeft(2, '0');

    var result = await db.rawQuery(
      '''
      SELECT 
        SUM(CASE WHEN status='present' THEN 1 ELSE 0 END) as present_days,
        SUM(CASE WHEN status='absent' THEN 1 ELSE 0 END) as absent_days,
        SUM(CASE WHEN status='leave' THEN 1 ELSE 0 END) as leave_days
      FROM attendance
      WHERE strftime('%Y', attendance_date)=?
      AND strftime('%m', attendance_date)=?
    ''',
      [year.toString(), monthStr],
    );

    return {
      "present": result.first["present_days"] as int? ?? 0,
      "absent": result.first["absent_days"] as int? ?? 0,
      "leave": result.first["leave_days"] as int? ?? 0,
    };
  }

  /// GET ATTENDANCE PERCENTAGE
  Future<double> getAttendancePercentage(int year, int month) async {
    final stats = await getMonthlyStats(year, month);

    int present = stats["present"] ?? 0;
    int absent = stats["absent"] ?? 0;
    int leave = stats["leave"] ?? 0;

    int total = present + absent + leave;

    if (total == 0) return 0;

    return (present / total) * 100;
  }

  /// DELETE DATABASE (for reset during development)
  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'attendance.db');
    await deleteDatabase(path);
  }
}
