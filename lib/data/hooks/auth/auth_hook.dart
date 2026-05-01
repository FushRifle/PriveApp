import 'package:flutter/foundation.dart';
import 'package:social_media_app/data/services/auth/clerk_auth_service.dart';

class AuthHook extends ChangeNotifier {
  final ClerkAuthService _clerkAuth = ClerkAuthService();

  String _email = '';
  String _password = '';
  bool _loading = false;
  bool _showPassword = false;
  String _code = '';
  bool _showVerification = false;
  String _verificationError = '';
  String _loginError = '';
  bool _rememberMe = false;
  bool _isLoadingStorage = true;
  bool _isTokenReady = false;
  String _savedEmail = '';
  String _savedPassword = '';
  String? _currentSignInId;
  bool _isSignUp = false;

  // Getters
  String get email => _email;
  String get password => _password;
  bool get loading => _loading;
  bool get showPassword => _showPassword;
  String get code => _code;
  bool get showVerification => _showVerification;
  String get verificationError => _verificationError;
  String get loginError => _loginError;
  bool get rememberMe => _rememberMe;
  bool get isLoadingStorage => _isLoadingStorage;
  bool get isTokenReady => _isTokenReady;
  String get savedEmail => _savedEmail;
  String get savedPassword => _savedPassword;
  bool get isLoaded => !_isLoadingStorage;

  void _notify() {
    if (hasListeners) notifyListeners();
  }

  Future<void> initialize() async {
    _isLoadingStorage = true;
    _notify();

    try {
      final hasToken = await _clerkAuth.isAuthenticated();
      if (hasToken) {
        _isTokenReady = true;
        _isLoadingStorage = false;
        _notify();
        return;
      }

      final saved = await _clerkAuth.getSavedCredentials();
      if (saved['rememberMe'] == true) {
        _rememberMe = true;
        _email = saved['email'] ?? '';
        _password = saved['password'] ?? '';
        _savedEmail = saved['email'] ?? '';
        _savedPassword = saved['password'] ?? '';
      }

      _isTokenReady = true;
    } catch (e) {
      debugPrint('Init error: $e');
    } finally {
      _isLoadingStorage = false;
      _notify();
    }
  }

  void updateEmail(String value) {
    _email = value;
    _loginError = '';
  }

  void updatePassword(String value) {
    _password = value;
    _loginError = '';
  }

  void toggleShowPassword() {
    _showPassword = !_showPassword;
    _notify();
  }

  void updateCode(String value) {
    _code = value;
    _verificationError = '';
  }

  void toggleRememberMe(bool value) {
    _rememberMe = value;
    if (!value) {
      _clerkAuth.saveCredentials('', '', false);
    }
    _notify();
  }

  Future<bool> handleLogin() async {
    final normalizedEmail = _email.trim().toLowerCase();
    final password = _password.trim();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      _loginError = 'Please enter both email and password';
      _notify();
      return false;
    }

    _loading = true;
    _loginError = '';
    _notify();

    try {
      final result = await _clerkAuth.signIn(normalizedEmail, password);

      if (result.success) {
        await _clerkAuth.saveCredentials(
            normalizedEmail, password, _rememberMe);
        _loading = false;
        _notify();
        return true;
      } else if (result.status == 'needs_verification') {
        _currentSignInId = result.signInId;
        _isSignUp = false;
        _showVerification = true;
        _loading = false;
        _notify();
        return false;
      } else {
        _loginError = result.error ?? 'Login failed';
        _loading = false;
        _notify();
        return false;
      }
    } catch (e) {
      _loginError = 'Login failed. Please try again.';
      _loading = false;
      _notify();
      return false;
    }
  }

  Future<bool> handleVerify() async {
    if (_code.trim().isEmpty) {
      _verificationError = 'Please enter the verification code';
      _notify();
      return false;
    }

    if (_currentSignInId == null) {
      _verificationError = 'Session expired. Please login again.';
      _notify();
      return false;
    }

    _loading = true;
    _verificationError = '';
    _notify();

    try {
      final result = await _clerkAuth.verify(
        _currentSignInId!,
        _code.trim(),
        isSignUp: _isSignUp,
      );

      if (result.success) {
        await _clerkAuth.saveCredentials(_email, _password, _rememberMe);
        _showVerification = false;
        _code = '';
        _loading = false;
        _notify();
        return true;
      } else {
        _verificationError = result.error ?? 'Verification failed';
        _loading = false;
        _notify();
        return false;
      }
    } catch (e) {
      _verificationError = 'Verification failed. Please try again.';
      _loading = false;
      _notify();
      return false;
    }
  }

  Future<void> resendCode() async {
    if (_currentSignInId == null) return;
    await _clerkAuth.resendCode(_currentSignInId!, isSignUp: _isSignUp);
  }

  void backToLogin() {
    _showVerification = false;
    _code = '';
    _verificationError = '';
    _notify();
  }

  Future<void> signOut() async {
    await _clerkAuth.signOut();
    _notify();
  }

  Future<bool> isAuthenticated() async {
    return await _clerkAuth.isAuthenticated();
  }
}
