import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'new_episodes_channel',
      'New Episodes',
      channelDescription: 'Notifications for new episodes',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}

void backgroundFetchHeadlessTask(HeadlessTask task) async {
  await checkNewEpisodes();
  BackgroundFetch.finish(task.taskId);
}

Future<void> checkNewEpisodes() async {
  try {
    final response = await http.get(Uri.parse('https://api.die-drei-fragezeichen.de/episodes'));
    if (response.statusCode == 200) {
      final List<dynamic> episodes = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('lastEpisodeCheck') ?? 0;
      
      final newEpisodes = episodes.where((ep) {
        final releaseDate = DateTime.parse(ep['release_date']);
        return releaseDate.millisecondsSinceEpoch > lastCheck;
      }).toList();

      if (newEpisodes.isNotEmpty) {
        await NotificationService.showNotification(
          title: 'Neue Folge verfügbar!',
          body: '${newEpisodes.length} neue Folge(n) sind erschienen.',
        );
      }

      await prefs.setInt('lastEpisodeCheck', DateTime.now().millisecondsSinceEpoch);
    }
  } catch (e) {
    print('Error checking for new episodes: $e');
  }
} 