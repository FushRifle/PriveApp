import 'package:clique/core/local_cache/hive_cache_keys.dart';
import 'package:clique/core/local_cache/local_cache_service.dart';

class CachedFeedService {
  static const String _postsCacheKey = 'cached_posts';
  static const String _storiesCacheKey = 'cached_stories';
  static const String _lastFetchKey = 'last_fetch_time';
  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<void> cachePosts(List<dynamic> posts) async {
    final box = LocalCacheService.box(HiveCacheKeys.feedBox);
    await box?.put(_postsCacheKey, posts);
    await box?.put(_lastFetchKey, DateTime.now().toIso8601String());
  }

  Future<List<dynamic>> getCachedPosts() async {
    final value =
        LocalCacheService.box(HiveCacheKeys.feedBox)?.get(_postsCacheKey);
    return value is List ? List<dynamic>.from(value) : [];
  }

  Future<void> cacheStories(List<dynamic> stories) async {
    await LocalCacheService.box(HiveCacheKeys.feedBox)
        ?.put(_storiesCacheKey, stories);
  }

  Future<List<dynamic>> getCachedStories() async {
    final value =
        LocalCacheService.box(HiveCacheKeys.feedBox)?.get(_storiesCacheKey);
    return value is List ? List<dynamic>.from(value) : [];
  }

  Future<bool> shouldRefetch() async {
    final lastFetch = LocalCacheService.box(HiveCacheKeys.feedBox)
        ?.get(_lastFetchKey)
        ?.toString();
    if (lastFetch == null) return true;

    final lastFetchTime = DateTime.tryParse(lastFetch);
    if (lastFetchTime == null) return true;
    final now = DateTime.now();
    return now.difference(lastFetchTime) > _cacheDuration;
  }

  Future<void> clearCache() async {
    final box = LocalCacheService.box(HiveCacheKeys.feedBox);
    await box?.deleteAll([
      _postsCacheKey,
      _storiesCacheKey,
      _lastFetchKey,
    ]);
  }
}
