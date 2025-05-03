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
      coverUrl: json['links']?['cover'],
      serieTyp: 'Serie',
      sprechrollen: json['sprechrollen'],
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
      coverUrl: json['links']?['cover'],
      serieTyp: 'Spezial',
      sprechrollen: json['sprechrollen'],
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
      coverUrl: json['links']?['cover'],
      serieTyp: 'Kurzgeschichte',
      sprechrollen: json['sprechrollen'],
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
      coverUrl: json['links']?['cover'],
      serieTyp: 'Kids',
      sprechrollen: json['sprechrollen'],
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
      coverUrl: json['links']?['cover'],
      serieTyp: 'DR3i',
      sprechrollen: json['sprechrollen'],
    );
  }
}