import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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
    _initialize();
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

  List<Episode> getFilteredEpisodes() {
    final interpreter = _tabController.index == 0
        ? 'Die drei ???'
        : _tabController.index == 1
        ? 'Die drei ??? Kids'
        : 'DiE DR3i';

    // Filtern
    List<Episode> filtered = allEpisodes.where((ep) {
      if (ep.interpreter != interpreter) return false;
      if (filterListened && !ep.listened) return false;
      if (filterStars >= 0 && ep.rating != filterStars) return false;
      if (filterMinStars >= 0 && ep.rating < filterMinStars) return false;

      // Erweiterte Filter
      if (filterAuthor != null && ep.author != filterAuthor) return false;

      if (filterCharacter != null) {
        bool hasCharacter = false;
        for (var role in ep.roles) {
          if (role.containsKey('Character') && role['Character'] == filterCharacter) {
            hasCharacter = true;
            break;
          }
        }
        if (!hasCharacter) return false;
      }

      if (filterYear != null) {
        try {
          final date = DateTime.parse(ep.releaseDate);
          if (date.year.toString() != filterYear) return false;
        } catch (_) {
          return false;
        }
      }

      final searchLower = searchQuery.toLowerCase();
      if (searchLower.isNotEmpty &&
          !('${ep.numberEuropa} ${ep.title} ${ep.description} ${ep.roles.map((r) => r['Speaker'] ?? r['Character'] ?? "").join(' ')}'
              .toLowerCase()
              .contains(searchLower))) {
        return false;
      }

      return true;
    }).toList();

    // Sortieren
    switch (currentSortOption) {
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

    return filtered;
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
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      ep.image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
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