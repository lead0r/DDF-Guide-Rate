import 'package:flutter/material.dart';
import 'main.dart';
import 'episode.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

    // Fortschritt über Zeit (Monat/Jahr)
    Map<String, int> listenedPerMonth = {};
    for (var ep in episodes.where((e) => e.listened)) {
      if (ep.veroeffentlichungsdatum != null && ep.veroeffentlichungsdatum!.length >= 7) {
        final ym = ep.veroeffentlichungsdatum!.substring(0, 7); // yyyy-MM
        listenedPerMonth[ym] = (listenedPerMonth[ym] ?? 0) + 1;
      }
    }

    // Top 10 Lieblingsepisoden
    List<Episode> top10 = List<Episode>.from(ratedEpisodes)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    if (top10.length > 10) top10 = top10.sublist(0, 10);

    statistics = {
      'totalEpisodes': totalEpisodes,
      'listenedEpisodes': listenedEpisodes,
      'listenedPercentage': listenedPercentage.toStringAsFixed(1),
      'averageRating': averageRating.toStringAsFixed(1),
      'authorCounts': authorCounts,
      'yearCounts': yearCounts,
      'ratingDistribution': ratingDistribution,
      'listenedPerMonth': listenedPerMonth,
      'top10': top10,
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
            // Fortschritt pro Serie (rot/grüne Balken)
            buildProgressTimeline(
              widget.episodes.where((e) => e.serieTyp == 'Serie').toList(),
              '???'
            ),
            buildProgressTimeline(
              widget.episodes.where((e) => e.serieTyp == 'Kids').toList(),
              'Kids'
            ),
            buildProgressTimeline(
              widget.episodes.where((e) => e.serieTyp == 'DR3i').toList(),
              'DR3i'
            ),
            buildProgressTimeline(
              widget.episodes.where((e) => e.serieTyp == 'Spezial').toList(),
              'Spezial'
            ),
            buildProgressTimeline(
              widget.episodes.where((e) => e.serieTyp == 'Kurzgeschichte').toList(),
              'Kurzgeschichten'
            ),
            SizedBox(height: 24),
            _buildRatingDistributionSection(),
            SizedBox(height: 24),
            _buildTop10Section(),
            SizedBox(height: 24),
            _buildProgressChartSection(),
            SizedBox(height: 24),
            _buildYearBarChartSection(), // Veröffentlichungen pro Jahr
            SizedBox(height: 24),
            _buildAuthorBarChartSection(),
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

  Widget _buildProgressChartSection() {
    final Map<String, int> listenedPerMonth = Map<String, int>.from(statistics['listenedPerMonth'] as Map);
    final sortedKeys = listenedPerMonth.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fortschritt über Zeit', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < sortedKeys.length; i++)
                          FlSpot(i.toDouble(), listenedPerMonth[sortedKeys[i]]!.toDouble()),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= sortedKeys.length) return Container();
                          final label = sortedKeys[idx].replaceAll('-', '/');
                          return Text(label, style: TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTop10Section() {
    final List<Episode> top10 = List<Episode>.from(statistics['top10'] as List);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top 10 Lieblingsepisoden', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: top10.map((ep) => ListTile(
                leading: ep.coverUrl != null && ep.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ep.coverUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.broken_image),
                      )
                    : Icon(Icons.album),
                title: Text('${ep.nummer} / ${ep.titel}'),
                subtitle: Row(
                  children: List.generate(5, (i) => Icon(
                    ep.rating > i ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  )),
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorBarChartSection() {
    final Map<String, int> authorCounts = Map<String, int>.from(statistics['authorCounts'] as Map);
    final sorted = authorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top-Autoren', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    for (int i = 0; i < top.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: top[i].value.toDouble(),
                            color: Colors.blue,
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= top.length) return Container();
                          // Zeige nur jeden 2. Autor
                          if (idx % 2 != 0) return Container();
                          return Transform.rotate(
                            angle: -0.7, // ca. 40°
                            child: Tooltip(
                              message: top[idx].key,
                              child: Text(
                                top[idx].key.length > 8 ? top[idx].key.substring(0, 8) + '…' : top[idx].key,
                                style: TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearBarChartSection() {
    final Map<String, int> yearCounts = Map<String, int>.from(statistics['yearCounts'] as Map);
    final sorted = yearCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Veröffentlichungen pro Jahr', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    for (int i = 0; i < sorted.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: sorted[i].value.toDouble(),
                            color: Colors.green,
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= sorted.length) return Container();
                          // Zeige nur jedes 2. oder 3. Jahr, kleiner und gedreht
                          if (idx % 3 != 0) return Container();
                          return Transform.rotate(
                            angle: -0.7,
                            child: Text(
                              sorted[idx].key,
                              style: TextStyle(fontSize: 9),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
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

  Widget buildProgressTimeline(List<Episode> episodes, String title) {
    final sorted = List<Episode>.from(episodes)
      ..sort((a, b) => (a.veroeffentlichungsdatum ?? '').compareTo(b.veroeffentlichungsdatum ?? ''));
    final total = sorted.length;
    final listened = sorted.where((e) => e.listened).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title: $listened/$total (${total > 0 ? ((listened / total) * 100).toStringAsFixed(1) : '0'}%)', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(
          height: 24,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sorted.length,
            itemBuilder: (context, i) {
              final e = sorted[i];
              return Container(
                width: 4,
                height: 20,
                margin: EdgeInsets.symmetric(horizontal: 0.5),
                color: e.listened ? Colors.green : Colors.red,
              );
            },
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}