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

  // SIGN IN
  Future<ClerkResult> signIn(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      });

      final body = res.data;

      if (body['token'] != null) {
        await _saveToken(body['token']);
        return ClerkResult(success: true, status: 'complete');
      }

      return ClerkResult(success: false, error: 'Invalid login response');
    } on DioException catch (e) {
      return ClerkResult(success: false, error: _handleError(e));
    }
  }

  // SIGN UP
  Future<ClerkResult> signUp(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final res = await _dio.post('/auth/signup', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });

      final body = res.data;

      if (body['status'] == 'complete' || body['token'] != null) {
        final token = body['token'];
        if (token != null) await _saveToken(token);
        return ClerkResult(success: true, status: 'complete');
      }

      if (body['status'] == 'needs_verification') {
        return ClerkResult(
          success: false,
          status: 'needs_verification',
          signInId: body['signInId'] ?? body['id'],
        );
      }

      return ClerkResult(success: false, error: 'Signup failed');
    } on DioException catch (e) {
      return ClerkResult(success: false, error: _handleError(e));
    }
  }

  // VERIFY
  Future<ClerkResult> verify(
    String signInId,
    String code, {
    required bool isSignUp,
  }) async {
    try {
      final res = await _dio.post('/auth/verify', data: {
        'signInId': signInId,
        'code': code.trim(),
        'isSignUp': isSignUp,
      });

      final body = res.data;

      if (body['token'] != null) {
        await _saveToken(body['token']);
        return ClerkResult(success: true, status: 'complete');
      }

      return ClerkResult(success: false, error: 'Verification failed');
    } on DioException catch (e) {
      return ClerkResult(success: false, error: _handleError(e));
    }
  }

  // RESEND
  Future<void> resendCode(String signInId, {required bool isSignUp}) async {
    await _dio.post('/auth/resend', data: {
      'signInId': signInId,
      'isSignUp': isSignUp,
    });
  }

  // SIGN OUT
  Future<void> signOut() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

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

  String _handleError(DioException e) {
    final data = e.response?.data;
    final body = data is Map ? data : null;

    if (body != null && body['error'] != null) {
      return body['error'].toString();
    }

    if (e.response?.statusCode == 401) return 'Unauthorized';
    if (e.response?.statusCode == 429) return 'Too many attempts';
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    }
    if (e.type == DioExceptionType.unknown) {
      return 'Network error';
    }

    return 'Authentication failed';
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
