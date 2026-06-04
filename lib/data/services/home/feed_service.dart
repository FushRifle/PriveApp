import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api_service.dart';
import '../../models/feeds_models.dart';
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
    try {
      final response = await _api.get(
        '/api/feed/posts',
        queryParameters: {'page': page},
        forceRefresh: forceRefresh,
      );

      debugPrint('Posts response status: ${response.statusCode}');

      if (response.data is Map) {
        final postsResponse = PostsResponse.fromJson(response.data);
        if (page == 1) {
          await _feedCacheService.saveLatestFeed(postsResponse);
        }
        return postsResponse;
      }

      if (response.data is List) {
        final posts = (response.data as List)
            .map((json) => FeedPost.fromJson(json))
            .toList();
        final postsResponse = PostsResponse(
          posts: posts,
          hasMore: posts.length == 10,
          page: page,
        );
        if (page == 1) {
          await _feedCacheService.saveLatestFeed(postsResponse);
        }
        return postsResponse;
      }

      return PostsResponse(posts: [], hasMore: false, page: page);
    } on DioException catch (e) {
      debugPrint('Get posts error: ${e.response?.data}');
      if (page == 1) {
        final cached = _feedCacheService.readLatestFeed();
        if (cached != null && cached.posts.isNotEmpty) {
          return cached;
        }
      }
      throw e.response?.data['message'] ?? 'Failed to get posts';
    }
  }

  PostsResponse? getCachedPosts() {
    return _feedCacheService.readLatestFeed();
  }

  // Create post
  Future<Map<String, dynamic>> createPost({
    required String content,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final data = <String, dynamic>{'content': content};
      if (attachments != null && attachments.isNotEmpty) {
        data['attachments'] = attachments;
      }

      final response = await _api.post('/api/feed/posts', data: data);
      _invalidateFeedCaches();
      return response.data;
    } on DioException catch (e) {
      debugPrint('Create post error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to create post';
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

  Future<Map<String, dynamic>> repost({
    required int postId,
    String content = '',
  }) async {
    try {
      final response = await _api.post(
        '/api/feed/posts/$postId/repost',
        data: {'content': content},
      );
      _invalidateFeedCaches();
      return _readMap(response.data);
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
  }) async {
    try {
      final response = await _api.post(
        '/api/feed/posts/$postId/comments',
        data: {'content': content},
      );
      _invalidatePostCaches(postId);
      return Comment.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('Add comment error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to add comment';
    }
  }

  Future<void> deletePost(int postId) async {
    try {
      await _api.delete('/api/feed/posts/$postId');
      _invalidateFeedCaches();
    } on DioException {
      // Delete failures are intentionally non-blocking for the feed UI.
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
        return FeedPost.fromJson(response.data);
      }

      if (response.data is Map) {
        _invalidatePostCaches(postId);
        return FeedPost.fromJson(Map<String, dynamic>.from(response.data));
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

  Map<String, dynamic> _readMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  void _invalidatePostCaches(int postId) {
    _api.removeCacheByPath('/api/feed/posts');
    _api.removeCacheByPath('/api/feed/posts/$postId');
    _api.removeCacheByPath('/api/feed/posts/$postId/comments');
    _api.removeCacheByPath('/api/feed/users');
  }

  void _invalidateFeedCaches() {
    _api.removeCacheByPath('/api/feed/posts');
    _api.removeCacheByPath('/api/feed/users');
  }
}
