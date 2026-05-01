import 'package:dio/dio.dart';
import '../api_service.dart';

class InsightsService {
  final ApiService _api = ApiService();

  // Get insights
  Future<Map<String, dynamic>> getInsights({int days = 30}) async {
    try {
      final response = await _api.get('/insights', queryParameters: {
        'days': days,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get insights';
    }
  }

  // Get realtime stats
  Future<Map<String, dynamic>> getRealtimeStats() async {
    try {
      final response = await _api.get('/insights/realtime');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get realtime stats';
    }
  }

  // Track event
  Future<Map<String, dynamic>> trackEvent(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/insights/track', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to track event';
    }
  }
}
