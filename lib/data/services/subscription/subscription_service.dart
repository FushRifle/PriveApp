import 'package:dio/dio.dart';
import '../../../core/api_service.dart';

class SubscriptionService {
  final ApiService _api = ApiService();

  // Get current subscription
  Future<Map<String, dynamic>> getSubscription() async {
    try {
      final response = await _api.get('/subscription');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get subscription';
    }
  }

  // Create checkout session
  Future<Map<String, dynamic>> createCheckoutSession({
    required String planId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final response = await _api.post('/subscription/checkout', data: {
        'planId': planId,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to create checkout session';
    }
  }

  // Get available plans
  Future<List<dynamic>> getPlans() async {
    try {
      final response = await _api.get('/subscription/plans');
      return response.data is List ? response.data : [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get plans';
    }
  }
}
