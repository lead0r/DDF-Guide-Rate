import 'package:flutter/material.dart';
import 'main.dart';
import 'episode.dart';

class StatisticsPage extends StatefulWidget {
  final List<Episode> episodes;

  StatisticsPage({required this.episodes});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Map<String, dynamic> statistics;

  @override
  void initState() {
    super.initState();
    _calculateStatistics();
  }

  void _calculateStatistics() {
    final episodes = widget.episodes;

    // Allgemeine Statistiken
    int totalEpisodes = episodes.length;
    int listenedEpisodes = episodes.where((ep) => ep.listened).length;
    double listenedPercentage = totalEpisodes > 0
        ? (listenedEpisodes / totalEpisodes * 100)
        : 0.0;

    // Bewertungsstatistiken
    final ratedEpisodes = episodes.where((ep) => ep.rating > 0).toList();
    double averageRating = ratedEpisodes.isNotEmpty
        ? ratedEpisodes.fold<int>(0, (sum, ep) => sum + ep.rating) / ratedEpisodes.length
        : 0.0;

    // Nach Autor
    Map<String, int> authorCounts = {};
    for (var ep in episodes) {
      authorCounts[ep.autor] = (authorCounts[ep.autor] ?? 0) + 1;
    }

    // Nach Jahr
    Map<String, int> yearCounts = {};
    for (var ep in episodes) {
      final year = (ep.veroeffentlichungsdatum != null && ep.veroeffentlichungsdatum!.length >= 4)
          ? ep.veroeffentlichungsdatum!.substring(0, 4)
          : 'Unbekannt';
      yearCounts[year] = (yearCounts[year] ?? 0) + 1;
    }

    // Bewertungsverteilung
    Map<int, int> ratingDistribution = {};
    for (int i = 0; i <= 5; i++) {
      ratingDistribution[i] = episodes.where((ep) => ep.rating == i).length;
    }

    statistics = {
      'totalEpisodes': totalEpisodes,
      'listenedEpisodes': listenedEpisodes,
      'listenedPercentage': listenedPercentage.toStringAsFixed(1),
      'averageRating': averageRating.toStringAsFixed(1),
      'authorCounts': authorCounts,
      'yearCounts': yearCounts,
      'ratingDistribution': ratingDistribution,
    };
  }

  // Ändere die body-Methode wie folgt
  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiken'),
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
            _buildOverviewSection(),
            SizedBox(height: 24),
            _buildAuthorSection(),
            SizedBox(height: 24),
            _buildYearSection(),
            SizedBox(height: 24),
            _buildRatingDistributionSection(),
            // Zusätzlicher Leerraum am Ende der Seite
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Überblick',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatRow('Folgen insgesamt:', '${statistics['totalEpisodes']}'),
                SizedBox(height: 8),
                _buildStatRow('Gehörte Folgen:', '${statistics['listenedEpisodes']}'),
                SizedBox(height: 8),
                _buildStatRow('Fortschritt:', '${statistics['listenedPercentage']}%'),
                SizedBox(height: 8),
                _buildStatRow('Durchschnittliche Bewertung:', '${statistics['averageRating']} ⭐'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAuthorSection() {
    final Map<String, int> authorCounts = Map<String, int>.from(statistics['authorCounts'] as Map);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nach Autor',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: authorCounts.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${entry.value} Folgen',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearSection() {
    final Map<String, int> yearCounts = Map<String, int>.from(statistics['yearCounts'] as Map);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nach Jahr',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: yearCounts.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${entry.value} Folgen',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDistributionSection() {
    final Map<int, int> ratingDistribution = Map<int, int>.from(statistics['ratingDistribution'] as Map);
    final maxCount = ratingDistribution.values.fold<int>(1, (max, count) => count > max ? count : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bewertungsverteilung',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 5; i >= 1; i--)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Row(
                            children: List.generate(
                              i,
                                  (index) => Icon(Icons.star, color: Colors.amber, size: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: maxCount > 0
                                  ? (ratingDistribution[i] ?? 0) / maxCount
                                  : 0,
                              minHeight: 16,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${ratingDistribution[i] ?? 0}',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text('Keine'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxCount > 0
                              ? (ratingDistribution[0] ?? 0) / maxCount
                              : 0,
                          minHeight: 16,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${ratingDistribution[0] ?? 0}',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}