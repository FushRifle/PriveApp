import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CachedFeedService {
  static const String _postsCacheKey = 'cached_posts';
  static const String _storiesCacheKey = 'cached_stories';
  static const String _lastFetchKey = 'last_fetch_time';
  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<void> cachePosts(List<dynamic> posts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_postsCacheKey, jsonEncode(posts));
    await prefs.setString(_lastFetchKey, DateTime.now().toIso8601String());
  }

  Future<List<dynamic>> getCachedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? postsJson = prefs.getString(_postsCacheKey);
    if (postsJson != null) {
      return jsonDecode(postsJson);
    }
    return [];
  }

  Future<void> cacheStories(List<dynamic> stories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storiesCacheKey, jsonEncode(stories));
  }

  Future<List<dynamic>> getCachedStories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storiesJson = prefs.getString(_storiesCacheKey);
    if (storiesJson != null) {
      return jsonDecode(storiesJson);
    }
    return [];
  }

  Future<bool> shouldRefetch() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastFetch = prefs.getString(_lastFetchKey);
    if (lastFetch == null) return true;

    final lastFetchTime = DateTime.parse(lastFetch);
    final now = DateTime.now();
    return now.difference(lastFetchTime) > _cacheDuration;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_postsCacheKey);
    await prefs.remove(_storiesCacheKey);
    await prefs.remove(_lastFetchKey);
  }
}
