import 'package:dio/dio.dart';
import '../api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  List<String> _parseLanguages(dynamic languages) {
    if (languages == null) return [];
    if (languages is List) return languages.cast<String>();
    if (languages is String) {
      final cleaned = languages.replaceAll(RegExp(r'^{|}$'), '');
      return cleaned.isNotEmpty ? cleaned.split(',') : [];
    }
    return [];
  }

  // Complete onboarding
  Future<Map<String, dynamic>> completeOnboarding() async {
    try {
      final response = await _api.put('/users/onboard');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to complete onboarding';
    }
  }

  // Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _api.get('/users/me');

      if (response.data != null && response.data['languages'] != null) {
        response.data['languages'] =
            _parseLanguages(response.data['languages']);
      }

      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get user';
    }
  }

  // Update current user
  Future<Map<String, dynamic>> updateCurrentUser(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/users/me', data: data);

      if (response.data != null && response.data['languages'] != null) {
        response.data['languages'] =
            _parseLanguages(response.data['languages']);
      }

      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update user';
    }
  }

  // Delete current user
  Future<Map<String, dynamic>> deleteCurrentUser() async {
    try {
      final response = await _api.delete('/users/me');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete account';
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await _api.get('/users/$userId');

      if (response.data != null && response.data['languages'] != null) {
        response.data['languages'] =
            _parseLanguages(response.data['languages']);
      }

      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get user';
    }
  }
}
