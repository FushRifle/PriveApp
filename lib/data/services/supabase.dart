import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_media_app/data/services/api_service.dart'; // Add this

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _apiService = ApiService(); // Add this

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    // Save token after successful sign in
    if (response.session != null) {
      await _apiService.setToken(response.session!.accessToken);
      print('Token saved to ApiService');
    }

    return response;
  }

  Future<AuthResponse> signUp(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    final response = await _supabase.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'name': '$firstName $lastName'.trim(),
      },
    );

    // Save token after successful sign up (if session exists)
    if (response.session != null) {
      await _apiService.setToken(response.session!.accessToken);
      print('Token saved to ApiService');
    }

    return response;
  }

  Future<bool> verifyOtp({
    required String email,
    required String token,
  }) async {
    final res = await _supabase.auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: token.trim(),
      type: OtpType.signup,
    );

    // Save token after OTP verification (if session exists)
    if (res.session != null) {
      await _apiService.setToken(res.session!.accessToken);
      print('Token saved to ApiService after OTP');
    }

    return res.user != null;
  }

  Future<void> resendOtp(String email) {
    return _supabase.auth.resend(
      type: OtpType.signup,
      email: email.trim().toLowerCase(),
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _apiService.clearToken(); // Clear token on sign out
    print('Token cleared from ApiService');
  }

  bool isAuthenticated() {
    return _supabase.auth.currentSession != null;
  }

  User? get currentUser {
    return _supabase.auth.currentUser;
  }

  String? get accessToken {
    return _supabase.auth.currentSession?.accessToken;
  }

  Stream<AuthState> get authState {
    return _supabase.auth.onAuthStateChange;
  }

  Future<String?> getAuthToken() async {
    // First try to get from supabase session
    if (accessToken != null) {
      return accessToken;
    }
    // Fallback to stored token
    return await _apiService.getToken();
  }

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

  Future<void> saveCredentials(
    String email,
    String password,
    bool remember,
  ) async {
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
