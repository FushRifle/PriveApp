import 'package:dio/dio.dart';

import 'package:clique/core/clients/api_service.dart';

class FeedbackService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> submitFeedback({
    required String category,
    required String message,
    String? email,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _api.post(
        '/api/feedback',
        data: {
          'category': category,
          'message': message,
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
          if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return const {};
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to send feedback');
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
