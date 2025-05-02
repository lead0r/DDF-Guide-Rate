import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'episode.dart';
import 'episode_detail_page.dart';

class EpisodeListPage extends StatefulWidget {
  @override
  _EpisodeListPageState createState() => _EpisodeListPageState();
}

class _EpisodeListPageState extends State<EpisodeListPage> {
  List<Episode> episodes = [
    Episode(id: '1', title: 'Episode 1'),
    Episode(id: '2', title: 'Episode 2'),
    Episode(id: '3', title: 'Episode 3'),
  ];

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final ratingsJson = prefs.getString('episode_ratings');
    if (ratingsJson != null) {
      final Map<String, dynamic> ratingsMap = json.decode(ratingsJson);
      setState(() {
        episodes = episodes.map((ep) {
          final rating = ratingsMap[ep.id] ?? 0;
          return Episode(id: ep.id, title: ep.title, rating: rating);
        }).toList();
      });
    }
  }

  Future<void> _saveRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final ratingsMap = {
      for (var ep in episodes) ep.id: ep.rating,
    };
    await prefs.setString('episode_ratings', json.encode(ratingsMap));
  }

  void setRating(String id, int rating) {
    setState(() {
      episodes.firstWhere((ep) => ep.id == id).rating = rating;
    });
    _saveRatings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DdfGuide')),
      body: ListView(
        children: episodes.map((ep) {
          return ListTile(
            title: Text(ep.title),
            subtitle: Row(
              children: List.generate(5, (index) {
                int starIndex = index + 1;
                return IconButton(
                  icon: Icon(
                    ep.rating >= starIndex ? Icons.star : Icons.star_border,
                  ),
                  color: Colors.amber,
                  onPressed: () => setRating(ep.id, starIndex),
                );
              }),
            ),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EpisodeDetailPage(episode: ep),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
