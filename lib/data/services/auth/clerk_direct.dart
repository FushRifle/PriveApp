import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:social_media_app/app/configs/api_config.dart';

class ClerkDirectAuth {
  static const String frontendUrl = ApiConfig.clerkFrontendUrl;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: frontendUrl,
    connectTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Clerk-Instance-Type': 'production',
    },
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Sign In - Direct to Clerk
  Future<ClerkDirectResult> signIn(String email, String password) async {
    try {
      final response = await _dio.post('/v1/client/sign_ins', data: {
        'identifier': email.trim().toLowerCase(),
        'password': password,
      });
      final body = response.data;

      if (body['status'] == 'complete') {
        final sessionId = body['response']['id'];
        final token = await _getToken(sessionId);
        if (token != null) {
          await _saveToken(token);
          return ClerkDirectResult(success: true, status: 'complete');
        }
        return ClerkDirectResult(success: false, error: 'Failed to get token');
      }

      if (body['status'] == 'needs_second_factor') {
        return ClerkDirectResult(
          success: false,
          status: 'needs_verification',
          signInId: body['response']['id'],
        );
      }

      return ClerkDirectResult(
          success: false, error: 'Status: ${body['status']}');
    } on DioException catch (e) {
      return ClerkDirectResult(success: false, error: _handleError(e));
    }
  }

  // Sign Up - Direct to Clerk
  Future<ClerkDirectResult> signUp(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final response = await _dio.post('/v1/client/sign_ups', data: {
        'email_address': email.trim().toLowerCase(),
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });
      final body = response.data;

      if (body['status'] == 'missing_requirements') {
        // Trigger verification code to be sent
        await resendCode(body['response']['id'], isSignUp: true);
        return ClerkDirectResult(
          success: false,
          status: 'needs_verification',
          signInId: body['response']['id'],
        );
      }

      if (body['status'] == 'complete') {
        final sessionId = body['response']['id'];
        final token = await _getToken(sessionId);
        if (token != null) {
          await _saveToken(token);
          return ClerkDirectResult(success: true, status: 'complete');
        }
        return ClerkDirectResult(success: false, error: 'Failed to get token');
      }

      return ClerkDirectResult(
          success: false, error: 'Status: ${body['status']}');
    } on DioException catch (e) {
      return ClerkDirectResult(success: false, error: _handleError(e));
    }
  }

  // Verify Email Code - Direct to Clerk
  Future<ClerkDirectResult> verify(String signInId, String code,
      {required bool isSignUp}) async {
    try {
      String path;
      if (isSignUp) {
        path = '/v1/client/sign_ups/$signInId/attempt_verification';
      } else {
        path = '/v1/client/sign_ins/$signInId/attempt_second_factor';
      }

      final response = await _dio.post(path, data: {
        'strategy': 'email_code',
        'code': code.trim(),
      });
      final body = response.data;

      if (body['status'] == 'complete') {
        final sessionId = body['response']['id'];
        final token = await _getToken(sessionId);
        if (token != null) {
          await _saveToken(token);
          return ClerkDirectResult(success: true, status: 'complete');
        }
        return ClerkDirectResult(success: false, error: 'Failed to get token');
      }

      return ClerkDirectResult(success: false, error: 'Verification failed');
    } on DioException catch (e) {
      return ClerkDirectResult(success: false, error: _handleError(e));
    }
  }

  // Resend Verification Code - Direct to Clerk
  Future<void> resendCode(String signInId, {required bool isSignUp}) async {
    try {
      String path;
      Map<String, String> data;

      if (isSignUp) {
        path = '/v1/client/sign_ups/$signInId/prepare_verification';
        data = {'strategy': 'email_code'};
      } else {
        path = '/v1/client/sign_ins/$signInId/prepare_second_factor';
        data = {'strategy': 'email_code'};
      }

      await _dio.post(path, data: data);
    } on DioException catch (e) {
      print('Resend failed: ${_handleError(e)}');
      rethrow;
    }
  }

  // Get Session Token from Clerk
  Future<String?> _getToken(String sessionId) async {
    try {
      final response = await _dio.get('/v1/client/sessions/$sessionId/token');
      return response.data['jwt'];
    } catch (e) {
      print('Failed to get token: $e');
      return null;
    }
  }

  // Sign Out - Clear local storage
  Future<void> signOut() async {
    await _storage.delete(key: 'auth_token');
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  // Get the stored auth token
  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Save token to secure storage
  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
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
    return {'rememberMe': false, 'email': '', 'password': ''};
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

  // Error handler
  String _handleError(DioException e) {
    final data = e.response?.data;
    final body = data is Map ? data : null;

    if (body != null && body['errors'] is List && body['errors'].isNotEmpty) {
      final msg = body['errors'][0]['message']?.toString() ?? '';
      if (msg.contains('identifier') || msg.contains('email')) {
        return 'No account found with this email';
      }
      if (msg.contains('password')) return 'Incorrect password';
      if (msg.contains('verification')) return 'Invalid verification code';
      return msg.isNotEmpty ? msg : 'Authentication failed';
    }

    if (e.response?.statusCode == 401) return 'Invalid credentials';
    if (e.response?.statusCode == 429)
      return 'Too many attempts. Please try again later';
    if (e.type == DioExceptionType.connectionTimeout)
      return 'Connection timeout';
    if (e.type == DioExceptionType.unknown)
      return 'Network error. Check your connection';

    return 'Authentication failed. Please try again';
  }
}

// Result class
class ClerkDirectResult {
  final bool success;
  final String? status;
  final String? signInId;
  final String? error;

  ClerkDirectResult({
    required this.success,
    this.status,
    this.signInId,
    this.error,
  });
}
