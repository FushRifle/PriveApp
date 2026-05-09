import 'package:dio/dio.dart';
import '../api_service.dart';

class FeedService {
  final ApiService _api = ApiService();

  // Get stories
  Future<List<dynamic>> getStories() async {
    try {
      final response = await _api.get('/api/feed/stories');
      print('Stories response: ${response.data}');

      if (response.data is List) {
        return response.data;
      }

      if (response.data is Map && response.data['stories'] is List) {
        return response.data['stories'];
      }

      if (response.data is Map && response.data['data'] is List) {
        return response.data['data'];
      }

      return [];
    } on DioException catch (e) {
      print('Get stories error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to get stories';
    }
  }

  // Get feed posts
  Future<Map<String, dynamic>> getPosts({int page = 1}) async {
    try {
      final response = await _api.get(
        '/api/feed/posts',
        queryParameters: {'page': page},
      );

      print('Posts response status: ${response.statusCode}');

      if (response.data is Map) {
        return response.data;
      }

      if (response.data is List) {
        return {
          'posts': response.data,
          'hasMore': response.data.length == 10,
          'page': page,
        };
      }

      return {'posts': [], 'hasMore': false, 'page': page};
    } on DioException catch (e) {
      print('Get posts error: ${e.response?.data}');
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
      if (imageUrl != null && imageUrl.isNotEmpty) {
        data['attachments'] = [
          {'type': 'image', 'url': imageUrl},
        ];
      }

      final response = await _api.post('/api/feed/posts', data: data);
      return response.data;
    } on DioException catch (e) {
      print('Create post error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to create post';
    }
  }

  // Create story/status - Updated to match backend
  Future<Map<String, dynamic>> createStatus({
    required String text,
    String? imageUrl,
    String? videoUrl,
    String? backgroundColor,
    String? textAlign,
    double? fontSize,
  }) async {
    try {
      final data = <String, dynamic>{};

      // Add content if there's text
      if (text.isNotEmpty) {
        data['content'] = text;
      }

      // Add attachments if any
      List<Map<String, dynamic>> attachments = [];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        attachments.add({'type': 'image', 'url': imageUrl});
      }
      if (videoUrl != null && videoUrl.isNotEmpty) {
        attachments.add({'type': 'video', 'url': videoUrl});
      }
      if (attachments.isNotEmpty) {
        data['attachments'] = attachments;
      }

      // Add story formatting options
      if (backgroundColor != null && backgroundColor.isNotEmpty) {
        data['backgroundColor'] = backgroundColor;
      }
      if (textAlign != null && textAlign.isNotEmpty) {
        data['textAlign'] = textAlign;
      }
      if (fontSize != null) {
        data['fontSize'] = fontSize;
      }

      final response = await _api.post('/api/feed/stories', data: data);
      return response.data;
    } catch (e) {
      print('Create status error: $e');
      throw Exception('Failed to create status: $e');
    }
  }

  // Like post
  Future<void> likePost(int postId) async {
    try {
      await _api.post('/api/feed/posts/$postId/like');
    } on DioException catch (e) {
      print('Like post error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to like post';
    }
  }

  // Unlike post
  Future<void> unlikePost(int postId) async {
    try {
      await _api.delete('/api/feed/posts/$postId/like');
    } on DioException catch (e) {
      print('Unlike post error: ${e.response?.data}');
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

      if (response.data is List) {
        return response.data;
      }

      if (response.data is Map && response.data['comments'] is List) {
        return response.data['comments'];
      }

      return [];
    } on DioException catch (e) {
      print('Get comments error: ${e.response?.data}');
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
      print('Add comment error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to add comment';
    }
  }
}
