import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'episode.dart';
import 'episode_detail_page.dart';
import 'main.dart';

class EpisodeListPage extends StatefulWidget {
  @override
  _EpisodeListPageState createState() => _EpisodeListPageState();
}

class _EpisodeListPageState extends State<EpisodeListPage>
    with SingleTickerProviderStateMixin {
  List<Episode> allEpisodes = [];
  String searchQuery = '';
  bool filterListened = false;
  int filterStars = -1;
  int filterMinStars = -1;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initialize();
  }

  Future<void> _initialize() async {
    final loadedEpisodes = await loadEpisodes();
    setState(() {
      allEpisodes = loadedEpisodes;
    });
    await _loadStates();
  }

  Future<List<Episode>> loadEpisodes() async {
    final String response =
    await rootBundle.loadString('assets/data/dtos.json');
    final List<dynamic> data = json.decode(response);
    final episodes = data.map((json) => Episode.fromJson(json)).toList();
    episodes.sort((a, b) => b.numberEuropa.compareTo(a.numberEuropa));
    return episodes;
  }

  Future<void> _loadStates() async {
    final prefs = await SharedPreferences.getInstance();
    final ratingsJson = prefs.getString('episode_ratings');
    final listenedJson = prefs.getString('episode_listened');

    if (ratingsJson != null) {
      final Map<String, dynamic> ratingsMap = json.decode(ratingsJson);
      setState(() {
        allEpisodes = allEpisodes.map((ep) {
          ep.rating = ratingsMap[ep.id] ?? 0;
          return ep;
        }).toList();
      });
    }

    if (listenedJson != null) {
      final Map<String, dynamic> listenedMap = json.decode(listenedJson);
      setState(() {
        allEpisodes = allEpisodes.map((ep) {
          ep.listened = listenedMap[ep.id] ?? false;
          return ep;
        }).toList();
      });
    }
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempStars = filterStars;
        int tempMinStars = filterMinStars;
        bool tempListened = filterListened;

        return AlertDialog(
          title: Text('Filter auswählen'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: Text('Schon gehört'),
                      value: tempListened,
                      onChanged: (value) => setState(() => tempListened = value!),
                    ),
                    Divider(),
                    Text('Exakte Sterne'),
                    Wrap(
                      spacing: 4,
                      children: [
                        ChoiceChip(
                          label: Text('Kein Filter'),
                          selected: tempStars == -1,
                          onSelected: (_) => setState(() => tempStars = -1),
                        ),
                        ...List.generate(6, (index) {
                          return ChoiceChip(
                            label: Text('$index Sterne'),
                            selected: tempStars == index,
                            onSelected: (_) => setState(() => tempStars = index),
                          );
                        }),
                      ],
                    ),
                    Divider(),
                    Text('Mindestens Sterne'),
                    Wrap(
                      spacing: 4,
                      children: [
                        ChoiceChip(
                          label: Text('Kein Filter'),
                          selected: tempMinStars == -1,
                          onSelected: (_) => setState(() => tempMinStars = -1),
                        ),
                        ...List.generate(5, (index) {
                          return ChoiceChip(
                            label: Text('≥ $index Sterne'),
                            selected: tempMinStars == index,
                            onSelected: (_) => setState(() => tempMinStars = index),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  filterStars = tempStars;
                  filterMinStars = tempMinStars;
                  filterListened = tempListened;
                });
                Navigator.of(context).pop();
              },
              child: Text('Anwenden'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Abbrechen'),
            ),
          ],
        );
      },
    );
  }

  List<Episode> getFilteredEpisodes() {
    final interpreter = _tabController.index == 0
        ? 'Die drei ???'
        : _tabController.index == 1
        ? 'Die drei ??? Kids'
        : 'DiE DR3i';

    return allEpisodes.where((ep) {
      if (ep.interpreter != interpreter) return false;
      if (filterListened && !ep.listened) return false;
      if (filterStars >= 0 && ep.rating != filterStars) return false;
      if (filterMinStars >= 0 && ep.rating < filterMinStars) return false;

      final searchLower = searchQuery.toLowerCase();
      if (searchLower.isNotEmpty &&
          !('${ep.numberEuropa} ${ep.title} ${ep.description} ${ep.roles.map((r) => r['Speaker']).join(' ')}'
              .toLowerCase()
              .contains(searchLower))) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    final filteredEpisodes = getFilteredEpisodes();

    return Scaffold(
      appBar: AppBar(
        title: Text('??? Guide'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _openFilterDialog,
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Die drei ???'),
            Tab(text: 'Die drei ??? Kids'),
            Tab(text: 'Die DR3i'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Suchen…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: allEpisodes.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView(
              children: filteredEpisodes.map((ep) {
                return ListTile(
                  leading: Image.network(
                    ep.image,
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.broken_image),
                  ),
                  title: Text('${ep.numberEuropa} / ${ep.title}'),
                  subtitle: Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          int starIndex = index + 1;
                          return Icon(
                            ep.rating >= starIndex
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        ep.listened
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: ep.listened ? Colors.green : Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EpisodeDetailPage(
                            episode: ep, onUpdate: _loadStates),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}