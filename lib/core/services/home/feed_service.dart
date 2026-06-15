import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../clients/api_service.dart';
import '../../models/feeds_models.dart';
import '../../models/poll_model.dart';
import '../cache/feed_cache_service.dart';

class FeedService {
  final ApiService _api = ApiService();
  final FeedCacheService _feedCacheService = FeedCacheService();

  void setAuthToken(String token) {
    _api.setAuthToken(token);
  }

  void clearAuthToken() {
    _api.clearAuthToken();
  }

  Future<PostsResponse> getPosts({
    int page = 1,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedPage = _feedCacheService.readFeedPage(page);
      if (cachedPage != null && cachedPage.posts.isNotEmpty) {
        return cachedPage;
      }

      if (page == 1) {
        final cachedLatest = _feedCacheService.readLatestFeed();
        if (cachedLatest != null && cachedLatest.posts.isNotEmpty) {
          return cachedLatest;
        }
      }
    }

    try {
      final response = await _getPostsWithFallback(
        page: page,
        forceRefresh: forceRefresh,
      );

      debugPrint('Posts response status: ${response.statusCode}');

      final postsResponse = _parsePostsResponse(response.data, page);
      if (forceRefresh && page == 1) {
        await _feedCacheService.clearFeedPages();
      }
      await _feedCacheService.saveFeedPage(postsResponse);
      return postsResponse;
    } on DioException catch (e) {
      debugPrint('Get posts error: ${e.response?.data}');
      final cachedPage = _feedCacheService.readFeedPage(page);
      if (cachedPage != null && cachedPage.posts.isNotEmpty) {
        return cachedPage;
      }

      if (page == 1) {
        final cachedLatest = _feedCacheService.readLatestFeed();
        if (cachedLatest != null && cachedLatest.posts.isNotEmpty) {
          return cachedLatest;
        }
      }
      throw _readError(e.response?.data, 'Failed to get posts');
    }
  }

  Future<Response> _getPostsWithFallback({
    required int page,
    required bool forceRefresh,
  }) async {
    try {
      return await _api.get(
        '/api/feed/posts',
        queryParameters: {'page': page},
        forceRefresh: forceRefresh,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        return await _api.get(
          '/api/posts',
          queryParameters: {'page': page},
          forceRefresh: forceRefresh,
        );
      }
      rethrow;
    }
  }

  PostsResponse _parsePostsResponse(dynamic data, int page) {
    if (data is Map) {
      return PostsResponse.fromJson(Map<String, dynamic>.from(data));
    }

    if (data is List) {
      final posts = data.map((json) => FeedPost.fromJson(json)).toList();
      return PostsResponse(
        posts: posts,
        hasMore: posts.length == 10,
        page: page,
      );
    }

    return PostsResponse(posts: [], hasMore: false, page: page);
  }

  PostsResponse? getCachedPosts() {
    return _feedCacheService.readLatestFeed();
  }

  Future<FeedPost?> findPostById(int postId) async {
    if (postId <= 0) {
      return null;
    }

    final cached = getCachedPosts();
    final cachedMatch =
        cached?.posts.where((post) => post.id == postId).toList();
    if (cachedMatch != null && cachedMatch.isNotEmpty) {
      return cachedMatch.first;
    }

    for (var page = 1; page <= 20; page++) {
      final response = await getPosts(
        page: page,
        forceRefresh: page == 1,
      );

      final match = response.posts.where((post) => post.id == postId).toList();
      if (match.isNotEmpty) {
        return match.first;
      }

      if (!response.hasMore) {
        break;
      }
    }

    return null;
  }

  Future<FeedPost?> getPostById(int postId) async {
    if (postId <= 0) {
      return null;
    }

    try {
      final response = await _api.get('/api/feed/posts/$postId');

      if (response.data is Map) {
        return FeedPost.fromJson(_readMap(response.data));
      }

      return null;
    } on DioException catch (e) {
      debugPrint('Get post by id error: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        try {
          final fallback = await _api.get('/api/posts/$postId');
          if (fallback.data is Map) {
            return FeedPost.fromJson(_readMap(fallback.data));
          }
        } on DioException catch (fallbackError) {
          debugPrint('Get post by id fallback error: ${fallbackError.response?.data}');
        }
      }

      final cached = getCachedPosts();
      final cachedMatch = cached?.posts
          .where((post) => post.id == postId)
          .toList();
      if (cachedMatch != null && cachedMatch.isNotEmpty) {
        return cachedMatch.first;
      }
      return null;
    }
  }

  Future<FeedPoll?> getPostPoll(
    int postId, {
    bool forceRefresh = false,
  }) async {
    if (postId <= 0) {
      return null;
    }

    try {
      final response = await _api.get(
        '/api/feed/posts/$postId/poll',
        forceRefresh: forceRefresh,
      );

      if (response.data is Map) {
        return FeedPoll.fromJson(_readMap(response.data));
      }

      return null;
    } on DioException catch (e) {
      debugPrint('Get post poll error: ${e.response?.data}');
      return null;
    }
  }

  UserMediaResponse? getCachedUserMedia(int userId, String? type) {
    return _feedCacheService.readUserMedia(userId, type);
  }

  // Create post
  Future<FeedPost> createPost({
    required String content,
    List<Map<String, dynamic>>? attachments,
    String postType = 'standard',
    bool isAnonymous = false,
    String? anonymousCategory,
    List<String>? pollOptions,
    int? pollExpirationHours,
  }) async {
    try {
      final data = <String, dynamic>{
        'content': content,
        'postType': postType,
        'isAnonymous': isAnonymous,
      };

      if (anonymousCategory != null && anonymousCategory.trim().isNotEmpty) {
        data['anonymousCategory'] = anonymousCategory.trim();
      }

      final mentions = _extractMentions(content);
      if (mentions.isNotEmpty) {
        data['mentions'] = mentions;
      }
      if (attachments != null && attachments.isNotEmpty) {
        data['attachments'] = attachments;
      }
      if (pollOptions != null && pollOptions.isNotEmpty) {
        data['pollOptions'] = pollOptions;
      }
      if (pollExpirationHours != null && pollExpirationHours > 0) {
        data['pollExpirationHours'] = pollExpirationHours;
      }

      final response = await _postCreateWithFallback(
        data,
        postType: postType,
      );
      _invalidateFeedCaches();
      return FeedPost.fromJson(_readPostMap(response.data));
    } on DioException catch (e) {
      debugPrint('Create post error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to create post';
    }
  }

  Future<Response> _postCreateWithFallback(
    Map<String, dynamic> data, {
    required String postType,
  }) async {
    final normalizedPostType = postType.trim().toLowerCase();
    final isAiGeneratedPost =
        normalizedPostType == 'daily_prompt' || normalizedPostType == 'prompt';

    final preferredEndpoints = isAiGeneratedPost
        ? const ['/api/feed/posts', '/api/posts']
        : const ['/api/posts', '/api/feed/posts'];

    DioException? lastError;

    for (final endpoint in preferredEndpoints) {
      try {
        return await _api.post(endpoint, data: data);
      } on DioException catch (e) {
        lastError = e;
        if (e.response?.statusCode != 404) {
          if (endpoint == preferredEndpoints.last) {
            rethrow;
          }
          continue;
        }
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    throw StateError('Unable to create post');
  }

  Future<void> votePoll({
    required int postId,
    required int pollId,
    required List<int> optionIds,
  }) async {
    try {
      await _api.post(
        '/api/feed/polls/$pollId/vote',
        data: {'optionIds': optionIds},
      );
      _invalidatePostCaches(postId);
      _api.removeCacheByPath('/api/feed/posts/$postId/poll');
    } on DioException catch (e) {
      debugPrint('Vote poll error: ${e.response?.data}');
      throw e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to vote on poll';
    }
  }

  // Like post
  Future<Map<String, dynamic>> likePost(int postId) async {
    try {
      final response = await _api.post('/api/feed/posts/$postId/like');
      _invalidatePostCaches(postId);
      return response.data;
    } on DioException catch (e) {
      debugPrint('Like post error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to like post';
    }
  }

  // Unlike post
  Future<Map<String, dynamic>> unlikePost(int postId) async {
    try {
      final response = await _api.delete('/api/feed/posts/$postId/like');
      _invalidatePostCaches(postId);
      return response.data;
    } on DioException catch (e) {
      debugPrint('Unlike post error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to unlike post';
    }
  }

  Future<Map<String, dynamic>> savePost(int postId) async {
    try {
      final response = await _api.post('/api/feed/posts/$postId/save');
      _invalidatePostCaches(postId);
      return _readMap(response.data);
    } on DioException catch (e) {
      debugPrint('Save post error: ${e.response?.data}');
      throw e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to save post';
    }
  }

  Future<Map<String, dynamic>> unsavePost(int postId) async {
    try {
      final response = await _api.delete('/api/feed/posts/$postId/save');
      _invalidatePostCaches(postId);
      return _readMap(response.data);
    } on DioException catch (e) {
      debugPrint('Unsave post error: ${e.response?.data}');
      throw e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to unsave post';
    }
  }

  Future<Map<String, dynamic>> sharePost(int postId) async {
    try {
      final response = await _api.post('/api/feed/posts/$postId/share');
      _invalidatePostCaches(postId);
      return _readMap(response.data);
    } on DioException catch (e) {
      debugPrint('Share post error: ${e.response?.data}');
      throw e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to share post';
    }
  }

  Future<FeedPost> repost({
    required int postId,
    String content = '',
  }) async {
    try {
      final response = await _api.post(
        '/api/feed/posts/$postId/repost',
        data: {'content': content},
      );
      _invalidateFeedCaches();
      return FeedPost.fromJson(_readPostMap(response.data));
    } on DioException catch (e) {
      debugPrint('Repost error: ${e.response?.data}');
      throw e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to repost';
    }
  }

  Future<PostsResponse> getPostsByHashtag({
    required String tag,
    int page = 1,
  }) async {
    try {
      final cleanTag = tag.replaceFirst('#', '').trim().toLowerCase();
      final response = await _api.get(
        '/api/feed/hashtags/$cleanTag/posts',
        queryParameters: {'page': page},
      );

      if (response.data is List) {
        final posts = (response.data as List)
            .map((json) => FeedPost.fromJson(json))
            .toList();
        return PostsResponse(
          posts: posts,
          hasMore: posts.length == 10,
          page: page,
        );
      }

      if (response.data is Map) {
        return PostsResponse.fromJson(response.data);
      }

      return PostsResponse(posts: [], hasMore: false, page: page);
    } on DioException catch (e) {
      debugPrint('Hashtag posts error: ${e.response?.data}');
      throw e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to get hashtag posts';
    }
  }

  // Get post comments - returns typed List<Comment>
  Future<CommentsResponse> getComments(
    int postId, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _api.get(
        '/api/feed/posts/$postId/comments',
        queryParameters: {'page': page},
        forceRefresh: forceRefresh,
      );

      if (response.data is List) {
        final comments = (response.data as List)
            .map((json) => Comment.fromJson(json))
            .toList();
        final commentsResponse = CommentsResponse(
          comments: comments,
          hasMore: comments.length == 20,
          page: page,
        );
        if (page == 1) {
          await _feedCacheService.saveComments(postId, commentsResponse);
        }
        return commentsResponse;
      }

      if (response.data is Map) {
        final commentsResponse = CommentsResponse.fromJson(response.data);
        if (page == 1) {
          await _feedCacheService.saveComments(postId, commentsResponse);
        }
        return commentsResponse;
      }

      return CommentsResponse(comments: [], hasMore: false, page: page);
    } on DioException catch (e) {
      debugPrint('Get comments error: ${e.response?.data}');
      if (page == 1) {
        final cached = _feedCacheService.readComments(postId);
        if (cached != null && cached.comments.isNotEmpty) {
          return cached;
        }
      }
      throw e.response?.data['message'] ?? 'Failed to get comments';
    }
  }

  // Add comment - returns typed Comment
  Future<Comment> addComment({
    required int postId,
    required String content,
    String? audioUrl,
    int? duration,
    int? replyToCommentId,
  }) async {
    try {
      final data = <String, dynamic>{
        'content': content,
      };
      if (audioUrl != null && audioUrl.isNotEmpty) {
        data['audioUrl'] = audioUrl;
        data['duration'] = duration ?? 0;
      }
      if (replyToCommentId != null) {
        data['replyToCommentId'] = replyToCommentId;
      }

      final response = await _api.post(
        '/api/feed/posts/$postId/comments',
        data: data,
      );
      _invalidatePostCaches(postId);
      return Comment.fromJson(_readCommentMap(response.data));
    } on DioException catch (e) {
      debugPrint('Add comment error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to add comment';
    }
  }

  Future<Comment> likeComment({
    required int postId,
    required int commentId,
  }) async {
    try {
      final response = await _api.post(
        '/api/feed/posts/$postId/comments/$commentId/like',
      );
      _invalidatePostCaches(postId);
      return Comment.fromJson(_readCommentMap(response.data));
    } on DioException catch (e) {
      debugPrint('Like comment error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to like comment';
    }
  }

  Future<Comment> dislikeComment({
    required int postId,
    required int commentId,
  }) async {
    try {
      final response = await _api.post(
        '/api/feed/posts/$postId/comments/$commentId/dislike',
      );
      _invalidatePostCaches(postId);
      return Comment.fromJson(_readCommentMap(response.data));
    } on DioException catch (e) {
      debugPrint('Dislike comment error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to dislike comment';
    }
  }

  Future<void> deletePost(int postId) async {
    try {
      await _api.delete('/api/feed/posts/$postId');
      _invalidateFeedCaches();
    } on DioException catch (e) {
      debugPrint('Delete post error: ${e.response?.data}');
      throw _readError(e.response?.data, 'Failed to delete post');
    }
  }

  Future<FeedPost> updatePost({
    required int postId,
    required String content,
  }) async {
    try {
      final response = await _api.put(
        '/api/feed/posts/$postId',
        data: {'content': content},
      );

      if (response.data is Map<String, dynamic>) {
        _invalidatePostCaches(postId);
        return FeedPost.fromJson(_readPostMap(response.data));
      }

      if (response.data is Map) {
        _invalidatePostCaches(postId);
        return FeedPost.fromJson(_readPostMap(response.data));
      }

      throw 'Invalid update response';
    } on DioException catch (e) {
      debugPrint('Update post error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to update post';
    }
  }

  // Get user media (for profile gallery)
  Future<UserMediaResponse> getUserMedia({
    required int userId,
    int page = 1,
    String? type,
    bool forceRefresh = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _api.get(
        '/api/feed/users/$userId/media',
        queryParameters: queryParams,
        forceRefresh: forceRefresh,
      );

      debugPrint('User media response status: ${response.statusCode}');

      if (response.data is Map) {
        final mediaResponse = UserMediaResponse.fromJson(response.data);
        if (page == 1) {
          await _feedCacheService.saveUserMedia(userId, type, mediaResponse);
        }
        return mediaResponse;
      }

      if (response.data is List) {
        final media = (response.data as List)
            .map((json) => UserMedia.fromJson(json))
            .toList();
        final mediaResponse = UserMediaResponse(
          media: media,
          hasMore: media.length == 10,
          page: page,
        );
        if (page == 1) {
          await _feedCacheService.saveUserMedia(userId, type, mediaResponse);
        }
        return mediaResponse;
      }

      return UserMediaResponse(media: [], hasMore: false, page: page);
    } on DioException catch (e) {
      debugPrint('Get user media error: ${e.response?.data}');
      if (page == 1) {
        final cached = _feedCacheService.readUserMedia(userId, type);
        if (cached != null && cached.media.isNotEmpty) {
          return cached;
        }
      }
      throw e.response?.data['message'] ?? 'Failed to get user media';
    }
  }

  // Get user media count
  Future<int> getUserMediaCount({
    required int userId,
    String? type,
  }) async {
    try {
      final response = await _api.get(
        '/api/feed/users/$userId/media',
        queryParameters: {'page': 1, 'limit': 1},
      );

      if (response.data is Map && response.data['total'] != null) {
        return response.data['total'];
      }

      if (response.data is List) {
        return (response.data as List).length;
      }

      return 0;
    } on DioException catch (e) {
      debugPrint('Get user media count error: ${e.response?.data}');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getTrendingHashtags({
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        '/api/feed/hashtags',
        queryParameters: {'limit': limit},
      );

      final data = response.data is Map
          ? response.data['data'] ?? response.data['hashtags'] ?? response.data
          : response.data;

      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return const [];
    } on DioException catch (e) {
      debugPrint('Get trending hashtags error: ${e.response?.data}');
      return const [];
    }
  }

  Map<String, dynamic> _readMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  Map<String, dynamic> _readPostMap(dynamic data) {
    final map = _readMap(data);

    final post = map['post'] ?? map['data'] ?? map['item'];
    if (post is Map) {
      return Map<String, dynamic>.from(post);
    }

    return map;
  }

  Map<String, dynamic> _readCommentMap(dynamic data) {
    final map = _readMap(data);
    final comment = map['comment'] ?? map['data'] ?? map['item'];
    if (comment is Map) {
      return Map<String, dynamic>.from(comment);
    }
    return map;
  }

  String _readError(dynamic data, String fallback) {
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return fallback;
  }

  void _invalidatePostCaches(int postId) {
    _api.removeCacheByPath('/api/feed/posts');
    _api.removeCacheByPath('/api/feed/posts/$postId');
    _api.removeCacheByPath('/api/feed/posts/$postId/comments');
    _api.removeCacheByPath('/api/feed/users');
    unawaited(_feedCacheService.clearFeedPages());
  }

  void _invalidateFeedCaches() {
    _api.removeCacheByPath('/api/feed/posts');
    _api.removeCacheByPath('/api/feed/users');
    unawaited(_feedCacheService.clearFeedPages());
  }

  List<String> _extractMentions(String text) {
    final seen = <String>{};
    return RegExp(r'(?<![A-Za-z0-9_])@([A-Za-z0-9_]+)')
        .allMatches(text)
        .map((match) => match.group(1)!.toLowerCase())
        .where(seen.add)
        .toList();
  }
}
