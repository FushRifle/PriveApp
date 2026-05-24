import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clique/app/configs/api_config.dart';
import 'package:clique/core/supabase_client.dart';

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

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

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

      // Check if email is verified
      if (user.confirmedAt == null) {
        return AuthResult(
          success: false,
          needsVerification: true,
          error: 'Please verify your email before logging in',
        );
      }

      // Backend sync (optional, don't fail if backend is down)
      try {
        await _dio.post(
          '/api/auth/signin',
          data: {
            'email': normalizedEmail,
            'password': password,
          },
        );
      } catch (e) {
        // Log but don't fail - Supabase is the source of truth
        print('Backend sync failed: $e');
      }

      return AuthResult(
        success: true,
        token: token,
        user: {
          'id': user.id,
          'email': user.email,
          'firstName': user.userMetadata?['first_name'] ?? '',
          'lastName': user.userMetadata?['last_name'] ?? '',
        },
      );
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        error: _handleAuthError(e),
      );
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        error: _handleDioError(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Unable to connect. Please check your internet connection.',
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
      if (session == null || user?.confirmedAt == null) {
        return AuthResult(
          success: false,
          needsVerification: true,
          error: 'Verification email sent. Please verify your email.',
        );
      }

      final token = session.accessToken;

      // Backend sync (optional)
      try {
        await _dio.post(
          '/api/auth/signup',
          data: {
            'email': normalizedEmail,
            'password': password,
            'firstName': firstName,
            'lastName': lastName,
          },
        );
      } catch (e) {
        print('Backend sync failed: $e');
      }

      return AuthResult(
        success: true,
        token: token,
        user: {
          'id': user?.id,
          'email': user?.email,
          'firstName': firstName,
          'lastName': lastName,
        },
      );
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        error: _handleAuthError(e),
      );
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        error: _handleDioError(e),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Unable to create account. Please try again.',
      );
    }
  }

  // RESEND VERIFICATION
  Future<bool> resendVerification(String email) async {
    try {
      final tempPassword = 'Temp_${DateTime.now().millisecondsSinceEpoch}';
      await SupabaseConfig.client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: tempPassword,
        emailRedirectTo: 'com.clique.app://verify-email',
      );

      return true;
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        return false;
      }
      print('Resend verification error: $e');
      return false;
    } catch (e) {
      print('Failed to resend verification: $e');
      return false;
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {}

    // Clear all stored credentials
    await _storage.deleteAll();
  }

  // GET CURRENT TOKEN
  Future<String?> getToken() async {
    try {
      final session = SupabaseConfig.client.auth.currentSession;
      return session?.accessToken;
    } catch (e) {
      return null;
    }
  }

  // AUTH CHECK
  Future<bool> isAuthenticated() async {
    try {
      final session = SupabaseConfig.client.auth.currentSession;
      return session != null && session.accessToken.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // GET CURRENT USER
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return null;

      return {
        'id': user.id,
        'email': user.email,
        'firstName': user.userMetadata?['first_name'] ?? '',
        'lastName': user.userMetadata?['last_name'] ?? '',
      };
    } catch (e) {
      return null;
    }
  }

  // GET SAVED CREDENTIALS
  Future<Map<String, dynamic>> getSavedCredentials() async {
    try {
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
    } catch (e) {
      return {
        'rememberMe': false,
        'email': '',
        'password': '',
      };
    }
  }

  // SAVE REMEMBER ME CREDENTIALS
  Future<void> saveCredentials(
    String email,
    String password,
    bool remember,
  ) async {
    try {
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
      } else {
        await _storage.delete(key: 'email');
        await _storage.delete(key: 'password');
        await _storage.write(
          key: 'remember_me',
          value: 'false',
        );
      }
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  String _handleAuthError(AuthException e) {
    if (e.message.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (e.message.contains('Email not confirmed')) {
      return 'Please verify your email first';
    }
    return e.message;
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Network error. Please check your connection.';
    }
    return 'Service temporarily unavailable. Please try again.';
  }

  Future<Object?> verifyEmail(String email, String code) async {}
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
}
