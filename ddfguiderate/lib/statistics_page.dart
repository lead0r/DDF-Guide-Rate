import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'main.dart';
import 'episode.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'episode_state_provider.dart';
import 'episode_detail_page.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Map<String, dynamic> statistics;
  final GlobalKey _sharePicKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateStatistics();
  }

  Future<void> _calculateStatistics() async {
    final episodeProvider = Provider.of<EpisodeStateProvider>(context, listen: false);
    final episodes = episodeProvider.episodes;

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

    // Fortschritt über Zeit (tatsächliches "gehört am"-Datum, gruppiert nach Monat)
    Map<String, int> listenedPerMonth = {};
    final db = await DatabaseService().db;
    final history = await db.query('episode_state_history', where: 'listened = 1');
    for (var entry in history) {
      final ts = entry['timestamp'];
      if (ts != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(ts is int ? ts : int.parse(ts.toString()));
        final ym = "${date.year}-${date.month.toString().padLeft(2, '0')}";
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
    setState(() {});
  }

  Future<void> _shareStatisticsPic() async {
    try {
      RenderRepaintBoundary boundary = _sharePicKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/statistik_share.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Meine Drei ??? Hörstatistiken!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Teilen des Bildes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    final episodeProvider = Provider.of<EpisodeStateProvider>(context);
    final episodes = episodeProvider.episodes;

    // Gruppiere die Episoden nach Typ
    final mainEpisodes = episodes.where((e) => e.serieTyp == 'Serie').toList();
    final spezialEpisodes = episodes.where((e) => e.serieTyp == 'Spezial').toList();
    final kurzEpisodes = episodes.where((e) => e.serieTyp == 'Kurzgeschichte').toList();
    final kidsEpisodes = episodes.where((e) => e.serieTyp == 'Kids').toList();
    final dr3iEpisodes = episodes.where((e) => e.serieTyp == 'DR3i').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiken'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            tooltip: 'Statistik als Bild teilen',
            onPressed: _shareStatisticsPic,
          ),
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
        child: RepaintBoundary(
          key: _sharePicKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(),
            SizedBox(height: 24),
              // Fortschritt pro Serie (rot/grüne Balken) in gewünschter Reihenfolge
              _buildProgressTimeline(mainEpisodes, '???'),
              _buildProgressTimeline(spezialEpisodes, 'Spezial'),
              _buildProgressTimeline(kurzEpisodes, 'Kurzgeschichten'),
              _buildProgressTimeline(kidsEpisodes, 'Kids'),
              _buildProgressTimeline(dr3iEpisodes, 'DR3i'),
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
    final Map<String, int> listenedPerMonth = Map<String, int>.from(statistics['listenedPerMonth'] as Map? ?? {});
    final sortedKeys = listenedPerMonth.keys.toList()..sort();
    // Kumulativ berechnen
    int sum = 0;
    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      sum += listenedPerMonth[sortedKeys[i]]!;
      spots.add(FlSpot(i.toDouble(), sum.toDouble()));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fortschritt über Zeit (gehört am)', style: Theme.of(context).textTheme.titleLarge),
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
                      spots: spots,
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
                    ? GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => EpisodeDetailPage(episode: ep),
                          ));
                        },
                        child: CachedNetworkImage(
                        imageUrl: ep.coverUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.broken_image),
                        ),
                      )
                    : Icon(Icons.album),
                title: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => EpisodeDetailPage(episode: ep),
                    ));
                  },
                  child: Text(
                    '${ep.nummer} / ${ep.titel}',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
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
    final episodeProvider = Provider.of<EpisodeStateProvider>(context, listen: false);
    final episodes = episodeProvider.episodes;
    final Map<String, int> authorCounts = Map<String, int>.from(statistics['authorCounts'] as Map);
    final sorted = authorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top-Autoren', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
            child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
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
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                          rodStackItems: [],
                          ),
                        ],
                      ),
                  ],
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (event.isInterestedForInteractions && response != null && response.spot != null) {
                      final idx = response.spot!.touchedBarGroupIndex;
                      if (idx >= 0 && idx < top.length) {
                        _showAuthorEpisodesDialog(context, top[idx].key, episodes);
                      }
                    }
                  },
                ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          value.toInt().toString(),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                      reservedSize: 64,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= top.length) return Container();
                          if (idx % 2 != 0) return Container();
                        return Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: GestureDetector(
                            onTap: () => _showAuthorEpisodesDialog(context, top[idx].key, episodes),
                            child: Transform.rotate(
                              angle: -0.7,
                            child: Tooltip(
                              message: top[idx].key,
                              child: Text(
                                top[idx].key.length > 8 ? top[idx].key.substring(0, 8) + '…' : top[idx].key,
                                  style: TextStyle(
                                    fontSize: 9,
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue,
                                  ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                ),
                              ),
                              ),
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
        Align(
          alignment: Alignment.centerLeft,
            child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
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
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          value.toInt().toString(),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                        // Zeige nur jede 5. Jahreszahl an
                        if (idx % 5 != 0) return Container();
                          if (idx < 0 || idx >= sorted.length) return Container();
                        return Text(
                              sorted[idx].key,
                          style: TextStyle(fontSize: 10),
                              maxLines: 1,
                          overflow: TextOverflow.visible,
                          );
                        },
                      reservedSize: 28,
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

  Widget _buildProgressTimeline(List<Episode> episodes, String title) {
    if (episodes.isEmpty) return SizedBox();

    // Chronologisch sortieren
    final sorted = List<Episode>.from(episodes)
      ..sort((a, b) => (a.veroeffentlichungsdatum ?? '').compareTo(b.veroeffentlichungsdatum ?? ''));
    final total = sorted.length;
    final listened = sorted.where((e) => e.listened).length;

    // Maximal 100 Balken, jeder Balken steht für n Folgen
    const maxBars = 100;
    final bars = <Widget>[];
    final groupSize = (total / maxBars).ceil().clamp(1, total);

    for (int i = 0; i < total; i += groupSize) {
      final group = sorted.sublist(i, (i + groupSize).clamp(0, total));
      final listenedCount = group.where((e) => e.listened).length;
      final color = listenedCount >= (group.length / 2) ? Colors.green : Colors.red;
      bars.add(
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 0.5),
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: $listened/$total (${total > 0 ? ((listened / total) * 100).toStringAsFixed(1) : '0'}%)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: bars,
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  void _showAuthorEpisodesDialog(BuildContext context, String author, List<Episode> episodes) {
    final authorEpisodes = episodes.where((ep) => ep.autor == author).toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(author),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: authorEpisodes.length,
            itemBuilder: (context, index) {
              final ep = authorEpisodes[index];
              return ListTile(
                leading: ep.coverUrl != null && ep.coverUrl!.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => EpisodeDetailPage(episode: ep),
                          ));
                        },
                        child: Image.network(ep.coverUrl!, width: 32, height: 32, fit: BoxFit.cover),
                      )
                    : Icon(Icons.album, size: 32),
                title: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => EpisodeDetailPage(episode: ep),
                    ));
                  },
                  child: Text(ep.titel, style: TextStyle(decoration: TextDecoration.underline)),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Schließen'),
          ),
      ],
      ),
    );
  }
}