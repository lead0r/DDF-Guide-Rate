import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';

class BackupService {
  static Future<Map<String, dynamic>> getExportData() async {
    // Hole Daten aus SQLite
    final db = DatabaseService();
    return await db.exportAllToJson();
  }

  static Future<String> createAndShareBackupFile() async {
    try {
      final exportData = await getExportData();
      final jsonString = json.encode(exportData);

      // Temporäre Datei erstellen
      final directory = await getTemporaryDirectory();
      final backupFilePath = '${directory.path}/ddfguide_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(backupFilePath);
      await file.writeAsString(jsonString);

      // Datei teilen
      await Share.shareXFiles(
        [XFile(backupFilePath)],
        subject: 'Drei ??? Guide Backup',
      );

      return 'Backup erfolgreich erstellt und geteilt';
    } catch (e) {
      return 'Fehler beim Erstellen des Backups: $e';
    }
  }

  static Future<String> importDataFromClipboard(BuildContext context) async {
    try {
      // Daten aus der Zwischenablage lesen
      ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

      if (clipboardData == null || clipboardData.text == null || clipboardData.text!.isEmpty) {
        return 'Keine Daten in der Zwischenablage gefunden';
      }

      try {
        // Versuche, die Daten als JSON zu parsen
        final Map<String, dynamic> importData = json.decode(clipboardData.text!);

        // Datenvalidierung
        if (!importData.containsKey('episode_state') || !importData.containsKey('episode_state_history')) {
          return 'Ungültiges Backup-Format in der Zwischenablage';
        }

        // Bestätigungsdialog anzeigen
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Backup importieren'),
            content: Text(
                'Möchtest du wirklich dieses Backup importieren? '
                    'Dies wird alle deine aktuellen Notizen, Bewertungen und Hörstatus überschreiben.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Importieren'),
              ),
            ],
          ),
        );

        if (confirm != true) {
          return 'Import abgebrochen';
        }

        // In SQLite speichern
        final db = DatabaseService();
        await db.importAllFromJson(importData);

        // Nach dem Import: Spezial-Null-States bereinigen
        await db.removeNullSpezialStates();

        return 'Backup erfolgreich importiert';
      } catch (e) {
        return 'Fehler beim Parsen der Daten: $e';
      }
    } catch (e) {
      return 'Fehler beim Importieren des Backups: $e';
    }
  }

  static Future<void> showBackupDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Backup-Optionen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.upload),
              title: Text('Backup exportieren'),
              subtitle: Text('Notizen, Bewertungen und Hörstatus exportieren'),
              onTap: () async {
                Navigator.pop(context);
                final message = await createAndShareBackupFile();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.download),
              title: Text('Backup importieren'),
              subtitle: Text('Aus Zwischenablage importieren (kopiere vorher die JSON-Datei)'),
              onTap: () async {
                Navigator.pop(context);
                final message = await importDataFromClipboard(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              },
            ),
          ],
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
}