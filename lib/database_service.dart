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
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE episode_state (
            episode_id TEXT PRIMARY KEY,
            note TEXT,
            rating INTEGER,
            listened INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE episode_state_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            episode_id TEXT,
            note TEXT,
            rating INTEGER,
            listened INTEGER,
            timestamp INTEGER
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS episode_state_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              episode_id TEXT,
              note TEXT,
              rating INTEGER,
              listened INTEGER,
              timestamp INTEGER
            )
          ''');
        }
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
    await _logHistory(episodeId);
  }

  Future<void> setRating(String episodeId, int rating) async {
    final dbClient = await db;
    await dbClient.insert(
      'episode_state',
      {'episode_id': episodeId, 'rating': rating},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _logHistory(episodeId);
  }

  Future<void> setListened(String episodeId, bool listened) async {
    final dbClient = await db;
    await dbClient.insert(
      'episode_state',
      {'episode_id': episodeId, 'listened': listened ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _logHistory(episodeId);
  }

  Future<void> updateEpisodeState(String episodeId, {String? note, int? rating, bool? listened}) async {
    final dbClient = await db;
    // Hole bisherigen State (falls vorhanden)
    final prev = await getEpisodeState(episodeId);
    final updateMap = <String, Object?>{
      'episode_id': episodeId,
      'note': note ?? prev?['note'] ?? '',
      'rating': rating != null ? rating : (prev?['rating'] ?? 0),
      'listened': listened != null
          ? (listened ? 1 : 0)
          : prev?['listened'] ?? 0,
    };
    // Upsert: Insert mit ConflictAlgorithm.replace
    await dbClient.insert(
      'episode_state',
      updateMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _logHistory(episodeId);
  }

  Future<void> _logHistory(String episodeId) async {
    final dbClient = await db;
    final state = await getEpisodeState(episodeId);
    if (state != null) {
      await dbClient.insert('episode_state_history', {
        'episode_id': episodeId,
        'note': state['note'],
        'rating': state['rating'],
        'listened': state['listened'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<void> deleteEpisodeState(String episodeId) async {
    final dbClient = await db;
    await dbClient.delete(
      'episode_state',
      where: 'episode_id = ?',
      whereArgs: [episodeId],
    );
    // Optional: History nicht löschen
  }

  Future<List<Map<String, dynamic>>> getAllStates() async {
    final dbClient = await db;
    final result = await dbClient.query('episode_state');
    return result;
  }

  Future<List<Map<String, dynamic>>> getHistory(String episodeId) async {
    final dbClient = await db;
    return await dbClient.query(
      'episode_state_history',
      where: 'episode_id = ?',
      whereArgs: [episodeId],
      orderBy: 'timestamp DESC',
    );
  }

  // Exportiert beide Tabellen als JSON-Map
  Future<Map<String, dynamic>> exportAllToJson() async {
    final dbClient = await db;
    final states = await dbClient.query('episode_state');
    final history = await dbClient.query('episode_state_history');
    return {
      'episode_state': states,
      'episode_state_history': history,
    };
  }

  // Importiert beide Tabellen aus einer JSON-Map
  Future<void> importAllFromJson(Map<String, dynamic> data) async {
    final dbClient = await db;
    final batch = dbClient.batch();
    // Leere Tabellen
    batch.delete('episode_state');
    batch.delete('episode_state_history');
    // Füge States ein
    if (data['episode_state'] is List) {
      for (final row in data['episode_state']) {
        batch.insert('episode_state', Map<String, Object?>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    // Füge History ein
    if (data['episode_state_history'] is List) {
      for (final row in data['episode_state_history']) {
        batch.insert('episode_state_history', Map<String, Object?>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }

  // Export/Import folgt im nächsten Schritt

  Future<void> removeNullSpezialStates() async {
    final dbClient = await db;
    await dbClient.delete(
      'episode_state',
      where: 'episode_id = ?',
      whereArgs: ['spezial_null'],
    );
  }

  Future<void> removeOrphanedStates(List<String> validEpisodeIds) async {
    if (validEpisodeIds.isEmpty) return;
    final dbClient = await db;
    await dbClient.delete(
      'episode_state',
      where: 'episode_id NOT IN (${List.filled(validEpisodeIds.length, '?').join(',')})',
      whereArgs: validEpisodeIds,
    );
  }
} 