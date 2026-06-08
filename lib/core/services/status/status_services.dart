import 'package:dio/dio.dart';
import '../../clients/api_service.dart';
import '../../models/status_model.dart';

class StatusService {
  final ApiService _api = ApiService();

  void setAuthToken(String token) {
    _api.setAuthToken(token);
  }

  void clearAuthToken() {
    _api.clearAuthToken();
  }

  Future<List<Story>> getStories() async {
    try {
      final response = await _api.get(
        '/api/stories',
        queryParameters: const {
          'scope': 'following',
          'followingOnly': true,
        },
        forceRefresh: true,
      );
      final data = response.data;

      if (data is List) {
        return data.map((json) => Story.fromJson(json)).toList();
      }
      if (data is Map) {
        final stories = data['data'] ?? data['stories'] ?? data['items'];
        if (stories is List) {
          return stories.map((json) => Story.fromJson(json)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load stories');
    }
  }

  Future<void> createStory({
    required String content,
    List<Attachment>? attachments,
    String? backgroundColor,
    String? textAlign,
    double? fontSize,
  }) async {
    try {
      final data = <String, dynamic>{
        'content': content,
      };
      final mentions = _extractMentions(content);
      if (mentions.isNotEmpty) {
        data['mentions'] = mentions;
      }

      if (attachments != null && attachments.isNotEmpty) {
        data['attachments'] = attachments.map((a) => a.toJson()).toList();
      }
      if (backgroundColor != null) data['backgroundColor'] = backgroundColor;
      if (textAlign != null) data['textAlign'] = textAlign;
      if (fontSize != null) data['fontSize'] = fontSize;

      await _api.post('/api/stories', data: data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to create story');
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await _api.delete('/api/stories/$storyId');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to delete story');
    }
  }

  Future<void> markStoryAsSeen(String storyId) async {
    try {
      await _api.post('/api/stories/$storyId/seen');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to mark story as seen');
    }
  }

  Future<void> likeStory(String storyId) async {
    try {
      await _api.post('/api/stories/$storyId/like');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to like story');
    }
  }

  Future<void> unlikeStory(String storyId) async {
    try {
      await _api.delete('/api/stories/$storyId/like');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to unlike story');
    }
  }

  Future<void> replyToStory({
    required String storyId,
    required String content,
  }) async {
    try {
      await _api.post(
        '/api/stories/$storyId/replies',
        data: {'content': content},
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to reply to story');
    }
  }

  Future<void> reshareStory(String storyId) async {
    try {
      await _api.post('/api/stories/$storyId/reshare');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to reshare story');
    }
  }

  String _handleError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    return fallback;
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
