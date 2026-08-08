import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/entry.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'daily_journal.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            date TEXT PRIMARY KEY,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<Entry?> getEntry(String date) async {
    final db = await database;
    final results = await db.query(
      'entries',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (results.isEmpty) return null;
    return Entry.fromMap(results.first);
  }

  Future<void> saveEntry(Entry entry) async {
    final db = await database;
    await db.insert(
      'entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getEntryDates() async {
    final db = await database;
    final results = await db.query(
      'entries',
      columns: ['date'],
      orderBy: 'date DESC',
    );
    return results.map((r) => r['date'] as String).toList();
  }

  Future<String?> getPreviousEntryDate(String currentDate) async {
    final db = await database;
    final results = await db.query(
      'entries',
      columns: ['date'],
      where: 'date < ?',
      whereArgs: [currentDate],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['date'] as String;
  }

  Future<String?> getNextEntryDate(String currentDate) async {
    final db = await database;
    final results = await db.query(
      'entries',
      columns: ['date'],
      where: 'date > ?',
      whereArgs: [currentDate],
      orderBy: 'date ASC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['date'] as String;
  }
}
