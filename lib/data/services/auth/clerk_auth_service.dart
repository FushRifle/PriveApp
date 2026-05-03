import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:social_media_app/app/configs/api_config.dart';

class ClerkAuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Sign In
  Future<ClerkResult> signIn(String email, String password) async {
    try {
      final res = await _dio.post('/api/auth/signin', data: {
        'identifier': email.trim().toLowerCase(),
        'password': password,
      });
      final body = res.data;

      if (body['status'] == 'complete') {
        final token = await _getToken(body['created_session_id']);
        if (token != null) await _saveToken(token);
        return ClerkResult(success: true, status: 'complete');
      }

      if (body['status'] == 'needs_second_factor') {
        return ClerkResult(
            success: false, status: 'needs_verification', signInId: body['id']);
      }

      return ClerkResult(success: false, error: 'Status: ${body['status']}');
    } on DioException catch (e) {
      return ClerkResult(success: false, error: _handleError(e));
    }
  }

  // Sign Up
  Future<ClerkResult> signUp(
      String email, String password, String firstName, String lastName) async {
    try {
      final res = await _dio.post('/api/auth/signup', data: {
        'email_address': email.trim().toLowerCase(),
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });
      final body = res.data;

      if (body['status'] == 'missing_requirements') {
        // Trigger verification code to be sent
        await _resendCode(body['id'], isSignUp: true);
        return ClerkResult(
            success: false, status: 'needs_verification', signInId: body['id']);
      }

      if (body['status'] == 'complete') {
        final token = await _getToken(body['created_session_id']);
        if (token != null) await _saveToken(token);
        return ClerkResult(success: true, status: 'complete');
      }

      return ClerkResult(success: false, error: 'Status: ${body['status']}');
    } on DioException catch (e) {
      return ClerkResult(success: false, error: _handleError(e));
    }
  }

  // Verify Email Code
  Future<ClerkResult> verify(String signInId, String code,
      {required bool isSignUp}) async {
    try {
      final res = await _dio.post('/api/auth/verify', data: {
        'signInId': signInId,
        'code': code.trim(),
        'isSignUp': isSignUp,
      });
      final body = res.data;

      if (body['status'] == 'complete') {
        final token = await _getToken(body['created_session_id']);
        if (token != null) await _saveToken(token);
        return ClerkResult(success: true, status: 'complete');
      }

      return ClerkResult(success: false, error: 'Verification failed');
    } on DioException catch (e) {
      return ClerkResult(success: false, error: _handleError(e));
    }
  }

  // Resend Verification Code
  Future<void> resendCode(String signInId, {required bool isSignUp}) async {
    await _resendCode(signInId, isSignUp: isSignUp);
  }

  Future<void> _resendCode(String signInId, {required bool isSignUp}) async {
    try {
      await _dio.post('/api/auth/resend', data: {
        'signInId': signInId,
        'isSignUp': isSignUp,
      });
    } on DioException catch (e) {
      print('Resend failed: ${_handleError(e)}');
      rethrow;
    }
  }

  // Get Session Token
  Future<String?> _getToken(String sessionId) async {
    try {
      final res = await _dio.get('/api/auth/token/$sessionId');
      return res.data['jwt'] ?? res.data['response']?['jwt'];
    } catch (e) {
      print('Failed to get token: $e');
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _storage.delete(key: 'auth_token');
  }

  // Check Authentication Status
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  // Get Auth Token for API Calls
  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Save Auth Token
  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Get Saved Credentials (Remember Me)
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

  // Save Credentials (Remember Me)
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

  // Add Token to Dio Headers (Interceptor)
  void addAuthInterceptor() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAuthToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // Error Handler
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

    // Handle specific status codes
    if (e.response?.statusCode == 401)
      return 'Unauthorized. Please sign in again.';
    if (e.response?.statusCode == 429)
      return 'Too many attempts. Please try again later.';
    if (e.type == DioExceptionType.connectionTimeout)
      return 'Connection timeout. Check your network.';
    if (e.type == DioExceptionType.unknown)
      return 'Network error. Check your connection.';

    return 'Authentication failed. Please try again.';
  }
}

class ClerkResult {
  final bool success;
  final String? status;
  final String? signInId;
  final String? error;

  ClerkResult({
    required this.success,
    this.status,
    this.signInId,
    this.error,
  });
}
