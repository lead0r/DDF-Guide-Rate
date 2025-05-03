import 'package:flutter/material.dart';
import 'episode.dart';
import 'episode_data_service.dart';
import 'episode_detail_page.dart';
import 'backup_service.dart';
import 'statistics_page.dart';
import 'settings_page.dart';
import 'main.dart';

class EpisodeListPage extends StatefulWidget {
  @override
  _EpisodeListPageState createState() => _EpisodeListPageState();
}

class _EpisodeListPageState extends State<EpisodeListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Episode> _mainEpisodes = [];
  List<Episode> _kidsEpisodes = [];
  List<Episode> _dr3iEpisodes = [];
  bool _loading = true;
  String _search = '';
  bool _showFuture = false;
  String _sortBy = 'date'; // 'date' oder 'number'
  // Filter-Status
  String _selectedAuthor = '';
  String _selectedYear = '';
  int _selectedRating = -1;
  String _selectedListened = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEpisodes();
    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text;
      });
    });
  }

  Future<void> _loadEpisodes() async {
    setState(() => _loading = true);
    final dataService = EpisodeDataService();
    final main = await dataService.fetchAllMainEpisodes();
    final kids = await dataService.fetchKidsEpisodes();
    final dr3i = await dataService.fetchDr3iEpisodes();
    setState(() {
      _mainEpisodes = main;
      _kidsEpisodes = kids;
      _dr3iEpisodes = dr3i;
      _loading = false;
    });
  }

  void _showFilterDialog() async {
    if (_mainEpisodes.isEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Filter auswählen'),
          content: SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Schließen'),
            ),
          ],
        ),
      );
      return;
    }
    final authors = <String>{};
    final years = <String>{};
    for (var ep in _mainEpisodes) {
      if (ep.autor.isNotEmpty) {
        ep.autor.split(',').map((a) => a.trim()).forEach(authors.add);
      }
      if (ep.veroeffentlichungsdatum != null && ep.veroeffentlichungsdatum!.length >= 4) {
        years.add(ep.veroeffentlichungsdatum!.substring(0, 4));
      }
    }

    final sortedAuthors = authors.where((a) => a.isNotEmpty).toList()..sort();
    final sortedYears = years.where((y) => y.isNotEmpty).toList()..sort((a, b) => b.compareTo(a));
    final ratingList = List.generate(5, (i) => 5 - i);
    final listenedValues = ['', 'true', 'false'];

    // Lokale Kopien der Filterwerte
    String authorValue = _selectedAuthor;
    String yearValue = _selectedYear;
    int ratingValue = _selectedRating;
    String listenedValue = _selectedListened;

    // Wert auf gültigen Wert mappen
    if (!sortedAuthors.contains(authorValue)) authorValue = '';
    if (!sortedYears.contains(yearValue)) yearValue = '';
    if (!ratingList.contains(ratingValue)) ratingValue = -1;
    if (!listenedValues.contains(listenedValue)) listenedValue = '';

    final authorItems = sortedAuthors.isEmpty
      ? [DropdownMenuItem(value: '', child: Text('Keine Autoren'))]
      : [DropdownMenuItem(value: '', child: Text('Alle Autoren'))] +
        sortedAuthors.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList();

    final yearItems = sortedYears.isEmpty
      ? [DropdownMenuItem(value: '', child: Text('Keine Jahre'))]
      : [DropdownMenuItem(value: '', child: Text('Alle Jahre'))] +
        sortedYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList();

    final ratingItems = [DropdownMenuItem(value: -1, child: Text('Alle Bewertungen'))] +
      ratingList.map((r) => DropdownMenuItem(value: r, child: Text('$r Sterne'))).toList();

    final listenedItems = [
      DropdownMenuItem(value: '', child: Text('Alle')),
      DropdownMenuItem(value: 'true', child: Text('Gehört')),
      DropdownMenuItem(value: 'false', child: Text('Nicht gehört')),
    ];

    // Debug-Ausgaben für Dropdowns
    print('authorItems: \\${authorItems.map((e) => e.value)}, authorValue: $authorValue');
    print('yearItems: \\${yearItems.map((e) => e.value)}, yearValue: $yearValue');
    print('ratingItems: \\${ratingItems.map((e) => e.value)}, ratingValue: $ratingValue');
    print('listenedItems: \\${listenedItems.map((e) => e.value)}, listenedValue: $listenedValue');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Filter auswählen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: authorItems.any((item) => item.value == authorValue) ? authorValue : authorItems.first.value,
                  items: authorItems,
                  onChanged: (v) => setState(() => authorValue = v ?? ''),
                  decoration: InputDecoration(labelText: 'Autor'),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: yearItems.any((item) => item.value == yearValue) ? yearValue : yearItems.first.value,
                  items: yearItems,
                  onChanged: (v) => setState(() => yearValue = v ?? ''),
                  decoration: InputDecoration(labelText: 'Jahr'),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: ratingItems.any((item) => item.value == ratingValue) ? ratingValue : ratingItems.first.value,
                  items: ratingItems,
                  onChanged: (v) => setState(() => ratingValue = v ?? -1),
                  decoration: InputDecoration(labelText: 'Bewertung'),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: listenedItems.any((item) => item.value == listenedValue) ? listenedValue : listenedItems.first.value,
                  items: listenedItems,
                  onChanged: (v) => setState(() => listenedValue = v ?? ''),
                  decoration: InputDecoration(labelText: 'Gehört-Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  authorValue = '';
                  yearValue = '';
                  ratingValue = -1;
                  listenedValue = '';
                });
              },
              child: Text('Zurücksetzen'),
            ),
            TextButton(
              onPressed: () {
                // Übernehme die Werte in den State der Seite
                setState(() {
                  _selectedAuthor = authorValue;
                  _selectedYear = yearValue;
                  _selectedRating = ratingValue;
                  _selectedListened = listenedValue;
                });
                Navigator.pop(context);
              },
              child: Text('Anwenden'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Schließen'),
            ),
          ],
        ),
      ),
    );
  }

  List<Episode> _filterAndSort(List<Episode> episodes) {
    List<Episode> filtered = episodes.where((ep) =>
      (_search.isEmpty ||
        ep.titel.toLowerCase().contains(_search.toLowerCase()) ||
        ep.nummer.toString().contains(_search) ||
        (ep.autor.toLowerCase().contains(_search.toLowerCase()))) &&
      (_selectedAuthor == '' || ep.autor == _selectedAuthor) &&
      (_selectedYear == '' || (ep.veroeffentlichungsdatum != null && ep.veroeffentlichungsdatum!.startsWith(_selectedYear))) &&
      (_selectedRating == -1 || ep.rating == _selectedRating) &&
      (_selectedListened == '' || (_selectedListened == 'true' ? ep.listened : !ep.listened))
    ).toList();
    if (_sortBy == 'date') {
      filtered.sort((a, b) => (b.veroeffentlichungsdatum ?? '').compareTo(a.veroeffentlichungsdatum ?? ''));
    } else {
      filtered.sort((a, b) => b.nummer.compareTo(a.nummer));
    }
    return filtered;
  }

  List<Episode> _futureEpisodes(List<Episode> episodes) =>
      episodes.where((ep) => ep.isFutureRelease).toList();
  List<Episode> _pastEpisodes(List<Episode> episodes) =>
      episodes.where((ep) => !ep.isFutureRelease).toList();

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Sortieren nach'),
        children: [
          RadioListTile<String>(
            value: 'date',
            groupValue: _sortBy,
            title: Text('Neueste zuerst'),
            onChanged: (v) {
              setState(() => _sortBy = v!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            value: 'number',
            groupValue: _sortBy,
            title: Text('Folgen-Nummer absteigend'),
            onChanged: (v) {
              setState(() => _sortBy = v!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('???'),
        actions: [
          IconButton(
            icon: Icon(Icons.backup),
            tooltip: 'Backup',
            onPressed: () => BackupService.showBackupDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.sort),
            tooltip: 'Sortieren',
            onPressed: _showSortDialog,
          ),
          IconButton(
            icon: Icon(Icons.bar_chart),
            tooltip: 'Statistiken',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StatisticsPage(episodes: _mainEpisodes))),
          ),
          IconButton(
            icon: Icon(Icons.filter_alt),
            tooltip: 'Filter',
            onPressed: _loading ? null : _showFilterDialog,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage())),
          ),
          IconButton(
            icon: Icon(appState?.themeMode == ThemeMode.dark ? Icons.wb_sunny : Icons.nightlight_round),
            tooltip: 'Dark/Light Mode',
            onPressed: () => appState?.toggleTheme(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Hauptserie'),
            Tab(text: 'Kids'),
            Tab(text: 'DR3i'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Suche Episoden...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_mainEpisodes),
                      _buildList(_kidsEpisodes),
                      _buildList(_dr3iEpisodes),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Episode> episodes) {
    final future = _filterAndSort(_futureEpisodes(episodes));
    final past = _filterAndSort(_pastEpisodes(episodes));
    return ListView(
      children: [
        ExpansionTile(
          title: Text('Zukünftige Episoden (${future.length})'),
          initiallyExpanded: _showFuture,
          onExpansionChanged: (v) => setState(() => _showFuture = v),
          children: future.map((ep) => _buildTile(ep)).toList(),
        ),
        ...past.map((ep) => _buildTile(ep)),
      ],
    );
  }

  Widget _buildTile(Episode ep) {
    return ListTile(
      leading: ep.coverUrl != null && ep.coverUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(ep.coverUrl!, width: 48, height: 48, fit: BoxFit.cover),
            )
          : Icon(Icons.album, size: 48),
      title: Text('${ep.nummer} / ${ep.titel}'),
      subtitle: Text(ep.autor),
      trailing: ep.isFutureRelease
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('NEU', style: TextStyle(color: Colors.white)),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EpisodeDetailPage(episode: ep),
          ),
        );
      },
    );
  }
} 