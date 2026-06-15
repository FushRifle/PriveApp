import 'package:clique/core/local_cache/hive_cache_keys.dart';
import 'package:clique/core/local_cache/local_cache_service.dart';
import 'package:clique/core/models/feeds_models.dart';

class FeedCacheService {
  Future<void> saveLatestFeed(PostsResponse response) async {
    await saveFeedPage(response);
  }

  Future<void> saveFeedPage(PostsResponse response) async {
    final feedBox = LocalCacheService.box(HiveCacheKeys.feedBox);
    final metaBox = LocalCacheService.box(HiveCacheKeys.metaBox);

    if (feedBox == null) return;

    final pageKey = _feedPageKey(response.page);
    final payload = {
      'posts': response.posts.map((post) => post.toJson()).toList(),
      'hasMore': response.hasMore,
      'page': response.page,
    };

    await feedBox.put(pageKey, payload);

    if (response.page == 1) {
      await feedBox.put(HiveCacheKeys.latestFeed, payload);
    }

    if (response.page == 1 && metaBox != null) {
      await metaBox.put(HiveCacheKeys.latestFeedMeta, {
        'cachedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  PostsResponse? readFeedPage(int page) {
    final feedBox = LocalCacheService.box(HiveCacheKeys.feedBox);
    final raw = feedBox?.get(_feedPageKey(page));

    if (raw is! Map) return null;

    try {
      final data = Map<String, dynamic>.from(raw);
      return PostsResponse.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  PostsResponse? readLatestFeed() {
    return readFeedPage(1);
  }

  Future<void> clearFeedPages() async {
    final feedBox = LocalCacheService.box(HiveCacheKeys.feedBox);
    final metaBox = LocalCacheService.box(HiveCacheKeys.metaBox);

    if (feedBox == null) return;

    final keysToRemove = feedBox.keys
        .whereType<String>()
        .where(
          (key) =>
              key == HiveCacheKeys.latestFeed ||
              key.startsWith('${HiveCacheKeys.feedPagePrefix}_'),
        )
        .toList();

    for (final key in keysToRemove) {
      await feedBox.delete(key);
    }

    if (metaBox != null) {
      await metaBox.delete(HiveCacheKeys.latestFeedMeta);
    }
  }

  Future<void> saveComments(int postId, CommentsResponse response) async {
    final feedBox = LocalCacheService.box(HiveCacheKeys.feedBox);
    if (feedBox == null) return;

    await feedBox.put(_postCommentsKey(postId), {
      'comments': response.comments.map((comment) => comment.toJson()).toList(),
      'hasMore': response.hasMore,
      'page': response.page,
    });
  }

  CommentsResponse? readComments(int postId) {
    final feedBox = LocalCacheService.box(HiveCacheKeys.feedBox);
    final raw = feedBox?.get(_postCommentsKey(postId));

    if (raw is! Map) return null;

    try {
      final data = Map<String, dynamic>.from(raw);
      return CommentsResponse.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserMedia(
    int userId,
    String? type,
    UserMediaResponse response,
  ) async {
    final feedBox = LocalCacheService.box(HiveCacheKeys.feedBox);
    if (feedBox == null) return;

    await feedBox.put(_userMediaKey(userId, type), {
      'media': response.media.map((media) => media.toJson()).toList(),
      'hasMore': response.hasMore,
      'page': response.page,
      if (response.total != null) 'total': response.total,
    });
  }

  UserMediaResponse? readUserMedia(int userId, String? type) {
    final feedBox = LocalCacheService.box(HiveCacheKeys.feedBox);
    final raw = feedBox?.get(_userMediaKey(userId, type));

    if (raw is! Map) return null;

    try {
      final data = Map<String, dynamic>.from(raw);
      return UserMediaResponse.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  String _postCommentsKey(int postId) {
    return '${HiveCacheKeys.postCommentsPrefix}_$postId';
  }

  String _feedPageKey(int page) {
    return '${HiveCacheKeys.feedPagePrefix}_$page';
  }

  String _userMediaKey(int userId, String? type) {
    return [
      HiveCacheKeys.userMediaPrefix,
      userId,
      type?.trim().isNotEmpty == true ? type!.trim() : 'all',
    ].join('_');
  }
}
