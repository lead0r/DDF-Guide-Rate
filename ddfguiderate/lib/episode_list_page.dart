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
    final authors = <String>{};
    final years = <String>{};
    for (var ep in _mainEpisodes) {
      authors.add(ep.autor);
      if (ep.veroeffentlichungsdatum != null && ep.veroeffentlichungsdatum!.length >= 4) {
        years.add(ep.veroeffentlichungsdatum!.substring(0, 4));
      }
    }
    final sortedAuthors = authors.toList()..sort();
    final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
    final authorValue = sortedAuthors.contains(_selectedAuthor) ? _selectedAuthor : '';
    final yearValue = sortedYears.contains(_selectedYear) ? _selectedYear : '';
    final ratingList = List.generate(5, (i) => 5 - i);
    final ratingValue = ratingList.contains(_selectedRating) ? _selectedRating : -1;
    final listenedValues = ['', 'true', 'false'];
    final listenedValue = listenedValues.contains(_selectedListened) ? _selectedListened : '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Filter auswählen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: authorValue,
                  items: [DropdownMenuItem(value: '', child: Text('Alle Autoren'))] +
                      sortedAuthors.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (v) => setState(() => _selectedAuthor = v ?? ''),
                  decoration: InputDecoration(labelText: 'Autor'),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: yearValue,
                  items: [DropdownMenuItem(value: '', child: Text('Alle Jahre'))] +
                      sortedYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (v) => setState(() => _selectedYear = v ?? ''),
                  decoration: InputDecoration(labelText: 'Jahr'),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: ratingValue,
                  items: [DropdownMenuItem(value: -1, child: Text('Alle Bewertungen'))] +
                      ratingList.map((r) => DropdownMenuItem(value: r, child: Text('$r Sterne'))).toList(),
                  onChanged: (v) => setState(() => _selectedRating = v ?? -1),
                  decoration: InputDecoration(labelText: 'Bewertung'),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: listenedValue,
                  items: [
                    DropdownMenuItem(value: '', child: Text('Alle')),
                    DropdownMenuItem(value: 'true', child: Text('Gehört')),
                    DropdownMenuItem(value: 'false', child: Text('Nicht gehört')),
                  ],
                  onChanged: (v) => setState(() => _selectedListened = v ?? ''),
                  decoration: InputDecoration(labelText: 'Gehört-Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedAuthor = '';
                  _selectedYear = '';
                  _selectedRating = -1;
                  _selectedListened = '';
                });
              },
              child: Text('Zurücksetzen'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
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
            onPressed: _showFilterDialog,
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