import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'episode.dart';
import 'database_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EpisodeDetailPage extends StatefulWidget {
  final Episode episode;
  const EpisodeDetailPage({Key? key, required this.episode}) : super(key: key);

  @override
  _EpisodeDetailPageState createState() => _EpisodeDetailPageState();
}

class _EpisodeDetailPageState extends State<EpisodeDetailPage> {
  late TextEditingController _noteController;
  int _rating = 0;
  bool _listened = false;
  bool _saving = false;
  bool _editingNote = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.episode.note ?? '');
    _rating = widget.episode.rating;
    _listened = widget.episode.listened;
    _editingNote = (widget.episode.note == null || widget.episode.note!.isEmpty);
  }

  Future<void> _saveState() async {
    setState(() => _saving = true);
    await DatabaseService().updateEpisodeState(
      widget.episode.id,
      note: _noteController.text,
      rating: _rating,
      listened: _listened,
    );
    widget.episode.rating = _rating;
    widget.episode.listened = _listened;
    widget.episode.note = _noteController.text;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gespeichert!')),
    );
  }

  Future<void> _reloadState() async {
    final state = await DatabaseService().getEpisodeState(widget.episode.id);
    if (state != null) {
      setState(() {
        _rating = state['rating'] ?? 0;
        _listened = (state['listened'] ?? 0) == 1;
        _noteController.text = state['note'] ?? '';
      });
    }
  }

  void _share() {
    final text = 'Meine Bewertung für ${widget.episode.titel} (#${widget.episode.nummer}): $_rating Sterne\n${_noteController.text}';
    Share.share(text);
  }

  void _openStreaming() async {
    final url = widget.episode.links['spotify'] ?? widget.episode.spotifyUrl;
    if (url != null && await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Streaming-Link nicht verfügbar.')),
      );
    }
  }

  Future<String> _getProviderName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('streaming_provider');
    switch (name) {
      case 'StreamingProvider.spotify': return 'Spotify';
      case 'StreamingProvider.appleMusic': return 'Apple Music';
      case 'StreamingProvider.bookbeat': return 'Bookbeat';
      case 'StreamingProvider.amazonMusic': return 'Amazon Music';
      case 'StreamingProvider.amazon': return 'Amazon';
      case 'StreamingProvider.youtubeMusic': return 'YouTube Music';
      default: return 'Spotify';
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.length < 10) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatHistoryDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _saveNote() async {
    setState(() => _saving = true);
    await DatabaseService().updateEpisodeState(
      widget.episode.id,
      note: _noteController.text,
      rating: _rating,
      listened: _listened,
    );
    widget.episode.note = _noteController.text;
    setState(() {
      _saving = false;
      _editingNote = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notiz gespeichert!')),
    );
  }

  Future<void> _deleteNote() async {
    setState(() => _saving = true);
    await DatabaseService().updateEpisodeState(
      widget.episode.id,
      note: '',
      rating: _rating,
      listened: _listened,
    );
    widget.episode.note = '';
    _noteController.clear();
    setState(() {
      _saving = false;
      _editingNote = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notiz gelöscht!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ep = widget.episode;
    return Scaffold(
      appBar: AppBar(
        title: Text('${ep.nummer} / ${ep.titel}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _share,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ep.coverUrl != null && ep.coverUrl!.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: ep.coverUrl!,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.broken_image),
                  ),
                ),
              ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('Autor: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(ep.autor),
              ],
            ),
            SizedBox(height: 8),
            if (ep.veroeffentlichungsdatum != null)
              Row(
                children: [
                  Text('Veröffentlichung: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_formatDate(ep.veroeffentlichungsdatum)),
                ],
              ),
            SizedBox(height: 16),
            Text(ep.beschreibung, style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            FutureBuilder<String>(
              future: _getProviderName(),
              builder: (context, snapshot) {
                final provider = snapshot.data ?? 'Spotify';
                return ElevatedButton.icon(
                  icon: Icon(Icons.play_arrow),
                  label: Text('Auf $provider abspielen'),
                  onPressed: _openStreaming,
                );
              },
            ),
            SizedBox(height: 16),
            if (ep.sprechrollen != null && ep.sprechrollen!.isNotEmpty) ...[
              Text('Sprecher:', style: Theme.of(context).textTheme.titleMedium),
              ...ep.sprechrollen!.map<Widget>((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text('${s['rolle'] ?? ''}: ${s['sprecher'] ?? ''}'),
              )),
              SizedBox(height: 12),
            ],
            if ((ep.links['dreifragezeichen'] != null) && (ep.serieTyp == 'Serie' || ep.serieTyp == 'Kids'))
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.link),
                  label: Text('Offizielle Episodenseite'),
                  onPressed: () async {
                    final url = ep.links['dreifragezeichen'];
                    if (url != null && await canLaunch(url)) {
                      await launch(url);
                    }
                  },
                ),
              ),
            SizedBox(height: 12),
            Text('Notiz', style: Theme.of(context).textTheme.titleMedium),
            if (_editingNote) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Deine Notiz zur Folge...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.save, color: Colors.blue),
                    tooltip: 'Notiz speichern',
                    onPressed: () {
                      if (_noteController.text.trim().isNotEmpty) {
                        _saveNote();
                      }
                    },
                  ),
                ],
              ),
            ] else if ((ep.note ?? '').isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _editingNote = true;
                          _noteController.text = ep.note ?? '';
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ep.note ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Bearbeiten',
                        onPressed: () {
                          setState(() {
                            _editingNote = true;
                            _noteController.text = ep.note ?? '';
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Löschen',
                        onPressed: _deleteNote,
                      ),
                    ],
                  ),
                ],
              ),
            ],
            SizedBox(height: 8),
            Text('Bewertung', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: List.generate(5, (i) => IconButton(
                icon: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() => _rating = i + 1);
                  _saveState();
                },
              )),
            ),
            SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                setState(() => _listened = !_listened);
                _saveState();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _listened ? Icons.check_box : Icons.check_box_outline_blank,
                    color: _listened ? Colors.green : null,
                  ),
                  SizedBox(width: 8),
                  Text('Gehört'),
                ],
              ),
            ),
            SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseService().getHistory(ep.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox();
                final history = snapshot.data!;
                return ExpansionTile(
                  title: Text('Änderungsverlauf', style: Theme.of(context).textTheme.bodySmall),
                  initiallyExpanded: false,
                  children: [
                    ...history.take(5).map((h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16),
                      child: Text(
                        '${_formatHistoryDate(h['timestamp'])}: '
                        'Notiz: ${h['note'] ?? ''} | Bewertung: ${h['rating'] ?? ''} | Gehört: ${(h['listened'] ?? 0) == 1 ? 'Ja' : 'Nein'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    )),
                  ],
                );
              },
            ),
            SizedBox(height: 48),
            if (_saving) ...[
              SizedBox(height: 16),
              Center(child: CircularProgressIndicator()),
            ],
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
} 