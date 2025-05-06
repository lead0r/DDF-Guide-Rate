import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'episode.dart';
import 'episode_cache_service.dart';

// --- NEU: Top-Level-Funktion für compute ---
List<Episode> parseEpisodesIsolate(Map<String, dynamic> args) {
  final String type = args['type'];
  final dynamic data = args['data'];
  List episodesJson = [];
  if (type == 'DR3i') {
    episodesJson = data['die_dr3i'] ?? [];
  } else if (type == 'Kids') {
    episodesJson = data['kids'] ?? [];
  } else {
    episodesJson = data['serie'] ?? data['spezial'] ?? data['kurzgeschichten'] ?? [];
  }
  return episodesJson.map<Episode>((json) {
    switch (type) {
      case 'Serie':
        return Episode.fromSerieJson(json);
      case 'Spezial':
        return Episode.fromSpezialJson(json);
      case 'Kurzgeschichte':
        return Episode.fromKurzgeschichteJson(json);
      case 'Kids':
        return Episode.fromKidsJson(json);
      case 'DR3i':
        return Episode.fromDr3iJson(json);
      default:
        throw Exception('Unbekannter Episodentyp: $type');
    }
  }).toList();
}

class EpisodeDataService {
  static const Map<String, String> urls = {
    'Serie': 'https://dreimetadaten.de/data/Serie.json',
    'Spezial': 'https://dreimetadaten.de/data/Spezial.json',
    'Kurzgeschichte': 'https://dreimetadaten.de/data/Kurzgeschichten.json',
    'Kids': 'https://dreimetadaten.de/data/Kids.json',
    'DR3i': 'https://dreimetadaten.de/data/DiE_DR3i.json',
  };

  Future<List<Episode>> fetchEpisodes({required String type, bool forceNetwork = false}) async {
    // 1. Erst aus Cache laden (sofortige Anzeige), außer forceNetwork=true
    if (!forceNetwork) {
      final cachedData = await EpisodeCacheService.loadEpisodesFromCache(type);
      if (cachedData != null) {
        try {
          // NEU: Mapping in Isolate
          return await compute(parseEpisodesIsolate, {'type': type, 'data': cachedData});
        } catch (e) {
          print('[ERROR] Fehler beim Parsen des Caches für $type: $e');
        }
      }
    }

    // 2. Dann aus dem Netz laden (und Cache aktualisieren)
    final url = urls[type];
    if (url == null) return [];
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
      final data = json.decode(utf8.decode(response.bodyBytes));
      await EpisodeCacheService.saveEpisodesToCache(type, data);
      // NEU: Mapping in Isolate
      return await compute(parseEpisodesIsolate, {'type': type, 'data': data});
    } catch (e) {
      print('[ERROR] Fehler beim Laden aus dem Netz für $type: $e');
      // Fallback: Versuche Cache zu laden
      final cachedData = await EpisodeCacheService.loadEpisodesFromCache(type);
      if (cachedData != null) {
        try {
          // NEU: Mapping in Isolate
          return await compute(parseEpisodesIsolate, {'type': type, 'data': cachedData});
        } catch (e) {
          print('[ERROR] Fehler beim Parsen des Caches (Fallback) für $type: $e');
        }
      }
      // Wenn alles fehlschlägt, gib leere Liste zurück
      return [];
    }
  }

  Future<List<Episode>> fetchAllMainEpisodes() async {
    // Hauptserie, Spezial und Kurzgeschichten zusammenführen
    final serie = await fetchEpisodes(type: 'Serie');
    final spezial = await fetchEpisodes(type: 'Spezial');
    final kurz = await fetchEpisodes(type: 'Kurzgeschichte');
    return [...serie, ...spezial, ...kurz];
  }

  Future<List<Episode>> fetchKidsEpisodes() async {
    return await fetchEpisodes(type: 'Kids');
  }

  Future<List<Episode>> fetchDr3iEpisodes() async {
    return await fetchEpisodes(type: 'DR3i');
  }
} 