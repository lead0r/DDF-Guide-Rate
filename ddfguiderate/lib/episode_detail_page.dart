import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'episode.dart';
import 'database_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.episode.note ?? '');
    _rating = widget.episode.rating;
    _listened = widget.episode.listened;
  }

  Future<void> _saveState() async {
    setState(() => _saving = true);
    await DatabaseService().updateEpisodeState(
      widget.episode.id,
      note: _noteController.text,
      rating: _rating,
      listened: _listened,
    );
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gespeichert!')),
    );
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

  @override
  Widget build(BuildContext context) {
    final ep = widget.episode;
    return Scaffold(
      appBar: AppBar(
        title: Text('${ep.nummer} / ${ep.titel}'),
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
                  child: Image.network(ep.coverUrl!, height: 200),
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
                  Text(ep.veroeffentlichungsdatum!),
                ],
              ),
            SizedBox(height: 16),
            Text(ep.beschreibung, style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            if (ep.sprechrollen != null && ep.sprechrollen!.isNotEmpty) ...[
              Text('Sprecher:', style: Theme.of(context).textTheme.titleMedium),
              ...ep.sprechrollen!.map<Widget>((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text('${s['rolle'] ?? ''}: ${s['sprecher'] ?? ''}'),
              )),
              SizedBox(height: 16),
            ],
            SizedBox(height: 24),
            if ((ep.links['dreifragezeichen'] != null) && (ep.serieTyp == 'Serie' || ep.serieTyp == 'Kids'))
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
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
            Text('Notiz', style: Theme.of(context).textTheme.titleMedium),
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
                    onChanged: (_) => _saveState(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  tooltip: 'Notiz löschen',
                  onPressed: () {
                    setState(() {
                      _noteController.clear();
                    });
                    _saveState();
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseService().getHistory(ep.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox();
                final history = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Änderungsverlauf:', style: Theme.of(context).textTheme.bodySmall),
                    ...history.take(5).map((h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        '${DateTime.fromMillisecondsSinceEpoch(h['timestamp'] ?? 0).toLocal().toString().substring(0, 16)}: '
                        'Notiz: ${h['note'] ?? ''} | Bewertung: ${h['rating'] ?? ''} | Gehört: ${(h['listened'] ?? 0) == 1 ? 'Ja' : 'Nein'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    )),
                  ],
                );
              },
            ),
            SizedBox(height: 16),
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
            Row(
              children: [
                Checkbox(
                  value: _listened,
                  onChanged: (val) {
                    setState(() => _listened = val ?? false);
                    _saveState();
                  },
                ),
                Text('Gehört'),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.play_arrow),
              label: Text('Streaming öffnen'),
              onPressed: _openStreaming,
            ),
            if (_saving) ...[
              SizedBox(height: 16),
              Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
} 