import 'package:flutter/material.dart';

class ChatWallpaper {
  final String id;
  final String name;
  final String category;
  final String? asset;
  final Color? color;

  const ChatWallpaper({
    required this.id,
    required this.name,
    required this.category,
    this.asset,
    this.color,
  });

  bool get isImage => asset != null;
  bool get isSolid => color != null && asset == null;
}

class ChatWallpapers {
  const ChatWallpapers._();

  static const images = <ChatWallpaper>[
    ChatWallpaper(id: 'default', name: 'Default', category: 'Images'),
    ChatWallpaper(
      id: 'palms',
      name: 'Palms',
      category: 'Images',
      asset: 'assets/wallpapers/palms.png',
    ),
    ChatWallpaper(
      id: 'modern',
      name: 'Modern',
      category: 'Images',
      asset: 'assets/wallpapers/modern.png',
    ),
    ChatWallpaper(
      id: 'sunset',
      name: 'Sunset',
      category: 'Images',
      asset: 'assets/wallpapers/sunset.png',
    ),
    ChatWallpaper(
      id: 'sky',
      name: 'Sky',
      category: 'Images',
      asset: 'assets/wallpapers/sky.png',
    ),
    ChatWallpaper(
      id: 'galaxy',
      name: 'Galaxy',
      category: 'Images',
      asset: 'assets/wallpapers/galaxy.png',
    ),
    ChatWallpaper(
      id: 'wallpaper_1',
      name: 'Image 1',
      category: 'Images',
      asset: 'assets/wallpapers/1.jpeg',
    ),
    ChatWallpaper(
      id: 'wallpaper_2',
      name: 'Image 2',
      category: 'Images',
      asset: 'assets/wallpapers/2.jpg',
    ),
    ChatWallpaper(
      id: 'wallpaper_3',
      name: 'Image 3',
      category: 'Images',
      asset: 'assets/wallpapers/3.jpeg',
    ),
    ChatWallpaper(
      id: 'wallpaper_4',
      name: 'Image 4',
      category: 'Images',
      asset: 'assets/wallpapers/4.jpg',
    ),
    ChatWallpaper(
      id: 'wallpaper_5',
      name: 'Image 5',
      category: 'Images',
      asset: 'assets/wallpapers/5.jpeg',
    ),
    ChatWallpaper(
      id: 'wallpaper_6',
      name: 'Image 6',
      category: 'Images',
      asset: 'assets/wallpapers/6.jpeg',
    ),
    ChatWallpaper(
      id: 'wallpaper_7',
      name: 'Image 7',
      category: 'Images',
      asset: 'assets/wallpapers/7.jpg',
    ),
    ChatWallpaper(
      id: 'wallpaper_8',
      name: 'Image 8',
      category: 'Images',
      asset: 'assets/wallpapers/8.jpeg',
    ),
    ChatWallpaper(
      id: 'wallpaper_9',
      name: 'Image 9',
      category: 'Images',
      asset: 'assets/wallpapers/9.jpeg',
    ),
    ChatWallpaper(
      id: 'wallpaper_10',
      name: 'Image 10',
      category: 'Images',
      asset: 'assets/wallpapers/10.jpeg',
    ),
  ];

  static const solidColors = <ChatWallpaper>[
    ChatWallpaper(
      id: 'solid_light',
      name: 'Light',
      category: 'Solid Colors',
      color: Color(0xFFF7F7F2),
    ),
    ChatWallpaper(
      id: 'solid_mint',
      name: 'Mint',
      category: 'Solid Colors',
      color: Color(0xFFE4F4EC),
    ),
    ChatWallpaper(
      id: 'solid_sky',
      name: 'Sky',
      category: 'Solid Colors',
      color: Color(0xFFE5F0FA),
    ),
    ChatWallpaper(
      id: 'solid_rose',
      name: 'Rose',
      category: 'Solid Colors',
      color: Color(0xFFF8E7EC),
    ),
    ChatWallpaper(
      id: 'solid_charcoal',
      name: 'Charcoal',
      category: 'Solid Colors',
      color: Color(0xFF171A21),
    ),
    ChatWallpaper(
      id: 'solid_ink',
      name: 'Ink',
      category: 'Solid Colors',
      color: Color(0xFF0F172A),
    ),
  ];

  static const illustrations = <ChatWallpaper>[
    ChatWallpaper(
        id: 'clip_art_1', name: 'Clip Art 1', category: 'Illustrations'),
    ChatWallpaper(
        id: 'clip_art_2', name: 'Clip Art 2', category: 'Illustrations'),
    ChatWallpaper(
        id: 'clip_art_3', name: 'Clip Art 3', category: 'Illustrations'),
  ];

  static const categories = <String, List<ChatWallpaper>>{
    'Images': images,
    'Solid Colors': solidColors,
    'Illustrations': illustrations,
  };

  static List<ChatWallpaper> get all => [
        ...images,
        ...solidColors,
        ...illustrations,
      ];

  static ChatWallpaper byId(String id) {
    return all.firstWhere(
      (wallpaper) => wallpaper.id == id,
      orElse: () => images.first,
    );
  }

  static String? assetFor(String id) => byId(id).asset;
  static Color? colorFor(String id) => byId(id).color;
}
