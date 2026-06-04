import 'package:dio/dio.dart';
import '../../../core/api_service.dart';
import '../../models/feature_access_model.dart';

class SubscriptionService {
  final ApiService _api = ApiService();

  // Get current subscription
  Future<Map<String, dynamic>> getSubscription() async {
    try {
      final response = await _api.get('/api/subscription');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get subscription';
    }
  }

  Future<FeatureAccess> getFeatureAccess() async {
    try {
      final response = await _api.get('/api/subscription/access');
      if (response.data is Map) {
        return FeatureAccess.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      return FeatureAccess.free();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get feature access';
    }
  }

  Future<FeatureAccess> syncEntitlement({
    required String productId,
    required int expiresAtMs,
    required bool isActive,
  }) async {
    try {
      final response = await _api.post(
        '/api/subscription/sync-entitlement',
        data: {
          'productId': productId,
          'expiresAtMs': expiresAtMs,
          'isActive': isActive,
        },
      );
      if (response.data is Map) {
        return FeatureAccess.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      return FeatureAccess.free();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to sync entitlement';
    }
  }

  // Create checkout session
  Future<Map<String, dynamic>> createCheckoutSession({
    required String planId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final response = await _api.post('/api/subscription/checkout', data: {
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
      final response = await _api.get('/api/subscription/plans');
      return response.data is List ? response.data : [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get plans';
    }
  }
}
