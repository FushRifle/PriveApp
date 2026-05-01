import 'package:dio/dio.dart';
import '../api_service.dart';

class FeedService {
  final ApiService _api = ApiService();

  // Get stories
  Future<List<dynamic>> getStories() async {
    try {
      final response = await _api.get('/api/feed/stories');
      return response.data['stories'] ?? response.data ?? [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get stories';
    }
  }

  // Get feed posts
  Future<Map<String, dynamic>> getPosts({int page = 1}) async {
    try {
      final response = await _api.get('/api/feed/posts', queryParameters: {
        'page': page,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get posts';
    }
  }

  // Create post
  Future<Map<String, dynamic>> createPost({
    required String content,
    String? imageUrl,
  }) async {
    try {
      final data = <String, dynamic>{'content': content};
      if (imageUrl != null) data['imageUrl'] = imageUrl;

      final response = await _api.post('/api/feed/posts', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to create post';
    }
  }

  // Like post
  Future<void> likePost(int postId) async {
    try {
      await _api.post('/api/feed/posts/$postId/like');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to like post';
    }
  }

  // Unlike post
  Future<void> unlikePost(int postId) async {
    try {
      await _api.delete('/api/feed/posts/$postId/like');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to unlike post';
    }
  }

  // Get post comments
  Future<List<dynamic>> getComments(int postId, {int page = 1}) async {
    try {
      final response = await _api.get(
        '/api/feed/posts/$postId/comments',
        queryParameters: {'page': page},
      );
      return response.data['comments'] ?? response.data ?? [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get comments';
    }
  }

  // Add comment
  Future<Map<String, dynamic>> addComment({
    required int postId,
    required String content,
  }) async {
    try {
      final response = await _api.post(
        '/api/feed/posts/$postId/comments',
        data: {'content': content},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to add comment';
    }
  }
}
