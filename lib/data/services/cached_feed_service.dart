import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class CachedFeedService {
  static const String _postsCacheKey = 'cached_posts';
  static const String _storiesCacheKey = 'cached_stories';
  static const String _lastFetchKey = 'last_fetch_time';
  static const Duration _cacheDuration = Duration(minutes: 5);

  // In-memory cache for faster access
  List<dynamic>? _cachedPosts;
  List<dynamic>? _cachedStories;
  DateTime? _lastFetchTime;
  bool _isInitialized = false;

  // Debounce for cache writes
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  SharedPreferences? _prefs;

  // Singleton pattern
  static final CachedFeedService _instance = CachedFeedService._internal();
  factory CachedFeedService() => _instance;
  CachedFeedService._internal();

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    final prefs = await _getPrefs();

    // Load from disk in background
    unawaited(_loadFromDisk(prefs));
    _isInitialized = true;
  }

  Future<void> _loadFromDisk(SharedPreferences prefs) async {
    try {
      // Load posts
      final postsJson = prefs.getString(_postsCacheKey);
      if (postsJson != null) {
        _cachedPosts = jsonDecode(postsJson);
      }

      // Load stories
      final storiesJson = prefs.getString(_storiesCacheKey);
      if (storiesJson != null) {
        _cachedStories = jsonDecode(storiesJson);
      }

      // Load last fetch time
      final lastFetchStr = prefs.getString(_lastFetchKey);
      if (lastFetchStr != null) {
        _lastFetchTime = DateTime.tryParse(lastFetchStr);
      }
    } catch (e) {
      // Silent fail - will fetch from network
      _cachedPosts = [];
      _cachedStories = [];
    }
  }

  Future<void> cachePosts(List<dynamic> posts) async {
    await _ensureInitialized();

    // Update memory cache immediately
    _cachedPosts = posts;

    // Debounce disk write
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        final prefs = await _getPrefs();
        await prefs.setString(_postsCacheKey, jsonEncode(posts));
        await prefs.setString(_lastFetchKey, DateTime.now().toIso8601String());
        _lastFetchTime = DateTime.now();
      } catch (e) {
        // Silent fail
      }
    });
  }

  Future<List<dynamic>> getCachedPosts() async {
    await _ensureInitialized();

    // Return from memory cache if available
    if (_cachedPosts != null) {
      return _cachedPosts!;
    }

    // Fallback to disk
    try {
      final prefs = await _getPrefs();
      final postsJson = prefs.getString(_postsCacheKey);
      if (postsJson != null) {
        _cachedPosts = jsonDecode(postsJson);
        return _cachedPosts!;
      }
    } catch (e) {
      // Silent fail
    }

    return [];
  }

  Future<void> cacheStories(List<dynamic> stories) async {
    await _ensureInitialized();

    // Update memory cache immediately
    _cachedStories = stories;

    // Debounce disk write
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        final prefs = await _getPrefs();
        await prefs.setString(_storiesCacheKey, jsonEncode(stories));
      } catch (e) {
        // Silent fail
      }
    });
  }

  Future<List<dynamic>> getCachedStories() async {
    await _ensureInitialized();

    // Return from memory cache if available
    if (_cachedStories != null) {
      return _cachedStories!;
    }

    // Fallback to disk
    try {
      final prefs = await _getPrefs();
      final storiesJson = prefs.getString(_storiesCacheKey);
      if (storiesJson != null) {
        _cachedStories = jsonDecode(storiesJson);
        return _cachedStories!;
      }
    } catch (e) {
      // Silent fail
    }

    return [];
  }

  Future<bool> shouldRefetch() async {
    await _ensureInitialized();

    if (_lastFetchTime == null) {
      // Try to load from disk
      try {
        final prefs = await _getPrefs();
        final lastFetchStr = prefs.getString(_lastFetchKey);
        if (lastFetchStr != null) {
          _lastFetchTime = DateTime.tryParse(lastFetchStr);
        }
      } catch (e) {
        // Silent fail
      }
    }

    if (_lastFetchTime == null) return true;

    return DateTime.now().difference(_lastFetchTime!) > _cacheDuration;
  }

  Future<void> clearCache() async {
    // Clear memory cache
    _cachedPosts = null;
    _cachedStories = null;
    _lastFetchTime = null;

    // Cancel any pending writes
    _debounceTimer?.cancel();

    // Clear disk cache
    try {
      final prefs = await _getPrefs();
      await Future.wait([
        prefs.remove(_postsCacheKey),
        prefs.remove(_storiesCacheKey),
        prefs.remove(_lastFetchKey),
      ]);
    } catch (e) {
      // Silent fail
    }
  }

  // Get cache age in minutes
  Future<int?> getCacheAgeMinutes() async {
    await _ensureInitialized();

    if (_lastFetchTime == null) return null;
    return DateTime.now().difference(_lastFetchTime!).inMinutes;
  }

  // Check if cache is stale
  Future<bool> isCacheStale() async {
    final age = await getCacheAgeMinutes();
    if (age == null) return true;
    return age > _cacheDuration.inMinutes;
  }

  // Get cache info for debugging
  Future<Map<String, dynamic>> getCacheInfo() async {
    await _ensureInitialized();

    return {
      'hasPosts': _cachedPosts != null && _cachedPosts!.isNotEmpty,
      'hasStories': _cachedStories != null && _cachedStories!.isNotEmpty,
      'lastFetchTime': _lastFetchTime?.toIso8601String(),
      'isStale': await isCacheStale(),
      'cacheAgeMinutes': await getCacheAgeMinutes(),
    };
  }
}
