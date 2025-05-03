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
  });

  factory Episode.fromSerieJson(Map<String, dynamic> json) {
    return Episode(
      id: 'serie_${json['nummer']}',
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
      coverUrl: json['links']?['cover'] ?? json['cover_itunes'] ?? json['coverUrl'],
      serieTyp: 'Kids',
      sprechrollen: json['sprechrollen'],
      spotifyUrl: json['spotify'],
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
}