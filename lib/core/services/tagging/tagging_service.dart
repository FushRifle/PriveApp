import 'package:dio/dio.dart';

import 'package:clique/core/clients/api_service.dart';

class TaggingService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> syncUserTags({
    required String contentType,
    required int contentId,
    List<int> userIds = const [],
    List<String> usernames = const [],
  }) async {
    try {
      final response = await _api.post(
        '/api/tags/users',
        data: {
          'contentType': contentType,
          'contentId': contentId,
          'userIds': userIds,
          'usernames': usernames,
        },
      );

      final data = response.data;
      final raw = data is Map ? data['data'] : data;
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to tag users');
    }
  }

  Future<List<Map<String, dynamic>>> getUserTags({
    required String contentType,
    required int contentId,
  }) async {
    try {
      final response = await _api.get('/api/tags/$contentType/$contentId');
      final data = response.data;
      final raw = data is Map ? data['data'] : data;
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load tagged users');
    }
  }

  String _handleError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    if (data is String && data.trim().isNotEmpty) return data;
    return fallback;
  }
}
