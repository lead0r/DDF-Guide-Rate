import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class EpisodeCacheService {
  static Future<File> _getCacheFile(String type) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/episodes_cache_$type.json');
  }

  static Future<void> saveEpisodesToCache(String type, dynamic data) async {
    try {
      final file = await _getCacheFile(type);
      await file.writeAsString(json.encode(data));
    } catch (e) {
      print('[ERROR] Fehler beim Speichern des Caches für $type: $e');
    }
  }

  static Future<dynamic> loadEpisodesFromCache(String type) async {
    try {
      final file = await _getCacheFile(type);
      if (await file.exists()) {
        final content = await file.readAsString();
        return json.decode(content);
      }
    } catch (e) {
      print('[ERROR] Fehler beim Laden des Caches für $type: $e');
    }
    return null;
  }
}
