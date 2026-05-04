import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<AuthResponse> signIn(String email, String password) {
    return _supabase.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<AuthResponse> signUp(
    String email,
    String password,
    String firstName,
    String lastName,
  ) {
    return _supabase.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'name': '$firstName $lastName'.trim(),
      },
    );
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

    return res.user != null;
  }

  Future<void> resendOtp(String email) {
    return _supabase.auth.resend(
      type: OtpType.signup,
      email: email.trim().toLowerCase(),
    );
  }

  Future<void> signOut() {
    return _supabase.auth.signOut();
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
    return accessToken;
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
