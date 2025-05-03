import 'dart:convert';
import 'package:http/http.dart' as http;
import 'episode.dart';

class EpisodeDataService {
  static const Map<String, String> urls = {
    'Serie': 'https://dreimetadaten.de/data/Serie.json',
    'Spezial': 'https://dreimetadaten.de/data/Spezial.json',
    'Kurzgeschichte': 'https://dreimetadaten.de/data/Kurzgeschichten.json',
    'Kids': 'https://dreimetadaten.de/data/Kids.json',
    'DR3i': 'https://dreimetadaten.de/data/DiE_DR3i.json',
  };

  Future<List<Episode>> fetchEpisodes({required String type}) async {
    final url = urls[type];
    if (url == null) return [];
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return [];
    final data = json.decode(utf8.decode(response.bodyBytes));
    final List episodesJson = data['serie'] ?? data['spezial'] ?? data['kurzgeschichten'] ?? data['kids'] ?? data['dr3i'] ?? [];
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