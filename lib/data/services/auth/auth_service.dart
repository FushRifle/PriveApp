import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:social_media_app/app/configs/api_config.dart';
import '../../services/api_service.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  // Sign In
  Future<AuthResult> signIn(String email, String password) async {
    try {
      final response = await _dio.post('/api/auth/signin', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      });

      final data = response.data;
      final token = data['token'];

      if (token != null && token.isNotEmpty) {
        await _apiService.setToken(token);
        return AuthResult(success: true, token: token, user: data['user']);
      }

      return AuthResult(success: false, error: 'No token received');
    } on DioException catch (e) {
      return AuthResult(success: false, error: _handleError(e));
    }
  }

  // Sign Up
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _dio.post('/api/auth/signup', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });

      final data = response.data;
      final token = data['token'];

      if (token != null && token.isNotEmpty) {
        await _apiService.setToken(token);
        return AuthResult(success: true, token: token, user: data['user']);
      }

      return AuthResult(success: false, error: 'No token received');
    } on DioException catch (e) {
      return AuthResult(success: false, error: _handleError(e));
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _apiService.clearToken();
    await _storage.delete(key: 'remember_me');
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');
  }

  // Get Token
  Future<String?> getToken() async {
    return await _apiService.getToken();
  }

  // Check if authenticated
  Future<bool> isAuthenticated() async {
    return await _apiService.hasToken();
  }

  // Get saved credentials (Remember Me)
  Future<Map<String, dynamic>> getSavedCredentials() async {
    final rememberMe = await _storage.read(key: 'remember_me') == 'true';

    if (rememberMe) {
      return {
        'rememberMe': true,
        'email': await _storage.read(key: 'email') ?? '',
        'password': await _storage.read(key: 'password') ?? '',
      };
    }

    return {
      'rememberMe': false,
      'email': '',
      'password': '',
    };
  }

  // Save credentials (Remember Me)
  Future<void> saveCredentials(
      String email, String password, bool remember) async {
    if (remember) {
      await _storage.write(key: 'email', value: email);
      await _storage.write(key: 'password', value: password);
      await _storage.write(key: 'remember_me', value: 'true');
    } else {
      await _storage.delete(key: 'email');
      await _storage.delete(key: 'password');
      await _storage.write(key: 'remember_me', value: 'false');
    }
  }

  String _handleError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'];
    }
    if (e.response?.statusCode == 401) return 'Invalid email or password';
    if (e.type == DioExceptionType.connectionTimeout)
      return 'Connection timeout';
    if (e.type == DioExceptionType.unknown)
      return 'Network error. Check your connection';
    return 'Authentication failed. Please try again';
  }
}

class AuthResult {
  final bool success;
  final String? token;
  final Map<String, dynamic>? user;
  final String? error;

  AuthResult({
    required this.success,
    this.token,
    this.user,
    this.error,
  });
}
