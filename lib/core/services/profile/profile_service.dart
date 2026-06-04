import 'package:dio/dio.dart';
import '../../clients/api_service.dart';

class ProfileService {
  final ApiService _api = ApiService();

  void setAuthToken(String token) {
    _api.setAuthToken(token);
  }

  void clearAuthToken() {
    _api.clearAuthToken();
  }

  // Get my profile
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _api.get('/api/profiles/me');
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load profile');
    }
  }

  // Update my profile (creates or updates)
  Future<Map<String, dynamic>> updateMyProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/api/profiles/me', data: data);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to update profile');
    }
  }

  // Get profile by user ID
  Future<Map<String, dynamic>> getProfileByUserId(int userId) async {
    try {
      final response = await _api.get('/api/profiles/$userId');
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load profile');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw 'Invalid profile response';
  }

  String _handleError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    return fallback;
  }
}
