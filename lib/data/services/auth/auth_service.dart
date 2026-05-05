import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Prive/app/configs/api_config.dart';
import 'package:Prive/core/supabase_client.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 600,
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // SIGN IN
  Future<AuthResult> signIn(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // Supabase primary authentication
      final authResponse = await SupabaseConfig.client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      final session = authResponse.session;
      final user = authResponse.user;

      if (session == null || user == null) {
        return AuthResult(
          success: false,
          error: 'Authentication failed',
        );
      }

      final token = session.accessToken;

      // Backend sync / user bootstrap
      final backendResponse = await _dio.post(
        '/api/auth/signin',
        data: {
          'email': normalizedEmail,
          'password': password,
        },
      );

      final backendData = backendResponse.data;

      return AuthResult(
        success: true,
        token: token,
        user: backendData['user'] ??
            {
              'id': user.id,
              'email': user.email,
            },
      );
    } on AuthApiException catch (e) {
      return AuthResult(
        success: false,
        error: e.message,
      );
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        error: _handleError(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Unexpected authentication error: $e',
      );
    }
  }

  // SIGN UP
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final authResponse = await SupabaseConfig.client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      final session = authResponse.session;
      final user = authResponse.user;

      // Email verification required
      if (session == null) {
        return AuthResult(
          success: false,
          needsVerification: true,
          error: 'Please verify your email before logging in',
        );
      }

      final token = session.accessToken;

      // Backend sync
      await _dio.post(
        '/api/auth/signup',
        data: {
          'email': normalizedEmail,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        },
      );

      return AuthResult(
        success: true,
        token: token,
        user: {
          'id': user?.id,
          'email': user?.email,
        },
      );
    } on AuthApiException catch (e) {
      return AuthResult(
        success: false,
        error: e.message,
      );
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        error: _handleError(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Unexpected signup error: $e',
      );
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {}

    await _storage.delete(key: 'remember_me');
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');
  }

  // GET CURRENT TOKEN
  Future<String?> getToken() async {
    return SupabaseConfig.client.auth.currentSession?.accessToken;
  }

  // AUTH CHECK
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // GET SAVED CREDENTIALS
  Future<Map<String, dynamic>> getSavedCredentials() async {
    final rememberMe = await _storage.read(key: 'remember_me') == 'true';

    if (!rememberMe) {
      return {
        'rememberMe': false,
        'email': '',
        'password': '',
      };
    }

    return {
      'rememberMe': true,
      'email': await _storage.read(key: 'email') ?? '',
      'password': await _storage.read(key: 'password') ?? '',
    };
  }

  // SAVE REMEMBER ME CREDENTIALS
  Future<void> saveCredentials(
    String email,
    String password,
    bool remember,
  ) async {
    if (remember) {
      await _storage.write(
        key: 'email',
        value: email.trim().toLowerCase(),
      );

      await _storage.write(
        key: 'password',
        value: password,
      );

      await _storage.write(
        key: 'remember_me',
        value: 'true',
      );

      return;
    }

    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');

    await _storage.write(
      key: 'remember_me',
      value: 'false',
    );
  }

  // ERROR HANDLER
  String _handleError(DioException e) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['error'] != null) {
        return data['error'].toString();
      }
    }

    switch (e.response?.statusCode) {
      case 400:
        return 'Invalid request';
      case 401:
        return 'Invalid email or password';
      case 403:
        return 'Access denied';
      case 404:
        return 'Service unavailable';
      case 409:
        return 'User already exists';
      case 422:
        return 'Invalid form submission';
      case 500:
        return 'Server error';
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Request timeout';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond';
      case DioExceptionType.badCertificate:
        return 'Security certificate error';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return 'Network error. Check your connection';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}

class AuthResult {
  final bool success;
  final String? token;
  final Map<String, dynamic>? user;
  final String? error;
  final bool needsVerification;

  AuthResult({
    required this.success,
    this.token,
    this.user,
    this.error,
    this.needsVerification = false,
  });

  AuthResult copyWith({
    bool? success,
    String? token,
    Map<String, dynamic>? user,
    String? error,
    bool? needsVerification,
  }) {
    return AuthResult(
      success: success ?? this.success,
      token: token ?? this.token,
      user: user ?? this.user,
      error: error ?? this.error,
      needsVerification: needsVerification ?? this.needsVerification,
    );
  }
}
