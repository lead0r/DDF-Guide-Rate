import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class SpotifyIdResolver {
  static SpotifyIdResolver? _instance;
  final Map<String, String> _keyToSpotifyId = {};
  bool _initialized = false;

  SpotifyIdResolver._();

  static SpotifyIdResolver get instance => _instance ??= SpotifyIdResolver._();

  Future<void> _init() async {
    if (_initialized) return;
    final jsonStr = await rootBundle.loadString('assets/data/dtos.json');
    final List<dynamic> data = json.decode(jsonStr);
    for (final entry in data) {
      final interpreter = (entry['Interpreter'] ?? '').toString().trim();
      final nummer = entry['NumberEuropa']?.toString() ?? '';
      final title = (entry['Title'] ?? '').toString().trim();
      final spotifyId = (entry['SpotifyAlbumId'] ?? '').toString().trim();
      if (spotifyId.isNotEmpty) {
        final key = _makeKey(interpreter, nummer, title);
        _keyToSpotifyId[key] = spotifyId;
      }
    }
    _initialized = true;
  }

  String _makeKey(String interpreter, String nummer, String title) {
    return '$interpreter|$nummer|$title'.toLowerCase();
  }

  Future<String?> getSpotifyId({required String interpreter, required int nummer, required String titel}) async {
    await _init();
    final key = _makeKey(interpreter, nummer.toString(), titel);
    return _keyToSpotifyId[key];
  }
} 