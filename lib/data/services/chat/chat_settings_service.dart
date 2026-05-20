import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChatSettingsService {
  static final ChatSettingsService _instance = ChatSettingsService._internal();
  factory ChatSettingsService() => _instance;
  ChatSettingsService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings: settings);
  }

  // Play notification sound using local notifications
  Future<void> playNotificationSound(String soundName) async {
    if (soundName == 'default' || soundName.isEmpty) return;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('sounds_$soundName'),
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: '$soundName.caf',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // Get wallpaper asset path
  String getWallpaperPath(String wallpaperName) {
    if (wallpaperName == 'default') return '';
    return 'assets/wallpapers/$wallpaperName.png';
  }

  // Pre-cache wallpapers
  Future<void> precacheWallpapers(BuildContext context) {
    final wallpapers = ['palms', 'sunset', 'sky', 'galaxy', 'modern'];
    for (final wp in wallpapers) {
      precacheImage(AssetImage('assets/wallpapers/$wp.png'), context);
    }
    return Future.value();
  }
}
