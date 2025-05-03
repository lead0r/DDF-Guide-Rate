import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

import 'episode.dart';
import 'episode_detail_page.dart';
import 'statistics_page.dart';
import 'backup_service.dart';
import 'notification_service.dart';
import 'main.dart';

// Enum für Sortieroptionen muss auf Top-Level sein
enum SortOption {
  numberDesc,
  numberAsc,
  ratingDesc,
  ratingAsc,
  releaseDateDesc,
  releaseDateAsc,
  title
}

class EpisodeListPage extends StatefulWidget {
  @override
  _EpisodeListPageState createState() => _EpisodeListPageState();
}

class _EpisodeListPageState extends State<EpisodeListPage>
    with SingleTickerProviderStateMixin {
  List<Episode> allEpisodes = [];
  List<Episode> _filteredEpisodes = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 0;
  static const int _itemsPerPage = 20;
  String searchQuery = '';
  bool filterListened = false;
  int filterStars = -1;
  int filterMinStars = -1;
  String? filterAuthor;
  String? filterCharacter;
  String? filterYear;
  late TabController _tabController;

  SortOption currentSortOption = SortOption.numberDesc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    await Future.delayed(Duration(milliseconds: 100)); // Prevent rapid multiple calls
    
    final nextPageItems = await compute(_getPageItems, _FilterSortParams(
      allEpisodes: allEpisodes,
      filterParams: _FilterParams(
        interpreter: _tabController.index == 0
            ? 'Die drei ???'
            : _tabController.index == 1
            ? 'Die drei ??? Kids'
            : 'DiE DR3i',
        listened: filterListened,
        stars: filterStars,
        minStars: filterMinStars,
        author: filterAuthor,
        character: filterCharacter,
        year: filterYear,
        searchQuery: searchQuery,
      ),
      sortOption: currentSortOption,
      page: _currentPage,
      itemsPerPage: _itemsPerPage,
    ));

    setState(() {
      _filteredEpisodes.addAll(nextPageItems);
      _currentPage++;
      _isLoading = false;
    });
  }

  Future<void> _refreshList() async {
    setState(() {
      _currentPage = 0;
      _filteredEpisodes.clear();
    });
    await _loadMoreItems();
  }

  Future<void> _initialize() async {
    final loadedEpisodes = await loadEpisodes();
    setState(() {
      allEpisodes = loadedEpisodes;
    });
    await _loadStates();

    // Vereinfachte Benachrichtigungsfunktion
    await NotificationService.initialize();
    await NotificationService.checkForNewEpisodes(allEpisodes);
    await NotificationService.scheduleReminder();

    // Optional: Zeige Benachrichtigung für neue Episoden an
    // Dies würde eine BuildContext benötigen, was hier nicht einfach verfügbar ist
    // Du könntest es stattdessen im build-Methode oder nach einem kurzen Verzögerung tun
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

    if (ratingsJson != null || listenedJson != null) {
      final updatedEpisodes = await compute(_updateEpisodesState, _StateUpdateParams(
        episodes: allEpisodes,
        ratingsJson: ratingsJson,
        listenedJson: listenedJson,
      ));

      setState(() {
        allEpisodes = updatedEpisodes;
      });
    }
  }

  void _openSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sortieren nach'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<SortOption>(
                  title: Text('Folgen-Nr. (neueste zuerst)'),
                  value: SortOption.numberDesc,
                  groupValue: currentSortOption,
                  onChanged: (value) {
                    setState(() => currentSortOption = value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<SortOption>(
                  title: Text('Folgen-Nr. (älteste zuerst)'),
                  value: SortOption.numberAsc,
                  groupValue: currentSortOption,
                  onChanged: (value) {
                    setState(() => currentSortOption = value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<SortOption>(
                  title: Text('Bewertung (höchste zuerst)'),
                  value: SortOption.ratingDesc,
                  groupValue: currentSortOption,
                  onChanged: (value) {
                    setState(() => currentSortOption = value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<SortOption>(
                  title: Text('Bewertung (niedrigste zuerst)'),
                  value: SortOption.ratingAsc,
                  groupValue: currentSortOption,
                  onChanged: (value) {
                    setState(() => currentSortOption = value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<SortOption>(
                  title: Text('Erscheinungsdatum (neueste zuerst)'),
                  value: SortOption.releaseDateDesc,
                  groupValue: currentSortOption,
                  onChanged: (value) {
                    setState(() => currentSortOption = value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<SortOption>(
                  title: Text('Erscheinungsdatum (älteste zuerst)'),
                  value: SortOption.releaseDateAsc,
                  groupValue: currentSortOption,
                  onChanged: (value) {
                    setState(() => currentSortOption = value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<SortOption>(
                  title: Text('Titel (A-Z)'),
                  value: SortOption.title,
                  groupValue: currentSortOption,
                  onChanged: (value) {
                    setState(() => currentSortOption = value!);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempStars = filterStars;
        int tempMinStars = filterMinStars;
        bool tempListened = filterListened;
        String? tempAuthor = filterAuthor;
        String? tempCharacter = filterCharacter;
        String? tempYear = filterYear;

        // Sammle eindeutige Autoren und Rollen
        final Set<String> authors = Set();
        final Set<String> characters = Set();
        final Set<String> years = Set();

        for (var episode in allEpisodes) {
          if (episode.author.isNotEmpty) {
            authors.add(episode.author);
          }

          for (var role in episode.roles) {
            if (role.containsKey('Character')) {
              characters.add(role['Character']);
            }
          }

          try {
            final date = DateTime.parse(episode.releaseDate);
            years.add(date.year.toString());
          } catch (_) {}
        }

        // Sortiere die Listen
        final sortedAuthors = authors.toList()..sort();
        final sortedCharacters = characters.toList()..sort();
        final sortedYears = years.toList()..sort((a, b) => b.compareTo(a)); // Neueste zuerst

        return AlertDialog(
          title: Text('Filter auswählen'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    Divider(),
                    Text('Autor'),
                    DropdownButton<String?>(
                      isExpanded: true,
                      hint: Text('Alle Autoren'),
                      value: tempAuthor,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Alle Autoren'),
                        ),
                        ...sortedAuthors.map((author) => DropdownMenuItem<String?>(
                          value: author,
                          child: Text(author),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          tempAuthor = value;
                        });
                      },
                    ),

                    Divider(),
                    Text('Rolle/Charakter'),
                    DropdownButton<String?>(
                      isExpanded: true,
                      hint: Text('Alle Rollen'),
                      value: tempCharacter,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Alle Rollen'),
                        ),
                        ...sortedCharacters.map((character) => DropdownMenuItem<String?>(
                          value: character,
                          child: Text(character),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          tempCharacter = value;
                        });
                      },
                    ),

                    Divider(),
                    Text('Erscheinungsjahr'),
                    DropdownButton<String?>(
                      isExpanded: true,
                      hint: Text('Alle Jahre'),
                      value: tempYear,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Alle Jahre'),
                        ),
                        ...sortedYears.map((year) => DropdownMenuItem<String?>(
                          value: year,
                          child: Text(year),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          tempYear = value;
                        });
                      },
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
                  filterAuthor = tempAuthor;
                  filterCharacter = tempCharacter;
                  filterYear = tempYear;
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

  void _openStatisticsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatisticsPage(episodes: allEpisodes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('??? Guide'),
        actions: [
          IconButton(
            icon: Icon(Icons.backup),
            onPressed: () => BackupService.showBackupDialog(context),
            tooltip: 'Backup',
          ),
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _openSortDialog,
            tooltip: 'Sortieren',
          ),
          IconButton(
            icon: Icon(Icons.insert_chart),
            onPressed: _openStatisticsPage,
            tooltip: 'Statistiken',
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _openFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
            ),
            onPressed: () => appState?.toggleTheme(),
            tooltip: 'Thema wechseln',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Die drei ???'),
            Tab(text: 'Die drei ??? Kids'),
            Tab(text: 'DiE DR3i'),
          ],
          onTap: (_) => _refreshList(),
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
              onChanged: (value) {
                setState(() => searchQuery = value);
                _refreshList();
              },
            ),
          ),
          Expanded(
            child: allEpisodes.isEmpty
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshList,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredEpisodes.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _filteredEpisodes.length) {
                          return _isLoading
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : SizedBox.shrink();
                        }

                        final ep = _filteredEpisodes[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: ep.image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.broken_image),
                            ),
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
                                builder: (context) =>
                                    EpisodeDetailPage(episode: ep, onUpdate: _loadStates),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Data classes for compute isolate
class _FilterParams {
  final String interpreter;
  final bool listened;
  final int stars;
  final int minStars;
  final String? author;
  final String? character;
  final String? year;
  final String searchQuery;

  _FilterParams({
    required this.interpreter,
    required this.listened,
    required this.stars,
    required this.minStars,
    this.author,
    this.character,
    this.year,
    required this.searchQuery,
  });
}

class _FilterSortParams {
  final List<Episode> allEpisodes;
  final _FilterParams filterParams;
  final SortOption sortOption;
  final int page;
  final int itemsPerPage;

  _FilterSortParams({
    required this.allEpisodes,
    required this.filterParams,
    required this.sortOption,
    required this.page,
    required this.itemsPerPage,
  });
}

List<Episode> _getPageItems(_FilterSortParams params) {
  final filtered = params.allEpisodes.where((ep) {
    if (ep.interpreter != params.filterParams.interpreter) return false;
    if (params.filterParams.listened && !ep.listened) return false;
    if (params.filterParams.stars >= 0 && ep.rating != params.filterParams.stars) return false;
    if (params.filterParams.minStars >= 0 && ep.rating < params.filterParams.minStars) return false;

    if (params.filterParams.author != null && ep.author != params.filterParams.author) return false;

    if (params.filterParams.character != null) {
      bool hasCharacter = false;
      for (var role in ep.roles) {
        if (role.containsKey('Character') && role['Character'] == params.filterParams.character) {
          hasCharacter = true;
          break;
        }
      }
      if (!hasCharacter) return false;
    }

    if (params.filterParams.year != null) {
      try {
        final date = DateTime.parse(ep.releaseDate);
        if (date.year.toString() != params.filterParams.year) return false;
      } catch (_) {
        return false;
      }
    }

    final searchLower = params.filterParams.searchQuery.toLowerCase();
    if (searchLower.isNotEmpty &&
        !('${ep.numberEuropa} ${ep.title} ${ep.description} ${ep.roles.map((r) => r['Speaker'] ?? r['Character'] ?? "").join(' ')}'
            .toLowerCase()
            .contains(searchLower))) {
      return false;
    }

    return true;
  }).toList();

  // Sort the filtered list
  switch (params.sortOption) {
    case SortOption.numberDesc:
      filtered.sort((a, b) => b.numberEuropa.compareTo(a.numberEuropa));
      break;
    case SortOption.numberAsc:
      filtered.sort((a, b) => a.numberEuropa.compareTo(b.numberEuropa));
      break;
    case SortOption.ratingDesc:
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case SortOption.ratingAsc:
      filtered.sort((a, b) => a.rating.compareTo(b.rating));
      break;
    case SortOption.releaseDateDesc:
      filtered.sort((a, b) {
        try {
          return DateTime.parse(b.releaseDate).compareTo(DateTime.parse(a.releaseDate));
        } catch (_) {
          return 0;
        }
      });
      break;
    case SortOption.releaseDateAsc:
      filtered.sort((a, b) {
        try {
          return DateTime.parse(a.releaseDate).compareTo(DateTime.parse(b.releaseDate));
        } catch (_) {
          return 0;
        }
      });
      break;
    case SortOption.title:
      filtered.sort((a, b) => a.title.compareTo(b.title));
      break;
  }

  // Return paginated results
  final startIndex = params.page * params.itemsPerPage;
  if (startIndex >= filtered.length) return [];
  
  final endIndex = (startIndex + params.itemsPerPage).clamp(0, filtered.length);
  return filtered.sublist(startIndex, endIndex);
}

class _StateUpdateParams {
  final List<Episode> episodes;
  final String? ratingsJson;
  final String? listenedJson;

  _StateUpdateParams({
    required this.episodes,
    required this.ratingsJson,
    required this.listenedJson,
  });
}

List<Episode> _updateEpisodesState(_StateUpdateParams params) {
  final episodes = List<Episode>.from(params.episodes);
  
  if (params.ratingsJson != null) {
    final Map<String, dynamic> ratingsMap = json.decode(params.ratingsJson!);
    episodes.forEach((ep) {
      ep.rating = ratingsMap[ep.id] ?? 0;
    });
  }

  if (params.listenedJson != null) {
    final Map<String, dynamic> listenedMap = json.decode(params.listenedJson!);
    episodes.forEach((ep) {
      ep.listened = listenedMap[ep.id] ?? false;
    });
  }

  return episodes;
}