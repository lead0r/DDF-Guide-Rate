import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'episode.dart';
import 'main.dart';

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

  @override
  void initState() {
    super.initState();
    episode = widget.episode;
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
      episode.rating = rating;
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
    final url = 'https://open.spotify.com/album/${episode.spotifyAlbumId}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Spotify kann nicht geöffnet werden')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    final rolesToShow =
    showAllRoles ? episode.roles : episode.roles.take(3).toList();

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
            Image.network(
              episode.image,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.broken_image, size: 100),
            ),
            SizedBox(height: 16),
            Text(
              '${episode.numberEuropa} / ${episode.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(episode.description),
            SizedBox(height: 16),
            Text('Autor: ${episode.author}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Sprecher:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...rolesToShow.map<Widget>((role) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child:
              Text('${role['Character']}: ${role['Speaker']}'),
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
            SizedBox(height: 16),
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
            if (episode.spotifyAlbumId.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _openSpotify,
                icon: Icon(Icons.play_arrow),
                label: Text('In Spotify öffnen'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            SizedBox(height: 32), // Abstand, damit nichts abgeschnitten wird
          ],
        ),
      ),
    );
  }
}