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

    await db.execute('''
      CREATE TABLE PlayerDetails (
        playerIndex INTEGER PRIMARY KEY,
        name TEXT,
        handicap INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE RecentCourse (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseName TEXT,
        tees TEXT
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

  Future<int> getScoreForHole(int playerIndex, int holeIndex) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'PlayerScores',
      where: 'playerIndex = ? AND holeIndex = ?',
      whereArgs: [playerIndex, holeIndex],
    );
    if (maps.isNotEmpty) {
      return maps.first['score'] as int;
    } else {
      return 0;
    }
  }

  Future<int?> getHandicap(int playerIndex) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'PlayerDetails',
      where: 'playerIndex = ?',
      whereArgs: [playerIndex],
    );
    if (maps.isNotEmpty) {
      return maps.first['handicap'] as int?;
    } else {
      return 0;
    }
  }

  Future<void> setHandicap(int playerIndex, int handicap) async {
    final db = await database;
    await db.update('PlayerDetails', {'handicap': handicap},
        where: 'playerIndex = ?', whereArgs: [playerIndex]);
  }

  Future<String?> getPlayerName(int playerIndex) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'PlayerDetails',
      where: 'playerIndex = ?',
      whereArgs: [playerIndex],
    );
    if (maps.isNotEmpty) {
      return maps.first['name'] as String?;
    } else {
      return 'Name';
    }
  }

  Future<List<Map<String, dynamic>>> getPlayerNames() async {
    final db = await database;
    //get names from PlayerDetails table
    return await db.query('PlayerDetails');
  }

  Future<int> getPlayerCount() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('PlayerDetails');
    //i need to return an int so i return the length of the list
    return maps.length;
  }

  Future<void> setPlayerName(int playerIndex, String name) async {
    final db = await database;
    await db.update('PlayerDetails', {'name': name},
        where: 'playerIndex = ?', whereArgs: [playerIndex]);
  }

  Future<void> insertPlayerDetails(
      int playerIndex, String name, int handicap) async {
    final db = await database;
    await db.insert(
      'PlayerDetails',
      {'playerIndex': playerIndex, 'name': name, 'handicap': handicap},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removePlayerDetails(int playerIndex) async {
    final db = await database;
    await db.delete('PlayerDetails',
        where: 'playerIndex = ?', whereArgs: [playerIndex]);
  }

  Future<void> deleteScores() async {
    final db = await database;
    await db.delete('PlayerScores');
  }

  Future<void> deletePlayerScores(int playerIndex) async {
    final db = await database;
    await db.delete('PlayerScores',
        where: 'playerIndex = ?', whereArgs: [playerIndex]);
  }

  Future<void> updatePlayerName(int playerIndex, String newName) async {
    final db = await database;
    await db.update('PlayerDetails', {'name': newName},
        where: 'playerIndex = ?', whereArgs: [playerIndex]);
  }

  Future<void> insertRecentCourse(String courseName, String tees) async {
    final db = await database;
    await db.insert(
      'RecentCourse',
      {
        'courseName': courseName,
        'tees': tees,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String?>> getRecentCourse() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('RecentCourse');
    if (maps.isNotEmpty) {
      return {
        'courseName': maps.last['courseName'] as String?,
        'tees': maps.last['tees'] as String?,
      };
    } else {
      return {'courseName': 'Shaughnessy G&CC', 'tees': 'Whites'};
    }
  }
}
