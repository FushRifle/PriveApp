import 'package:dio/dio.dart';
import '../../../core/api_service.dart';
import '../../models/feeds_models.dart';

class FeedService {
  final ApiService _api = ApiService();

  Future<List<Story>> getStories() async {
    try {
      final response = await _api.get('/api/feed/stories');
      print('Stories response: ${response.data}');

      List<dynamic> storiesData = [];

      if (response.data is List) {
        storiesData = response.data;
      } else if (response.data is Map && response.data['stories'] is List) {
        storiesData = response.data['stories'];
      } else if (response.data is Map && response.data['data'] is List) {
        storiesData = response.data['data'];
      }

      return storiesData.map((json) => Story.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Get stories error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to get stories';
    }
  }

  // Get feed posts - returns typed PostsResponse
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

  // Create story
  Future<Map<String, dynamic>> createStory({
    String? content,
    List<Map<String, dynamic>>? attachments,
    String? backgroundColor,
    String? textAlign,
    double? fontSize,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (content != null && content.isNotEmpty) {
        data['content'] = content;
      }

      if (attachments != null && attachments.isNotEmpty) {
        data['attachments'] = attachments;
      }

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
    } on DioException catch (e) {
      print('Create story error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to create story';
    } catch (e) {
      print('Create story error: $e');
      throw Exception('Failed to create story: $e');
    }
  }

  // Delete story
  Future<void> deleteStory(String storyId) async {
    try {
      await _api.delete('/api/feed/stories/$storyId');
    } on DioException catch (e) {
      print('Delete story error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to delete story';
    }
  }

  // Mark story as seen
  Future<void> markStoryAsSeen(String storyId) async {
    try {
      await _api.post('/api/feed/stories/$storyId/seen');
    } on DioException catch (e) {
      print('Mark story as seen error: ${e.response?.data}');
      throw e.response?.data['message'] ?? 'Failed to mark story as seen';
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
    String? type, // 'image', 'video', or null for all
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
      // You might want to add a separate endpoint for count
      // Or just get first page and check total from response headers
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

// Response models for paginated data
class UserMediaResponse {
  final List<UserMedia> media;
  final bool hasMore;
  final int page;
  final int? total;

  UserMediaResponse({
    required this.media,
    required this.hasMore,
    required this.page,
    this.total,
  });

  factory UserMediaResponse.fromJson(Map<String, dynamic> json) {
    List<UserMedia> mediaList = [];

    if (json['media'] != null && json['media'] is List) {
      mediaList = (json['media'] as List)
          .map((item) => UserMedia.fromJson(item))
          .toList();
    } else if (json['data'] != null && json['data'] is List) {
      mediaList = (json['data'] as List)
          .map((item) => UserMedia.fromJson(item))
          .toList();
    } else if (json['items'] != null && json['items'] is List) {
      mediaList = (json['items'] as List)
          .map((item) => UserMedia.fromJson(item))
          .toList();
    }

    return UserMediaResponse(
      media: mediaList,
      hasMore: json['hasMore'] ?? json['has_more'] ?? false,
      page: json['page'] ?? 1,
      total: json['total'],
    );
  }
}

// UserMedia model (add this to your feeds_models.dart or create separate file)
class UserMedia {
  final int id;
  final int postId;
  final String type;
  final String url;
  final String? thumbnail;
  final String? caption;
  final int likes;
  final int comments;
  final DateTime createdAt;

  UserMedia({
    required this.id,
    required this.postId,
    required this.type,
    required this.url,
    this.thumbnail,
    this.caption,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  factory UserMedia.fromJson(Map<String, dynamic> json) {
    return UserMedia(
      id: json['id'] ?? 0,
      postId: json['postId'] ?? json['post_id'] ?? 0,
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'],
      caption: json['caption'],
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'type': type,
      'url': url,
      'thumbnail': thumbnail,
      'caption': caption,
      'likes': likes,
      'comments': comments,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
