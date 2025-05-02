class Episode {
  final String id;
  final String title;
  final int numberEuropa;
  final String releaseDate;
  final String image;
  final String interpreter;
  final String spotifyAlbumId;
  final String amazonAlbumId;
  final String author;
  final String description;
  final List<dynamic> roles;
  int rating;
  bool listened;

  Episode({
    required this.id,
    required this.title,
    required this.numberEuropa,
    required this.releaseDate,
    required this.image,
    required this.interpreter,
    required this.spotifyAlbumId,
    required this.amazonAlbumId,
    required this.author,
    required this.description,
    required this.roles,
    this.rating = 0,
    this.listened = false,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['Id'] ?? '',
      title: json['Title'] ?? '',
      numberEuropa: json['NumberEuropa'] ?? 0,
      releaseDate: json['ReleaseDate'] ?? '',
      image: json['CoverUrl'] ?? '',
      interpreter: json['Interpreter'] ?? '',
      spotifyAlbumId: json['SpotifyAlbumId'] ?? '',
      amazonAlbumId: json['AmazonAlbumId'] ?? '',
      author: json['Author'] ?? '',
      description: json['Description'] ?? '',
      roles: json['Roles'] ?? [],
    );
  }
}