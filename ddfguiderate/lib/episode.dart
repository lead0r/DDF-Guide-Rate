import 'dart:convert';

class Episode {
  final String id;
  final int nummer;
  final String titel;
  final String autor;
  final String beschreibung;
  final String? gesamtbeschreibung;
  final String? hoerspielskriptautor;
  final String? veroeffentlichungsdatum;
  final String? coverUrl;
  final String? serieTyp; // Serie, Spezial, Kurzgeschichte, Kids, DR3i
  final List<dynamic>? sprechrollen;
  int rating;
  bool listened;
  String? note;
  final String? spotifyUrl;
  final Map<String, String> links;

  Episode({
    required this.id,
    required this.nummer,
    required this.titel,
    required this.autor,
    required this.beschreibung,
    this.gesamtbeschreibung,
    this.hoerspielskriptautor,
    this.veroeffentlichungsdatum,
    this.coverUrl,
    this.serieTyp,
    this.sprechrollen,
    this.rating = 0,
    this.listened = false,
    this.note,
    this.spotifyUrl,
    Map<String, String>? links,
  }) : links = links ?? const {};

  static Map<String, String> _parseLinks(Map<String, dynamic>? jsonLinks) {
    if (jsonLinks == null) return {};
    return jsonLinks.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  factory Episode.fromSerieJson(Map<String, dynamic> json) {
    final id = 'serie_${json['nummer']}';
    print('[DEBUG] Erzeuge Episode: $id');
    return Episode(
      id: id,
      nummer: json['nummer'] ?? 0,
      titel: json['titel'] ?? '',
      autor: json['autor'] ?? '',
      beschreibung: json['beschreibung'] ?? '',
      gesamtbeschreibung: json['gesamtbeschreibung'],
      hoerspielskriptautor: json['hörspielskriptautor'],
      veroeffentlichungsdatum: json['veröffentlichungsdatum'],
      coverUrl: json['links']?['cover'] ?? json['coverUrl'],
      serieTyp: 'Serie',
      sprechrollen: json['sprechrollen'],
      spotifyUrl: json['spotify'],
      links: _parseLinks(json['links']),
    );
  }

  factory Episode.fromSpezialJson(Map<String, dynamic> json) {
    return Episode(
      id: 'spezial_${json['nummer']}',
      nummer: json['nummer'] ?? 0,
      titel: json['titel'] ?? '',
      autor: json['autor'] ?? '',
      beschreibung: json['beschreibung'] ?? '',
      gesamtbeschreibung: json['gesamtbeschreibung'],
      hoerspielskriptautor: json['hörspielskriptautor'],
      veroeffentlichungsdatum: json['veröffentlichungsdatum'],
      coverUrl: json['links']?['cover'] ?? json['coverUrl'],
      serieTyp: 'Spezial',
      sprechrollen: json['sprechrollen'],
      spotifyUrl: json['spotify'],
      links: _parseLinks(json['links']),
    );
  }

  factory Episode.fromKurzgeschichteJson(Map<String, dynamic> json) {
    return Episode(
      id: 'kurz_${json['nummer']}',
      nummer: json['nummer'] ?? 0,
      titel: json['titel'] ?? '',
      autor: json['autor'] ?? '',
      beschreibung: json['beschreibung'] ?? '',
      gesamtbeschreibung: json['gesamtbeschreibung'],
      hoerspielskriptautor: json['hörspielskriptautor'],
      veroeffentlichungsdatum: json['veröffentlichungsdatum'],
      coverUrl: json['links']?['cover'] ?? json['coverUrl'],
      serieTyp: 'Kurzgeschichte',
      sprechrollen: json['sprechrollen'],
      spotifyUrl: json['spotify'],
      links: _parseLinks(json['links']),
    );
  }

  factory Episode.fromKidsJson(Map<String, dynamic> json) {
    return Episode(
      id: 'kids_${json['nummer']}',
      nummer: json['nummer'] ?? 0,
      titel: json['titel'] ?? '',
      autor: json['autor'] ?? '',
      beschreibung: json['beschreibung'] ?? '',
      gesamtbeschreibung: json['gesamtbeschreibung'],
      hoerspielskriptautor: json['hörspielskriptautor'],
      veroeffentlichungsdatum: json['veröffentlichungsdatum'],
      coverUrl: json['links']?['cover'] ?? json['links']?['cover_itunes'] ?? json['coverUrl'],
      serieTyp: 'Kids',
      sprechrollen: json['sprechrollen'],
      spotifyUrl: json['spotify'],
      links: _parseLinks(json['links']),
    );
  }

  factory Episode.fromDr3iJson(Map<String, dynamic> json) {
    return Episode(
      id: 'dr3i_${json['nummer']}',
      nummer: json['nummer'] ?? 0,
      titel: json['titel'] ?? '',
      autor: json['autor'] ?? '',
      beschreibung: json['beschreibung'] ?? '',
      gesamtbeschreibung: json['gesamtbeschreibung'],
      hoerspielskriptautor: json['hörspielskriptautor'],
      veroeffentlichungsdatum: json['veröffentlichungsdatum'],
      coverUrl: json['links']?['cover'] ?? json['coverUrl'],
      serieTyp: 'DR3i',
      sprechrollen: json['sprechrollen'],
      spotifyUrl: json['spotify'],
      links: _parseLinks(json['links']),
    );
  }

  bool get isFutureRelease {
    if (veroeffentlichungsdatum == null) return false;
    try {
      final releaseDate = DateTime.parse(veroeffentlichungsdatum!);
      return releaseDate.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nummer': nummer,
    'titel': titel,
    'autor': autor,
    'beschreibung': beschreibung,
    'gesamtbeschreibung': gesamtbeschreibung,
    'hoerspielskriptautor': hoerspielskriptautor,
    'veroeffentlichungsdatum': veroeffentlichungsdatum,
    'coverUrl': coverUrl,
    'serieTyp': serieTyp,
    'sprechrollen': sprechrollen,
    'rating': rating,
    'listened': listened,
    'note': note,
    'spotifyUrl': spotifyUrl,
    'links': links,
  };

  static Episode fromJson(Map<String, dynamic> json) => Episode(
    id: json['id'],
    nummer: json['nummer'],
    titel: json['titel'],
    autor: json['autor'],
    beschreibung: json['beschreibung'],
    gesamtbeschreibung: json['gesamtbeschreibung'],
    hoerspielskriptautor: json['hoerspielskriptautor'],
    veroeffentlichungsdatum: json['veroeffentlichungsdatum'],
    coverUrl: json['coverUrl'],
    serieTyp: json['serieTyp'],
    sprechrollen: json['sprechrollen'],
    rating: json['rating'] ?? 0,
    listened: json['listened'] ?? false,
    note: json['note'],
    spotifyUrl: json['spotifyUrl'],
    links: (json['links'] as Map?)?.cast<String, String>(),
  );
}