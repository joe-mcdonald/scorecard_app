import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'scorecard_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE PlayerScores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playerIndex INTEGER,
        holeIndex INTEGER,
        score INTEGER
      )
    ''');
  }

  Future<void> insertScore(int playerIndex, int holeIndex, int score) async {
    final db = await database;
    await db.insert(
      'PlayerScores',
      {'playerIndex': playerIndex, 'holeIndex': holeIndex, 'score': score},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getScores() async {
    final db = await database;
    return await db.query('PlayerScores');
  }

  Future<void> deleteScores() async {
    final db = await database;
    await db.delete('PlayerScores');
  }
}
