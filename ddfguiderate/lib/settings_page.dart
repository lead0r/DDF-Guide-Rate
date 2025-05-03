import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StreamingProvider {
  spotify,
  appleMusic,
  bookbeat,
  amazonMusic,
  amazon,
  youtubeMusic,
}

const providerNames = {
  StreamingProvider.spotify: 'Spotify',
  StreamingProvider.appleMusic: 'Apple Music',
  StreamingProvider.bookbeat: 'Bookbeat',
  StreamingProvider.amazonMusic: 'Amazon Music',
  StreamingProvider.amazon: 'Amazon',
  StreamingProvider.youtubeMusic: 'YouTube Music',
};

const providerIcons = {
  StreamingProvider.spotify: Icons.music_note,
  StreamingProvider.appleMusic: Icons.apple,
  StreamingProvider.bookbeat: Icons.menu_book,
  StreamingProvider.amazonMusic: Icons.library_music,
  StreamingProvider.amazon: Icons.shopping_cart,
  StreamingProvider.youtubeMusic: Icons.ondemand_video,
};

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  StreamingProvider? _selectedProvider;

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('streaming_provider');
    setState(() {
      _selectedProvider = StreamingProvider.values.firstWhere(
        (e) => e.toString() == name,
        orElse: () => StreamingProvider.spotify,
      );
    });
  }

  Future<void> _saveProvider(StreamingProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('streaming_provider', provider.toString());
    setState(() {
      _selectedProvider = provider;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Einstellungen')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Bevorzugter Streaminganbieter'),
          ),
          ...StreamingProvider.values.map((provider) => RadioListTile<StreamingProvider>(
                value: provider,
                groupValue: _selectedProvider,
                onChanged: (value) {
                  if (value != null) _saveProvider(value);
                },
                title: Row(
                  children: [
                    Icon(providerIcons[provider]),
                    SizedBox(width: 12),
                    Text(providerNames[provider] ?? ''),
                  ],
                ),
              )),
        ],
      ),
    );
  }
} 