import 'package:flutter/material.dart';
import 'episode.dart';
import 'episode_data_service.dart';
import 'episode_detail_page.dart';

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

  List<Episode> _filter(List<Episode> episodes) {
    if (_search.isEmpty) return episodes;
    return episodes.where((ep) =>
      ep.titel.toLowerCase().contains(_search.toLowerCase()) ||
      ep.nummer.toString().contains(_search) ||
      (ep.autor.toLowerCase().contains(_search.toLowerCase()))
    ).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('???'),
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
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Suche Episoden...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_filter(_mainEpisodes)),
                      _buildList(_filter(_kidsEpisodes)),
                      _buildList(_filter(_dr3iEpisodes)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Episode> episodes) {
    if (episodes.isEmpty) {
      return Center(child: Text('Keine Episoden gefunden.'));
    }
    return ListView.separated(
      itemCount: episodes.length,
      separatorBuilder: (_, __) => Divider(height: 1),
      itemBuilder: (context, index) {
        final ep = episodes[index];
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
      },
    );
  }
} 