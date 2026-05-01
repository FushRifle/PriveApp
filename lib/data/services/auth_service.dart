import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      // Save token using instance method
      final token = response.data['token'];
      if (token != null) {
        await _api.setToken(token);
      }

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      final token = response.data['token'];
      if (token != null) {
        await _api.setToken(token);
      }

      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (e) {
      // Still clear token even if request fails
    } finally {
      await _api.clearToken();
    }
  }

  // Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Update profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? bio,
    String? avatar,
  }) async {
    try {
      final response = await _api.put('/auth/profile', data: {
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (avatar != null) 'avatar': avatar,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      return error.response?.data['message'] ?? 'Something went wrong';
    }
    return error.toString();
  }
}
