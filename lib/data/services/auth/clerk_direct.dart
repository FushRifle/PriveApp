import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:social_media_app/app/configs/api_config.dart';

class ClerkDirectAuth {
  static const String frontendUrl = ApiConfig.clerkFrontendUrl;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: frontendUrl,
    connectTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Sign In - Direct to Clerk (Single request with email and password)
  Future<ClerkDirectResult> signIn(String email, String password) async {
    try {
      final response = await _dio.post('/v1/client/sign_ins', data: {
        'strategy': 'password',
        'identifier': email.trim().toLowerCase(),
        'password': password,
      });

      final body = response.data;
      debugPrint('SignIn response: $body');

      final res = body['response'];
      final status = res?['status'];

      if (status == 'complete') {
        final sessionId = res['created_session_id'] ?? res['id'];

        final token = await _getToken(sessionId);
        if (token != null) {
          await _saveToken(token);
          return ClerkDirectResult(success: true, status: 'complete');
        }

        return ClerkDirectResult(success: false, error: 'Failed to get token');
      }

      if (status == 'needs_second_factor') {
        return ClerkDirectResult(
          success: false,
          status: 'needs_verification',
          signInId: res['id'],
        );
      }

      return ClerkDirectResult(
        success: false,
        error: 'Sign in failed: $status',
      );
    } on DioException catch (e) {
      debugPrint('SignIn error: ${e.response?.data}');
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

      debugPrint('SignUp response: $body');

      final status = body['status'];

      if (status == 'complete') {
        final sessionId = body['response']['id'];
        final token = await _getToken(sessionId);
        if (token != null) {
          await _saveToken(token);
          return ClerkDirectResult(success: true, status: 'complete');
        }
        return ClerkDirectResult(success: false, error: 'Failed to get token');
      }

      if (status == 'missing_requirements') {
        final signUpId = body['response']['id'];
        await _prepareVerification(signUpId);
        return ClerkDirectResult(
          success: false,
          status: 'needs_verification',
          signInId: signUpId,
        );
      }

      return ClerkDirectResult(
          success: false,
          error: body['error']?['message'] ?? 'Sign up failed: $status');
    } on DioException catch (e) {
      debugPrint('SignUp error: ${e.response?.data}');
      return ClerkDirectResult(success: false, error: _handleError(e));
    }
  }

  // Prepare verification (send email code)
  Future<void> _prepareVerification(String signUpId) async {
    try {
      await _dio
          .post('/v1/client/sign_ups/$signUpId/prepare_verification', data: {
        'strategy': 'email_code',
      });
    } catch (e) {
      debugPrint('Prepare verification error: $e');
    }
  }

  // Verify Email Code
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

      debugPrint('Verify response: $body');

      if (body['status'] == 'complete') {
        final sessionId =
            body['response']['created_session_id'] ?? body['response']['id'];
        final token = await _getToken(sessionId);
        if (token != null) {
          await _saveToken(token);
          return ClerkDirectResult(success: true, status: 'complete');
        }
        return ClerkDirectResult(success: false, error: 'Failed to get token');
      }

      return ClerkDirectResult(
          success: false,
          error: body['error']?['message'] ?? 'Verification failed');
    } on DioException catch (e) {
      debugPrint('Verify error: ${e.response?.data}');
      return ClerkDirectResult(success: false, error: _handleError(e));
    }
  }

  // Resend Verification Code
  Future<void> resendCode(String signInId, {required bool isSignUp}) async {
    try {
      if (isSignUp) {
        await _dio
            .post('/v1/client/sign_ups/$signInId/prepare_verification', data: {
          'strategy': 'email_code',
        });
      } else {
        await _dio
            .post('/v1/client/sign_ins/$signInId/prepare_second_factor', data: {
          'strategy': 'email_code',
        });
      }
    } on DioException catch (e) {
      debugPrint('Resend failed: ${e.response?.data}');
      rethrow;
    }
  }

  // Get Session Token from Clerk
  Future<String?> _getToken(String sessionId) async {
    try {
      final response = await _dio.get('/v1/client/sessions/$sessionId/token');
      return response.data['jwt'];
    } catch (e) {
      debugPrint('Failed to get token: $e');
      return null;
    }
  }

  // Sign Out
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
    if (e.response?.statusCode == 429) {
      return 'Too many attempts. Please try again later';
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    }
    if (e.type == DioExceptionType.unknown) {
      return 'Network error. Check your connection';
    }

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
