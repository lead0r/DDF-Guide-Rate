import 'package:flutter/material.dart';
import 'episode.dart';

class EpisodeDetailPage extends StatelessWidget {
  final Episode episode;

  EpisodeDetailPage({required this.episode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(episode.title)),
      body: Center(
        child: Text(
          'Details for ${episode.title} with rating: ${episode.rating} stars',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
