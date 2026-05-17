import 'package:dio/dio.dart';
import '../../../core/api_service.dart';
import '../../models/feeds_models.dart';

class FeedService {
  final ApiService _api = ApiService();

  void setAuthToken(String token) {
    _api.setAuthToken(token);
  }

  void clearAuthToken() {
    _api.clearAuthToken();
  }

  Future<PostsResponse> getPosts({int page = 1}) async {
    try {
      final response = await _api.get(
        '/api/feed/posts',
        queryParameters: {'page': page},
      );

      print('Posts response status: ${response.statusCode}');

      if (response.data is Map) {
        return PostsResponse.fromJson(response.data);
      }

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

      return PostsResponse(posts: [], hasMore: false, page: page);
    } on DioException catch (e) {
      print('Get posts error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to get posts';
    }
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
      return response.data;
    } on DioException catch (e) {
      print('Create post error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to create post';
    }
  }

  // Like post
  Future<Map<String, dynamic>> likePost(int postId) async {
    try {
      final response = await _api.post('/api/feed/posts/$postId/like');
      return response.data;
    } on DioException catch (e) {
      print('Like post error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to like post';
    }
  }

  // Unlike post
  Future<Map<String, dynamic>> unlikePost(int postId) async {
    try {
      final response = await _api.delete('/api/feed/posts/$postId/like');
      return response.data;
    } on DioException catch (e) {
      print('Unlike post error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to unlike post';
    }
  }

  // Get post comments - returns typed List<Comment>
  Future<CommentsResponse> getComments(int postId, {int page = 1}) async {
    try {
      final response = await _api.get(
        '/api/feed/posts/$postId/comments',
        queryParameters: {'page': page},
      );

      if (response.data is List) {
        final comments = (response.data as List)
            .map((json) => Comment.fromJson(json))
            .toList();
        return CommentsResponse(
          comments: comments,
          hasMore: comments.length == 20,
          page: page,
        );
      }

      if (response.data is Map) {
        return CommentsResponse.fromJson(response.data);
      }

      return CommentsResponse(comments: [], hasMore: false, page: page);
    } on DioException catch (e) {
      print('Get comments error: ${e.response?.data}');
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
      return Comment.fromJson(response.data);
    } on DioException catch (e) {
      print('Add comment error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to add comment';
    }
  }

  // Get user media (for profile gallery)
  Future<UserMediaResponse> getUserMedia({
    required int userId,
    int page = 1,
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _api.get(
        '/api/feed/users/$userId/media',
        queryParameters: queryParams,
      );

      print('User media response status: ${response.statusCode}');

      if (response.data is Map) {
        return UserMediaResponse.fromJson(response.data);
      }

      if (response.data is List) {
        final media = (response.data as List)
            .map((json) => UserMedia.fromJson(json))
            .toList();
        return UserMediaResponse(
          media: media,
          hasMore: media.length == 10,
          page: page,
        );
      }

      return UserMediaResponse(media: [], hasMore: false, page: page);
    } on DioException catch (e) {
      print('Get user media error: ${e.response?.data}');
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
      print('Get user media count error: ${e.response?.data}');
      return 0;
    }
  }
}
