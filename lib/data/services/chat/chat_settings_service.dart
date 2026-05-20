import 'package:flutter/material.dart';

class ChatSettingsService {
  static final ChatSettingsService _instance = ChatSettingsService._internal();
  factory ChatSettingsService() => _instance;
  ChatSettingsService._internal();

  // Play notification sound - disabled for now
  void playNotificationSound(String soundName) {
    // TODO: Implement sound playback later
    return;
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
