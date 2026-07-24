import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clique/core/clients/api_service.dart';
import 'package:clique/core/clients/supabase_client.dart';
import 'package:clique/core/local_cache/local_cache_service.dart';
import 'package:clique/core/services/auth/auth_session_manager.dart';

class AuthService {
  final ApiService _api = ApiService();
  final AuthSessionManager _sessionManager = AuthSessionManager.instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<AuthResult> signInWithGoogle() async {
    try {
      final launched = await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.Clique.app://login-callback',
      );
      return AuthResult(
        success: launched,
        error: launched ? null : 'Unable to start Google sign in.',
      );
    } on AuthException catch (e) {
      return AuthResult(success: false, error: _handleAuthError(e));
    } catch (_) {
      return AuthResult(
        success: false,
        error: 'Unable to start Google sign in. Please try again.',
      );
    }
  }

  Future<AuthResult> signInWithApple() async {
    try {
      final launched = await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.Clique.app://login-callback',
      );
      return AuthResult(
        success: launched,
        error: launched ? null : 'Unable to start Apple sign in.',
      );
    } on AuthException catch (e) {
      return AuthResult(success: false, error: _handleAuthError(e));
    } catch (_) {
      return AuthResult(
        success: false,
        error: 'Unable to start Apple sign in. Please try again.',
      );
    }
  }

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
        await SupabaseConfig.client.auth.signOut();
        _api.clearAuthToken();
        return AuthResult(
          success: false,
          needsVerification: true,
          error: 'Please verify your email before logging in',
        );
      }

      _api.setAuthToken(token);

      // The backend derives identity from the verified Supabase access token.
      try {
        await _bootstrapBackendUser(user);
      } catch (_) {
        // Supabase remains the authentication source of truth. Backend calls
        // will surface their own connectivity error if it is unavailable.
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
      final trimmedFirstName = firstName.trim();
      final trimmedLastName = lastName.trim();

      final authResponse = await SupabaseConfig.client.auth.signUp(
        email: normalizedEmail,
        password: password,
        emailRedirectTo: 'com.Clique.app://verify-email',
        data: {
          'first_name': trimmedFirstName,
          'last_name': trimmedLastName,
          'full_name': [
            trimmedFirstName,
            trimmedLastName,
          ].where((part) => part.isNotEmpty).join(' '),
        },
      );

      final session = authResponse.session;
      final user = authResponse.user;

      if (user == null) {
        return AuthResult(
          success: false,
          error: 'Unable to create account. Please try again.',
        );
      }

      // Email confirmation is temporarily disabled in the app signup flow.
      // A session is still required because onboarding uses authenticated APIs.
      if (session == null) {
        return AuthResult(
          success: false,
          needsVerification: true,
          error: 'Account created, but no session was returned. Disable email '
              'confirmation in Supabase while verification is paused.',
        );
      }

      final token = session.accessToken;

      _api.setAuthToken(token);

      try {
        await _bootstrapBackendUser(
          user,
          firstName: trimmedFirstName,
          lastName: trimmedLastName,
        );
      } on DioException catch (e) {
        return AuthResult(
          success: false,
          error: _readBackendError(
            e.response?.data,
            'Account created, but profile setup failed. Please sign in again.',
          ),
        );
      } catch (_) {
        return AuthResult(
          success: false,
          error:
              'Account created, but profile setup failed. Please sign in again.',
        );
      }

      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('new_account_${user.id}', true);

      return AuthResult(
        success: true,
        token: token,
        user: {
          'id': user.id,
          'email': user.email,
          'firstName': trimmedFirstName,
          'lastName': trimmedLastName,
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
      await SupabaseConfig.client.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
        emailRedirectTo: 'com.Clique.app://verify-email',
      );

      return true;
    } on AuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: 'com.Clique.app://reset-password',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    _api.clearAuthToken();
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {}

    // Clear all stored credentials
    await _storage.deleteAll();
    await LocalCacheService.clearAll();
  }

  // GET CURRENT TOKEN
  Future<String?> getToken() async {
    try {
      final session = await _sessionManager.getFreshSession();
      return session?.accessToken;
    } catch (e) {
      return null;
    }
  }

  // AUTH CHECK
  Future<bool> isAuthenticated() async {
    try {
      final session = await _sessionManager.getFreshSession();
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

  Future<AuthResult> restoreSession() async {
    final snapshot = await _sessionManager.restoreSession();
    if (snapshot == null) {
      return AuthResult(success: false);
    }

    final token = snapshot.session.accessToken;
    _api.setAuthToken(token);
    try {
      final user = snapshot.user;
      if (user != null) await _bootstrapBackendUser(user);
    } catch (_) {
      // Restoring the local Supabase session must remain usable offline.
    }
    return AuthResult(
      success: true,
      token: token,
      user: _userMap(snapshot.user),
    );
  }

  AuthResult? currentSessionFallback() {
    final snapshot = _sessionManager.currentSnapshot;
    if (snapshot == null || snapshot.session.accessToken.isEmpty) return null;

    final token = snapshot.session.accessToken;
    _api.setAuthToken(token);
    return AuthResult(
      success: true,
      token: token,
      user: _userMap(snapshot.user),
    );
  }

  Map<String, dynamic>? _userMap(User? user) {
    if (user == null) return null;
    return {
      'id': user.id,
      'email': user.email,
      'firstName': user.userMetadata?['first_name'] ?? '',
      'lastName': user.userMetadata?['last_name'] ?? '',
    };
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
        'password': '',
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
          key: 'remember_me',
          value: 'true',
        );
        await _storage.delete(key: 'password');
      } else {
        await _storage.delete(key: 'email');
        await _storage.delete(key: 'password');
        await _storage.write(
          key: 'remember_me',
          value: 'false',
        );
      }
    } catch (_) {}
  }

  String _handleAuthError(AuthException e) {
    final rawMessage = _readAuthErrorMessage(e.message);
    final message = rawMessage.toLowerCase();
    if (message.contains('database error saving new user')) {
      return 'Signup is blocked by backend database setup. Please try again after the server is updated.';
    }
    if (rawMessage.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (rawMessage.contains('Email not confirmed')) {
      return 'Please verify your email first';
    }
    if (message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('user already registered')) {
      return 'An account already exists for this email. Please sign in instead.';
    }
    if (message.contains('password')) {
      return rawMessage;
    }
    return rawMessage;
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Network error. Please check your connection.';
    }
    return 'Service temporarily unavailable. Please try again.';
  }

  String _readBackendError(dynamic data, String fallback) {
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return fallback;
  }

  String _readAuthErrorMessage(String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map) {
        final errorMessage = decoded['message'] ?? decoded['msg'];
        if (errorMessage != null) return errorMessage.toString();
      }
    } catch (_) {
      // Supabase usually provides a plain message; JSON only appears for some
      // gateway/backend failures.
    }
    return message;
  }

  Future<Object?> verifyEmail(String email, String code) async {
    return SupabaseConfig.client.auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: code.trim(),
      type: OtpType.signup,
    );
  }

  Future<void> _bootstrapBackendUser(
    User user, {
    String? firstName,
    String? lastName,
  }) async {
    await _api.post(
      '/api/auth/bootstrap',
      data: {
        'firstName':
            (firstName ?? user.userMetadata?['first_name'] ?? '').toString(),
        'lastName':
            (lastName ?? user.userMetadata?['last_name'] ?? '').toString(),
      },
    );
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
}
