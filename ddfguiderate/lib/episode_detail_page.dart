import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'episode.dart';
import 'main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'database_service.dart';
import 'package:intl/intl.dart';
import 'spotify_id_resolver.dart';

class EpisodeDetailPage extends StatefulWidget {
  final Episode episode;
  final VoidCallback onUpdate;

  EpisodeDetailPage({required this.episode, required this.onUpdate});

  @override
  _EpisodeDetailPageState createState() => _EpisodeDetailPageState();
}

class _EpisodeDetailPageState extends State<EpisodeDetailPage> {
  late Episode episode;
  bool showAllRoles = false;
  TextEditingController? _noteController;
  String? _noteInitialValue;
  bool _isEditingNote = false;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    episode = widget.episode;
    _loadNote();
  }

  Future<void> _loadNote() async {
    final state = await _dbService.getEpisodeState(episode.id);
    final note = state?['note'] ?? '';
    setState(() {
      _noteInitialValue = note;
      _noteController = TextEditingController(text: note);
      episode.note = note;
    });
  }

  Future<void> _saveNote(String value) async {
    await _dbService.updateEpisodeState(episode.id, note: value);
    setState(() {
      episode.note = value;
      _noteInitialValue = value;
      _isEditingNote = false;
    });
  }

  Future<void> _deleteNote() async {
    final oldNote = _noteController?.text ?? '';
    await _dbService.updateEpisodeState(episode.id, note: '');
    setState(() {
      _noteController?.text = '';
      episode.note = '';
      _isEditingNote = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notiz gelöscht'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () async {
            await _dbService.updateEpisodeState(episode.id, note: oldNote);
            setState(() {
              _noteController?.text = oldNote;
              episode.note = oldNote;
            });
          },
        ),
      ),
    );
  }

  void _startEditNote() {
    setState(() {
      _isEditingNote = true;
    });
  }

  Future<void> _saveRating(int rating) async {
    await _dbService.updateEpisodeState(episode.id, rating: rating);
    setState(() {
      episode.rating = rating;
    });
  }

  Future<void> _saveListened(bool listened) async {
    await _dbService.updateEpisodeState(episode.id, listened: listened);
    setState(() {
      episode.listened = listened;
    });
  }

  @override
  void dispose() {
    _noteController?.dispose();
    super.dispose();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final ratingsJson = prefs.getString('episode_ratings');
    final listenedJson = prefs.getString('episode_listened');

    final Map<String, dynamic> ratingsMap =
    ratingsJson != null ? json.decode(ratingsJson) : {};
    final Map<String, dynamic> listenedMap =
    listenedJson != null ? json.decode(listenedJson) : {};

    ratingsMap[episode.id] = episode.rating;
    listenedMap[episode.id] = episode.listened;

    await prefs.setString('episode_ratings', json.encode(ratingsMap));
    await prefs.setString('episode_listened', json.encode(listenedMap));

    widget.onUpdate();
  }

  void setRating(int rating) {
    setState(() {
      // Wenn der Benutzer auf den bereits ausgewählten Stern klickt, setze die Bewertung zurück
      if (episode.rating == rating) {
        episode.rating = 0;
      } else {
        episode.rating = rating;
      }
    });
    _saveState();
  }

  void toggleListened() {
    setState(() {
      episode.listened = !episode.listened;
    });
    _saveState();
  }

  void _openSpotify() async {
    // Diese Funktion entfällt, da spotifyAlbumId nicht mehr im Modell vorhanden ist
  }

  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return '${parsedDate.day.toString().padLeft(2, '0')}.${parsedDate.month.toString().padLeft(2, '0')}.${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  Future<void> _showHistoryDialog() async {
    final db = DatabaseService();
    final history = await db.getHistory(episode.id);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Änderungsverlauf'),
        content: SizedBox(
          width: double.maxFinite,
          child: history.isEmpty
              ? Text('Keine Änderungen vorhanden.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    final date = DateTime.fromMillisecondsSinceEpoch(entry['timestamp'] ?? 0);
                    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(date);
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text('Notiz: ${entry['note'] ?? ''}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bewertung: ${entry['rating'] ?? 0} Sterne'),
                            Text('Gehört: ${(entry['listened'] ?? 0) == 1 ? "Ja" : "Nein"}'),
                            Text('Zeit: $dateStr'),
                          ],
                        ),
                        trailing: TextButton(
                          child: Text('Wiederherstellen'),
                          onPressed: () async {
                            await db.updateEpisodeState(
                              episode.id,
                              note: entry['note'],
                              rating: entry['rating'],
                              listened: (entry['listened'] ?? 0) == 1,
                            );
                            await _loadNote();
                            setState(() {
                              episode.rating = entry['rating'] ?? 0;
                              episode.listened = (entry['listened'] ?? 0) == 1;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Stand wiederhergestellt.')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = MyApp.of(context);
    final rolesToShow = showAllRoles ? episode.sprechrollen : episode.sprechrollen?.take(3).toList();
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('??? Guide'),
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
            Hero(
              tag: 'episode_${episode.id}',
              child: Container(
                color: Colors.black,
                width: double.infinity,
                padding: EdgeInsets.all(8),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: CachedNetworkImage(
                    imageUrl: episode.coverUrl ?? '',
                    fit: BoxFit.contain,
                    fadeInDuration: Duration(milliseconds: 100),
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: episode.isFutureRelease
                            ? Text(
                                'NEW',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              )
                            : Icon(Icons.broken_image, size: 100),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '${episode.nummer} / ${episode.titel}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16),
                SizedBox(width: 4),
                Text('Veröffentlichung: ${formatDate(episode.veroeffentlichungsdatum ?? '')}'),
              ],
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beschreibung',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(episode.beschreibung),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16),
                        SizedBox(width: 4),
                        Text('Autor: ${episode.autor}'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sprecher:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (rolesToShow != null && rolesToShow.isNotEmpty)
                      ...rolesToShow.map((role) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text('${role['rolle'] ?? 'Unbekannt'}: ${role['sprecher'] ?? 'Unbekannt'}'),
                          ))
                    else
                      Text('Keine Sprecherinformationen verfügbar'),
                    if (episode.sprechrollen != null && episode.sprechrollen!.length > 3)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showAllRoles = !showAllRoles;
                          });
                        },
                        child: Text(showAllRoles ? 'Weniger anzeigen' : 'Alle anzeigen'),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streaming',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (episode.spotifyUrl != null && episode.spotifyUrl!.isNotEmpty) {
                          final url = episode.spotifyUrl!;
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            return;
                          }
                        }
                        // Fallback: Suche
                        final searchUrl = 'https://open.spotify.com/search/${Uri.encodeComponent(episode.titel)}';
                        if (await canLaunchUrl(Uri.parse(searchUrl))) {
                          await launchUrl(Uri.parse(searchUrl), mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: Icon(Icons.play_circle_outline),
                      label: Text('Auf Spotify anhören'),
                    ),
                  ],
                ),
              ),
            ),
            if (_noteController != null) ...[
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Notiz', style: Theme.of(context).textTheme.titleMedium),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                tooltip: 'Bearbeiten',
                                onPressed: _isEditingNote ? null : _startEditNote,
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                tooltip: 'Löschen',
                                onPressed: episode.note?.isNotEmpty == true ? _deleteNote : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        minLines: 2,
                        maxLines: 6,
                        enabled: _isEditingNote,
                        decoration: InputDecoration(
                          hintText: 'Deine Notiz zu dieser Folge ...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) => _saveNote(value),
                        onEditingComplete: () => _saveNote(_noteController!.text),
                      ),
                      if (_isEditingNote)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            child: Text('Speichern'),
                            onPressed: () => _saveNote(_noteController!.text),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bewertung',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        int starIndex = index + 1;
                        return IconButton(
                          icon: Icon(
                            episode.rating >= starIndex
                                ? Icons.star
                                : Icons.star_border,
                          ),
                          color: Colors.amber,
                          onPressed: () => _saveRating(starIndex),
                        );
                      }),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Gehört: '),
                        Switch(
                          value: episode.listened,
                          onChanged: (value) => _saveListened(value),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.history),
                  label: Text('Änderungsverlauf anzeigen'),
                  onPressed: _showHistoryDialog,
                ),
              ],
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}