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

  // NEU: Rollen-Cache
  static Future<File> _getRolesCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/roles_cache.json');
  }

  static Future<void> saveRolesToCache(List<String> roles) async {
    try {
      final file = await _getRolesCacheFile();
      await file.writeAsString(json.encode(roles));
    } catch (e) {
      print('[ERROR] Fehler beim Speichern des Rollen-Caches: $e');
    }
  }

  static Future<List<String>> loadRolesFromCache() async {
    try {
      final file = await _getRolesCacheFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> roles = json.decode(content);
        return roles.cast<String>();
      }
    } catch (e) {
      print('[ERROR] Fehler beim Laden des Rollen-Caches: $e');
    }
    return [];
  }
}
