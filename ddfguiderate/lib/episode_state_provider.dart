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

    final prefs = await SharedPreferences.getInstance();
    final cachedMain = prefs.getString('mainEpisodes');
    final cachedKids = prefs.getString('kidsEpisodes');
    final cachedDr3i = prefs.getString('dr3iEpisodes');

    List<Episode> main = [];
    List<Episode> kids = [];
    List<Episode> dr3i = [];

    // 1. Zeige sofort gecachte Episoden, falls vorhanden
    if (cachedMain != null && cachedKids != null && cachedDr3i != null) {
      main = (jsonDecode(cachedMain) as List).map((e) => Episode.fromJson(e)).toList();
      kids = (jsonDecode(cachedKids) as List).map((e) => Episode.fromJson(e)).toList();
      dr3i = (jsonDecode(cachedDr3i) as List).map((e) => Episode.fromJson(e)).toList();
      _episodes = [...main, ...kids, ...dr3i];
      _loading = false;
      notifyListeners();
    }

    // 2. Lade im Hintergrund die aktuellen Daten
    final dataService = EpisodeDataService();
    final results = await Future.wait([
      dataService.fetchAllMainEpisodes(),
      dataService.fetchKidsEpisodes(),
      dataService.fetchDr3iEpisodes(),
      DatabaseService().getAllStates(),
    ]);
    main = results[0] as List<Episode>;
    kids = results[1] as List<Episode>;
    dr3i = results[2] as List<Episode>;
    final dbStates = results[3] as List<Map<String, dynamic>>;

    void applyState(List<Episode> episodes) {
      for (var ep in episodes) {
        final state = dbStates.firstWhere(
          (s) => s['episode_id'] == ep.id,
          orElse: () => {},
        );
        if (state.isNotEmpty) {
          ep.listened = (state['listened'] ?? 0) == 1;
          ep.rating = state['rating'] ?? 0;
          ep.note = state['note'] ?? '';
        }
        print('[DEBUG] applyState: ${ep.id} listened=${ep.listened}');
      }
    }
    applyState(main);
    applyState(kids);
    applyState(dr3i);

    await prefs.setString('mainEpisodes', jsonEncode(main.map((e) => e.toJson()).toList()));
    await prefs.setString('kidsEpisodes', jsonEncode(kids.map((e) => e.toJson()).toList()));
    await prefs.setString('dr3iEpisodes', jsonEncode(dr3i.map((e) => e.toJson()).toList()));

    _episodes = [...main, ...kids, ...dr3i];
    _loading = false;
    notifyListeners();
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
