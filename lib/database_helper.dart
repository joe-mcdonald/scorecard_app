import 'dart:convert';
import 'package:scorecard_app/models/player.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
    String path = join(await getDatabasesPath(), 'golf_app.db');

    // Delete the existing database (for development purposes)
    await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        handicap REAL,
        score TEXT
      )
    ''');
    Player player = Player(
      name: 'Player 1',
      handicap: 10.0,
      score: [],
    );
    addPlayer(player.toMap());
  }

  Future<int> addPlayer(Map<String, dynamic> player) async {
    final db = await database;
    return await db.insert('players', player);
    // return await db.insert('players', {
    //   'name': name,
    //   'handicap': handicap,
    //   'score': jsonEncode(scores),
    // });
  }

  // Future<int> updatePlayer(
  //     int id, String name, double handicap, List<int> scores) async {
  //   final db = await database;
  //   return await db.update(
  //       'players',
  //       {
  //         'name': name,
  //         'handicap': handicap,
  //         'score': jsonEncode(scores),
  //       },
  //       where: 'id = ?',
  //       whereArgs: [id]);
  // }

  Future<void> updatePlayer(Player player) async {
    final db = await database;
    await db.update(
      'players',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  Future<int> deletePlayer(int id) async {
    final db = await database;
    return await db.delete(
      'players',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Player>> getPlayers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('players');
    return List.generate(maps.length, (i) {
      return Player.fromMap(maps[i]);
    });
  }

  // Future<List<Map<String, dynamic>>> getPlayers() async {
  //   final db = await database;
  //   return await db.query('players');
  // }
}
