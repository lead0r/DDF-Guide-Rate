class Episode {
  final String id;
  final String title;
  final String description;
  final String image;
  final int numberEuropa;
  final String author;
  final List<dynamic> roles;
  int rating;
  bool listened;

  Episode({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.numberEuropa,
    required this.author,
    required this.roles,
    this.rating = 0,
    this.listened = false,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['Id'] ?? '',
      title: json['Title'] ?? '',
      description: json['Description'] ?? '',
      image: json['CoverUrl'] ?? '',
      numberEuropa: json['NumberEuropa'] ?? 0,
      author: json['Author'] ?? '',
      roles: json['Roles'] ?? [],
    );
  }
}