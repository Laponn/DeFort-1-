import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'scan_history_item.dart';

class DatabaseHelper {
  // Pola Singleton
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('defort_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE scan_history (
  id $idType,
  scan_type $textType,
  timestamp $integerType,
  status $textType,
  summary $textType,
  details $textType
)
''');
  }

  /// Memasukkan data scan baru ke database
  Future<void> insertScan(ScanHistoryItem item) async {
    final db = await instance.database;
    await db.insert(
      'scan_history',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil semua riwayat, diurutkan dari yang terbaru (timestamp descending)
  Future<List<ScanHistoryItem>> getAllScans() async {
    final db = await instance.database;
    final orderBy = 'timestamp DESC';
    
    final result = await db.query('scan_history', orderBy: orderBy);

    return result.map((json) => ScanHistoryItem.fromMap(json)).toList();
  }

  /// Menghapus semua data (opsional, untuk tombol "Clear History")
  Future<void> clearHistory() async {
    final db = await instance.database;
    await db.delete('scan_history');
  }
}
