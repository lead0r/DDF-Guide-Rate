// For the Progress Chart Section
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
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString());
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx % 5 != 0) return Container();
                        if (idx < 0 || idx >= sortedKeys.length) return Container();
                        return Text(sortedKeys[idx].replaceAll('-', '/'));
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

// For the Author Bar Chart Section
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
                      ),
                    ],
                  ),
              ],
              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
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
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString());
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx % 2 != 0) return Container();
                      if (idx < 0 || idx >= top.length) return Container();
                      final name = top[idx].key;
                      return Text(name.length > 6 ? name.substring(0, 6) + '…' : name);
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
    ],
  );
}

// For the Year Bar Chart Section
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
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString());
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx % 5 != 0) return Container();
                      if (idx < 0 || idx >= sorted.length) return Container();
                      return Text(sorted[idx].key);
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
    ],
  );
}

// Fix for the unmatched bracket and parenthesis at the end of the file
// Replace line 449 and nearby lines with this:
// (This is part of _buildYearBarChartSection)
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
      ),
    ],
  );
}