import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'episode.dart';
import 'main.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EpisodeDetailPage extends StatefulWidget {
  final Episode episode;
  final VoidCallback onUpdate;

  EpisodeDetailPage({required this.episode, required this.onUpdate});

  @override
  _EpisodeDetailPageState createState() => _EpisodeDetailPageState();
}

class _EpisodeDetailPageState extends State<EpisodeDetailPage> {
  late Episode episode;
  bool showAllRoles = false;
  TextEditingController? _noteController;
  String? _noteInitialValue;

  @override
  void initState() {
    super.initState();
    episode = widget.episode;
    _loadNote();
  }

  Future<void> _loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    final note = prefs.getString('note_${episode.id}') ?? '';
    setState(() {
      _noteInitialValue = note;
      _noteController = TextEditingController(text: note);
    });
  }

  Future<void> _saveNote(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('note_${episode.id}', value);
  }

  @override
  void dispose() {
    _noteController?.dispose();
    super.dispose();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final ratingsJson = prefs.getString('episode_ratings');
    final listenedJson = prefs.getString('episode_listened');

    final Map<String, dynamic> ratingsMap =
    ratingsJson != null ? json.decode(ratingsJson) : {};
    final Map<String, dynamic> listenedMap =
    listenedJson != null ? json.decode(listenedJson) : {};

    ratingsMap[episode.id] = episode.rating;
    listenedMap[episode.id] = episode.listened;

    await prefs.setString('episode_ratings', json.encode(ratingsMap));
    await prefs.setString('episode_listened', json.encode(listenedMap));

    widget.onUpdate();
  }

  void setRating(int rating) {
    setState(() {
      // Wenn der Benutzer auf den bereits ausgewählten Stern klickt, setze die Bewertung zurück
      if (episode.rating == rating) {
        episode.rating = 0;
      } else {
        episode.rating = rating;
      }
    });
    _saveState();
  }

  void toggleListened() {
    setState(() {
      episode.listened = !episode.listened;
    });
    _saveState();
  }

  void _openSpotify() async {
    // Zuerst versuchen wir, die Spotify-App zu öffnen
    final spotifyUri = Uri.parse('spotify:album:${episode.spotifyAlbumId}');

    // Als Fallback haben wir die Web-URL
    final webUrl = Uri.parse('https://open.spotify.com/album/${episode.spotifyAlbumId}');

    try {
      // Versuche zuerst die App zu öffnen
      final appLaunched = await launchUrl(
        spotifyUri,
        mode: LaunchMode.externalApplication,
      );

      // Wenn das nicht klappt, öffne im Browser
      if (!appLaunched) {
        await launchUrl(
          webUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Wenn ein Fehler auftritt, zeige eine Fehlermeldung
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Spotify kann nicht geöffnet werden: ${e.toString()}')),
      );
    }
  }

  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return '${parsedDate.day.toString().padLeft(2, '0')}.${parsedDate.month.toString().padLeft(2, '0')}.${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    final rolesToShow = showAllRoles ? episode.roles : episode.roles.take(3).toList();
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('??? Guide'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
            ),
            onPressed: () => appState?.toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'episode_${episode.id}',
              child: Container(
                color: Colors.black,
                width: double.infinity,
                padding: EdgeInsets.all(8),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: CachedNetworkImage(
                    imageUrl: episode.image,
                    fit: BoxFit.contain,
                    fadeInDuration: Duration(milliseconds: 100),
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 100),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '${episode.numberEuropa} / ${episode.title}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16),
                SizedBox(width: 4),
                Text('Veröffentlichung: ${formatDate(episode.releaseDate)}'),
              ],
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beschreibung',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(episode.description),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16),
                        SizedBox(width: 4),
                        Text('Autor: ${episode.author}'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sprecher:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...rolesToShow.map((role) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text('${role['Character']}: ${role['Speaker']}'),
                        )),
                    if (episode.roles.length > 3)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showAllRoles = !showAllRoles;
                          });
                        },
                        child: Text(showAllRoles ? 'Weniger anzeigen' : 'Alle anzeigen'),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bewertung',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        int starIndex = index + 1;
                        return IconButton(
                          icon: Icon(
                            episode.rating >= starIndex
                                ? Icons.star
                                : Icons.star_border,
                          ),
                          color: Colors.amber,
                          onPressed: () => setRating(starIndex),
                        );
                      }),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Gehört: '),
                        Switch(
                          value: episode.listened,
                          onChanged: (value) => toggleListened(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (episode.spotifyAlbumId.isNotEmpty) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _openSpotify,
                child: Text('In Spotify öffnen'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
            if (_noteController != null) ...[
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notiz', style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        minLines: 2,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Deine Notiz zu dieser Folge ...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _saveNote(value),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}