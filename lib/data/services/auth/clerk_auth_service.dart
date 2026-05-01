import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:social_media_app/app/configs/api_config.dart';

class ClerkAuthService {
  final Dio _api = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<ClerkResult> signIn(String email, String password) async {
    try {
      final res = await _api.post('/auth/login', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      final data = res.data;

      if (data['token'] != null) {
        await _storage.write(key: 'auth_token', value: data['token']);
        return ClerkResult(success: true, status: 'complete');
      }
      if (data['needsVerification'] == true) {
        return ClerkResult(
            success: false,
            status: 'needs_verification',
            signInId: data['signInId']);
      }
      return ClerkResult(
          success: false, error: data['message'] ?? 'Login failed');
    } on DioException catch (e) {
      return ClerkResult(success: false, error: e.message ?? 'Network error');
    }
  }

  Future<ClerkResult> signUp(
      String email, String password, String firstName, String lastName) async {
    try {
      final res = await _api.post('/auth/register', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });
      final data = res.data;

      if (data['needsVerification'] == true) {
        return ClerkResult(
            success: false,
            status: 'needs_verification',
            signInId: data['signUpId']);
      }
      return ClerkResult(
          success: false, error: data['message'] ?? 'Registration failed');
    } on DioException catch (e) {
      return ClerkResult(success: false, error: e.message ?? 'Network error');
    }
  }

  Future<ClerkResult> verify(String signInId, String code,
      {required bool isSignUp}) async {
    try {
      final endpoint = isSignUp ? '/auth/verify-signup' : '/auth/verify-login';
      final res = await _api.post(endpoint, data: {
        'signInId': signInId,
        'code': code.trim(),
      });
      final data = res.data;

      if (data['token'] != null) {
        await _storage.write(key: 'auth_token', value: data['token']);
        return ClerkResult(success: true, status: 'complete');
      }
      return ClerkResult(
          success: false, error: data['message'] ?? 'Verification failed');
    } on DioException catch (e) {
      return ClerkResult(success: false, error: e.message ?? 'Network error');
    }
  }

  Future<void> resendCode(String signInId, {required bool isSignUp}) async {
    final endpoint =
        isSignUp ? '/auth/resend-signup-code' : '/auth/resend-login-code';
    await _api.post(endpoint, data: {'signInId': signInId});
  }

  Future<void> signOut() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');
    await _storage.write(key: 'remember_me', value: 'false');
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

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
}

class ClerkResult {
  final bool success;
  final String? status;
  final String? signInId;
  final String? error;
  ClerkResult({required this.success, this.status, this.signInId, this.error});
}
