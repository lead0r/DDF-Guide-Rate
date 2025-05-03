import 'package:flutter/material.dart';
import 'episode.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TimelinePage extends StatelessWidget {
  final List<Episode> episodes;
  TimelinePage({required this.episodes});

  @override
  Widget build(BuildContext context) {
    // Nach Jahr gruppieren
    final sorted = List<Episode>.from(episodes)
      ..sort((a, b) => (a.veroeffentlichungsdatum ?? '').compareTo(b.veroeffentlichungsdatum ?? ''));
    final Map<String, List<Episode>> grouped = {};
    for (var ep in sorted) {
      final year = (ep.veroeffentlichungsdatum != null && ep.veroeffentlichungsdatum!.length >= 4)
          ? ep.veroeffentlichungsdatum!.substring(0, 4)
          : 'Unbekannt';
      grouped.putIfAbsent(year, () => []).add(ep);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Zeitleiste')),
      body: ListView(
        children: grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Text(entry.key, style: Theme.of(context).textTheme.titleLarge),
              ),
              ...entry.value.map((ep) => _buildTimelineTile(context, ep)).toList(),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineTile(BuildContext context, Episode ep) {
    return ListTile(
      leading: ep.coverUrl != null && ep.coverUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: ep.coverUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.broken_image),
              ),
            )
          : Icon(Icons.album, size: 48),
      title: Text('${ep.nummer} / ${ep.titel}'),
      subtitle: Row(
        children: [
          if (ep.veroeffentlichungsdatum != null)
            Text(ep.veroeffentlichungsdatum!, style: TextStyle(fontSize: 12)),
          SizedBox(width: 8),
          Row(
            children: List.generate(5, (i) => Icon(
              ep.rating > i ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 16,
            )),
          ),
        ],
      ),
      onTap: () {
        // Optional: Navigiere zur Detailseite
      },
    );
  }
} 