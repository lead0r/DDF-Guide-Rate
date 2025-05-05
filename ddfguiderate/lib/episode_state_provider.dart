import 'package:flutter/material.dart';
import 'episode.dart';
import 'database_service.dart';
import 'episode_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EpisodeStateProvider extends ChangeNotifier {
  List<Episode> _episodes = [];
  bool _loading = false;

  List<Episode> get episodes => _episodes;
  bool get loading => _loading;

  Future<void> loadEpisodes() async {
    _loading = true;
    notifyListeners();

    final dataService = EpisodeDataService();
    final results = await Future.wait([
      dataService.fetchAllMainEpisodes(),
      dataService.fetchKidsEpisodes(),
      dataService.fetchDr3iEpisodes(),
      DatabaseService().getAllStates(),
    ]);
    List<Episode> main = results[0] as List<Episode>;
    List<Episode> kids = results[1] as List<Episode>;
    List<Episode> dr3i = results[2] as List<Episode>;
    final dbStates = results[3] as List<Map<String, dynamic>>;

    // --- Orphaned States bereinigen, bevor States angewendet werden ---
    final allEpisodeIds = [...main, ...kids, ...dr3i].map((e) => e.id).toList();
    await DatabaseService().removeOrphanedStates(allEpisodeIds);

    // Jetzt nochmal States laden, damit wirklich nur gültige States angewendet werden
    final cleanedDbStates = await DatabaseService().getAllStates();

    void applyState(List<Episode> episodes) {
      for (var ep in episodes) {
        final state = cleanedDbStates.firstWhere(
          (s) => s['episode_id'] == ep.id,
          orElse: () => {},
        );
        if (state.isNotEmpty) {
          ep.listened = (state['listened'] ?? 0) == 1;
          ep.rating = state['rating'] ?? 0;
          ep.note = state['note'] ?? '';
        }
      }
    }
    applyState(main);
    applyState(kids);
    applyState(dr3i);

    // Jetzt erst Episoden setzen und notifyListeners aufrufen!
    _episodes = [...main, ...kids, ...dr3i];
    _loading = false;
    notifyListeners();

    print('[DEBUG] Spezialfolgen-IDs:');
    for (var ep in main.where((e) => e.serieTyp == 'Spezial')) {
      print('[DEBUG] Spezialfolge: ${ep.titel} -> ${ep.id}');
    }
  }

  Future<void> updateEpisode(Episode episode, {String? note, int? rating, bool? listened}) async {
    await DatabaseService().updateEpisodeState(
      episode.id,
      note: note,
      rating: rating,
      listened: listened,
    );
    // Lade neuen State aus DB
    final state = await DatabaseService().getEpisodeState(episode.id);
    if (state != null) {
      final idx = _episodes.indexWhere((e) => e.id == episode.id);
      if (idx != -1) {
        _episodes[idx] = Episode(
          id: episode.id,
          nummer: episode.nummer,
          titel: episode.titel,
          autor: episode.autor,
          beschreibung: episode.beschreibung,
          gesamtbeschreibung: episode.gesamtbeschreibung,
          hoerspielskriptautor: episode.hoerspielskriptautor,
          veroeffentlichungsdatum: episode.veroeffentlichungsdatum,
          coverUrl: episode.coverUrl,
          serieTyp: episode.serieTyp,
          sprechrollen: episode.sprechrollen,
          rating: state['rating'] ?? 0,
          listened: (state['listened'] ?? 0) == 1,
          note: state['note'] ?? '',
          spotifyUrl: episode.spotifyUrl,
          links: episode.links,
        );
      }
    }
    notifyListeners();
  }
}
