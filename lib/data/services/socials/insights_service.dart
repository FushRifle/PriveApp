import 'package:dio/dio.dart';
import '../api_service.dart';

class InsightsService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getInsights({int days = 30}) async {
    try {
      final queryParams = <String, dynamic>{
        'days': days.clamp(1, 90),
      };

      final response =
          await _api.get('/api/insights', queryParameters: queryParams);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get insights');
    }
  }

  // Get real-time stats (online viewers, active sessions)
  Future<Map<String, dynamic>> getRealtimeStats() async {
    try {
      final response = await _api.get('/api/insights/realtime');
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get realtime stats');
    }
  }

  // Track user event (view, like, share, comment, follow)
  Future<void> trackEvent({
    required String eventType,
    required String objectType,
    required int objectId,
    String? section,
    String? source,
  }) async {
    try {
      final data = <String, dynamic>{
        'eventType': eventType,
        'objectType': objectType,
        'objectId': objectId,
      };
      if (section != null) data['section'] = section;
      if (source != null) data['source'] = source;

      final response = await _api.post('/api/insights/track', data: data);
      // Success - no return data needed
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to track event');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw 'Invalid response format';
  }

  String _handleError(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return fallback;
  }
}

// Event tracking helper methods for common actions
extension InsightsServiceEvents on InsightsService {
  // Track post views
  Future<void> trackPostView(int postId, {String? section}) async {
    await trackEvent(
      eventType: 'view',
      objectType: 'post',
      objectId: postId,
      section: section,
    );
  }

  // Track post likes
  Future<void> trackPostLike(int postId, {String? section}) async {
    await trackEvent(
      eventType: 'like',
      objectType: 'post',
      objectId: postId,
      section: section,
    );
  }

  // Track post comments
  Future<void> trackPostComment(int postId, {String? section}) async {
    await trackEvent(
      eventType: 'comment',
      objectType: 'post',
      objectId: postId,
      section: section,
    );
  }

  // Track post shares
  Future<void> trackPostShare(int postId, {String? section}) async {
    await trackEvent(
      eventType: 'share',
      objectType: 'post',
      objectId: postId,
      section: section,
    );
  }

  // Track reel views
  Future<void> trackReelView(int reelId, {String? section}) async {
    await trackEvent(
      eventType: 'view',
      objectType: 'reel',
      objectId: reelId,
      section: section,
    );
  }

  // Track reel likes
  Future<void> trackReelLike(int reelId, {String? section}) async {
    await trackEvent(
      eventType: 'like',
      objectType: 'reel',
      objectId: reelId,
      section: section,
    );
  }

  // Track reel shares
  Future<void> trackReelShare(int reelId, {String? section}) async {
    await trackEvent(
      eventType: 'share',
      objectType: 'reel',
      objectId: reelId,
      section: section,
    );
  }

  // Track profile views
  Future<void> trackProfileView(int userId, {String? section}) async {
    await trackEvent(
      eventType: 'view',
      objectType: 'profile',
      objectId: userId,
      section: section,
    );
  }

  // Track follows
  Future<void> trackFollow(int userId, {String? section}) async {
    await trackEvent(
      eventType: 'follow',
      objectType: 'user',
      objectId: userId,
      section: section,
    );
  }

  // Track story views
  Future<void> trackStoryView(int storyId, {String? section}) async {
    await trackEvent(
      eventType: 'view',
      objectType: 'story',
      objectId: storyId,
      section: section,
    );
  }

  // Track search queries
  Future<void> trackSearch(String query, {String? section}) async {
    // Search is tracked differently
    try {
      final data = {
        'eventType': 'search',
        'objectType': 'search',
        'objectId': 0,
        'section': section ?? 'search',
        'source': query,
      };
      await _api.post('/api/insights/track', data: data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to track search');
    }
  }
}
