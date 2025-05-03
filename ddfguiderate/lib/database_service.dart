import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'episode_state.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE episode_state (
            episode_id TEXT PRIMARY KEY,
            note TEXT,
            rating INTEGER,
            listened INTEGER
          )
        ''');
      },
    );
  }

  Future<Map<String, dynamic>?> getEpisodeState(String episodeId) async {
    final dbClient = await db;
    final res = await dbClient.query(
      'episode_state',
      where: 'episode_id = ?',
      whereArgs: [episodeId],
    );
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  Future<void> setNote(String episodeId, String note) async {
    final dbClient = await db;
    await dbClient.insert(
      'episode_state',
      {'episode_id': episodeId, 'note': note},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setRating(String episodeId, int rating) async {
    final dbClient = await db;
    await dbClient.insert(
      'episode_state',
      {'episode_id': episodeId, 'rating': rating},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setListened(String episodeId, bool listened) async {
    final dbClient = await db;
    await dbClient.insert(
      'episode_state',
      {'episode_id': episodeId, 'listened': listened ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateEpisodeState(String episodeId, {String? note, int? rating, bool? listened}) async {
    final dbClient = await db;
    final updateMap = <String, Object?>{};
    if (note != null) updateMap['note'] = note;
    if (rating != null) updateMap['rating'] = rating;
    if (listened != null) updateMap['listened'] = listened ? 1 : 0;
    if (updateMap.isNotEmpty) {
      await dbClient.update(
        'episode_state',
        updateMap,
        where: 'episode_id = ?',
        whereArgs: [episodeId],
      );
    }
  }

  Future<void> deleteEpisodeState(String episodeId) async {
    final dbClient = await db;
    await dbClient.delete(
      'episode_state',
      where: 'episode_id = ?',
      whereArgs: [episodeId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllStates() async {
    final dbClient = await db;
    return await dbClient.query('episode_state');
  }
} 