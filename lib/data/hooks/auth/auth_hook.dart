import 'package:flutter/foundation.dart';
import 'package:social_media_app/app/configs/supabase.dart';

class AuthHook extends ChangeNotifier {
  final SupabaseAuthService _auth = SupabaseAuthService();

  // State management
  String _email = '';
  String _password = '';
  String _code = '';
  String _currentSignInId = '';
  bool _isSignUp = false;

  // UI states
  bool _loading = false;
  bool _showPassword = false;
  bool _showVerification = false;
  bool _rememberMe = false;
  bool _isLoadingStorage = true;
  bool _isTokenReady = false;

  // Error messages
  String _loginError = '';
  String _verificationError = '';

  // Saved credentials
  String _savedEmail = '';
  String _savedPassword = '';

  // Getters
  String get email => _email;
  String get password => _password;
  String get code => _code;
  String get currentSignInId => _currentSignInId;
  bool get isSignUp => _isSignUp;
  bool get loading => _loading;
  bool get showPassword => _showPassword;
  bool get showVerification => _showVerification;
  bool get rememberMe => _rememberMe;
  bool get isLoadingStorage => _isLoadingStorage;
  bool get isTokenReady => _isTokenReady;
  bool get isLoaded => !_isLoadingStorage;
  String get loginError => _loginError;
  String get verificationError => _verificationError;
  String get savedEmail => _savedEmail;
  String get savedPassword => _savedPassword;

  void _notify() {
    if (hasListeners) notifyListeners();
  }

  void _clearErrors() {
    _loginError = '';
    _verificationError = '';
  }

  void _setLoading(bool value) {
    _loading = value;
    _notify();
  }

  Future<void> initialize() async {
    _isLoadingStorage = true;
    _notify();

    try {
      final hasToken = _auth.isAuthenticated();
      if (hasToken) {
        _isTokenReady = true;
        _isLoadingStorage = false;
        _notify();
        return;
      }

      await _loadSavedCredentials();
      _isTokenReady = true;
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoadingStorage = false;
      _notify();
    }
  }

  Future<void> _loadSavedCredentials() async {
    final saved = await _auth.getSavedCredentials();

    if (saved['rememberMe'] == true) {
      _rememberMe = true;
      _email = saved['email'] ?? '';
      _password = saved['password'] ?? '';
      _savedEmail = saved['email'] ?? '';
      _savedPassword = saved['password'] ?? '';
    }
  }

  // Field updates
  void updateEmail(String value) {
    if (_email == value) return;
    _email = value;
    _loginError = '';
    _notify();
  }

  void updatePassword(String value) {
    if (_password == value) return;
    _password = value;
    _loginError = '';
    _notify();
  }

  void updateCode(String value) {
    if (_code == value) return;
    _code = value;
    _verificationError = '';
    _notify();
  }

  void toggleShowPassword() {
    _showPassword = !_showPassword;
    _notify();
  }

  void toggleRememberMe(bool value) {
    if (_rememberMe == value) return;

    _rememberMe = value;

    if (!value) {
      _auth.saveCredentials('', '', false);
    }

    _notify();
  }

  // Validation helpers
  bool _validateLogin() {
    if (_email.trim().isEmpty || _password.trim().isEmpty) {
      _loginError = 'Please enter both email and password';
      _notify();
      return false;
    }
    return true;
  }

  bool _validateVerification() {
    if (_code.trim().isEmpty) {
      _verificationError = 'Please enter the verification code';
      _notify();
      return false;
    }

    return true;
  }

  // Login flow
  Future<bool> handleLogin() async {
    if (!_validateLogin()) return false;

    _setLoading(true);
    _clearErrors();

    try {
      final normalizedEmail = _email.trim().toLowerCase();

      final result = await _auth.signIn(
        normalizedEmail,
        _password.trim(),
      );

      if (result.user != null) {
        await _saveCredentialsAndComplete(normalizedEmail);
        _isTokenReady = true;
        return true;
      }

      _loginError = 'Login failed';
      return false;
    } catch (e) {
      _loginError = e.toString();
      debugPrint('Login error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Signup flow
  Future<bool> handleSignup({
    required String firstName,
    required String lastName,
  }) async {
    if (!_validateLogin()) return false;

    _setLoading(true);
    _clearErrors();

    try {
      final normalizedEmail = _email.trim().toLowerCase();

      final result = await _auth.signUp(
        normalizedEmail,
        _password.trim(),
        firstName,
        lastName,
      );

      if (result.user != null) {
        // Supabase email confirmation flow
        if (result.session == null) {
          _showVerification = true;
          _isSignUp = true;
          return false;
        }

        await _saveCredentialsAndComplete(normalizedEmail);
        _isTokenReady = true;
        return true;
      }

      _loginError = 'Signup failed';
      return false;
    } catch (e) {
      _loginError = e.toString();
      debugPrint('Signup error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveCredentialsAndComplete(String email) async {
    await _auth.saveCredentials(email, _password, _rememberMe);
  }

  // Verification flow
  Future<bool> handleVerify() async {
    if (!_validateVerification()) return false;

    _setLoading(true);
    _verificationError = '';

    try {
      final success = await _auth.verifyOtp(
        email: _email.trim().toLowerCase(),
        token: _code.trim(),
      );

      if (success) {
        await _auth.saveCredentials(_email, _password, _rememberMe);
        _resetVerificationState();
        _isTokenReady = true;
        return true;
      }

      _verificationError = 'Verification failed';
      return false;
    } catch (e) {
      _verificationError = e.toString();
      debugPrint('Verification error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _resetVerificationState() {
    _showVerification = false;
    _code = '';
    _verificationError = '';
    _currentSignInId = '';
    _notify();
  }

  // Resend code
  Future<void> resendCode() async {
    try {
      await _auth.resendOtp(_email.trim().toLowerCase());
    } catch (e) {
      debugPrint('Resend code error: $e');
    }
  }

  // Navigation helpers
  void backToLogin() {
    _resetVerificationState();
  }

  // Session management
  Future<void> signOut() async {
    await _auth.signOut();
    _resetToInitialState();
    _notify();
  }

  void _resetToInitialState() {
    _email = '';
    _password = '';
    _code = '';
    _currentSignInId = '';
    _isSignUp = false;
    _showPassword = false;
    _showVerification = false;
    _loginError = '';
    _verificationError = '';
    _isTokenReady = false;
  }

  Future<bool> isAuthenticated() async {
    return _auth.isAuthenticated();
  }

  Future<String?> getAuthToken() async {
    return _auth.accessToken;
  }
}
