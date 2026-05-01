import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:social_media_app/app/configs/api_config.dart';

class ClerkAuthService {
  // Use YOUR specific Clerk Frontend API URL + publishable key
  final Dio _clerk = Dio(BaseOptions(
    baseUrl: ApiConfig.clerkFrontendUrl,
    connectTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${ApiConfig.clerkPublishableKey}',
    },
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<ClerkResult> signIn(String email, String password) async {
    try {
      final res = await _clerk.post('/client/sign_ins', data: {
        'identifier': email.trim().toLowerCase(),
        'password': password,
      });
      final body = res.data['response'] ?? res.data;

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

  Future<ClerkResult> signUp(
      String email, String password, String firstName, String lastName) async {
    try {
      final res = await _clerk.post('/client/sign_ups', data: {
        'email_address': email.trim().toLowerCase(),
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });
      final body = res.data['response'] ?? res.data;

      if (body['status'] == 'missing_requirements') {
        await _clerk.post('/client/sign_ups/${body['id']}/prepare_verification',
            data: {'strategy': 'email_code'});
        return ClerkResult(
            success: false, status: 'needs_verification', signInId: body['id']);
      }

      return ClerkResult(success: false, error: 'Status: ${body['status']}');
    } on DioException catch (e) {
      return ClerkResult(success: false, error: _handleError(e));
    }
  }

  Future<ClerkResult> verify(String signInId, String code,
      {required bool isSignUp}) async {
    try {
      final path = isSignUp
          ? '/client/sign_ups/$signInId/attempt_verification'
          : '/client/sign_ins/$signInId/attempt_second_factor';

      final res = await _clerk.post(path, data: {
        'strategy': 'email_code',
        'code': code.trim(),
      });
      final body = res.data['response'] ?? res.data;

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

  Future<void> resendCode(String signInId, {required bool isSignUp}) async {
    final path = isSignUp
        ? '/client/sign_ups/$signInId/prepare_verification'
        : '/client/sign_ins/$signInId/prepare_second_factor';
    await _clerk.post(path, data: {'strategy': 'email_code'});
  }

  Future<void> signOut() async {
    await _storage.delete(key: 'auth_token');
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

  Future<String?> _getToken(String sessionId) async {
    try {
      final res = await _clerk.get('/client/sessions/$sessionId/token');
      return res.data['jwt'] ?? res.data['response']?['jwt'];
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  String _handleError(DioException e) {
    final data = e.response?.data;
    final body = data is Map ? (data['response'] ?? data) : null;
    if (body != null && body['errors'] is List && body['errors'].isNotEmpty) {
      final msg = body['errors'][0]['message']?.toString() ?? '';
      if (msg.contains('identifier')) return 'No account found';
      if (msg.contains('password')) return 'Incorrect password';
      return msg.isNotEmpty ? msg : 'Login failed';
    }
    return 'Network error. Check your connection.';
  }
}

class ClerkResult {
  final bool success;
  final String? status;
  final String? signInId;
  final String? error;
  ClerkResult({required this.success, this.status, this.signInId, this.error});
}
