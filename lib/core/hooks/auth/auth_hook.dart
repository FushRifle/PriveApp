import 'package:flutter/foundation.dart';
import 'package:clique/core/services/auth/auth_service.dart';

class AuthHook extends ChangeNotifier {
  final AuthService _auth = AuthService();

  // State management
  String _email = '';
  String _password = '';
  String _code = '';
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
    debugPrint('[AuthHook] Initializing...');
    _isLoadingStorage = true;
    _notify();

    try {
      final hasToken = await _auth.isAuthenticated();
      debugPrint('[AuthHook] Has token: $hasToken');

      if (hasToken) {
        _isTokenReady = true;
      } else {
        await _loadSavedCredentials();
        _isTokenReady = true;
      }
    } catch (e) {
      debugPrint('[AuthHook] Initialization error: $e');
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoadingStorage = false;
      _notify();
      debugPrint(
          '[AuthHook] Initialization complete, isTokenReady: $_isTokenReady');
    }
  }

  Future<void> _loadSavedCredentials() async {
    debugPrint('[AuthHook] Loading saved credentials...');
    final saved = await _auth.getSavedCredentials();
    debugPrint(
        '[AuthHook] Saved credentials: rememberMe=${saved['rememberMe']}, email=${saved['email']}');

    if (saved['rememberMe'] == true) {
      _rememberMe = true;
      _email = saved['email'] ?? '';
      _password = saved['password'] ?? '';
      _savedEmail = saved['email'] ?? '';
      _savedPassword = saved['password'] ?? '';
      debugPrint('[AuthHook] Loaded credentials for: $_email');
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
      debugPrint('[AuthHook] Remember me disabled, clearing credentials');
      _auth.saveCredentials('', '', false);
    }

    _notify();
  }

  void backToLogin() {
    _resetVerificationState();
  }

  void _resetVerificationState() {
    _showVerification = false;
    _code = '';
    _verificationError = '';
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
    debugPrint('[AuthHook] handleLogin called for: $_email');

    if (!_validateLogin()) {
      debugPrint('[AuthHook] Login validation failed');
      return false;
    }

    _setLoading(true);
    _clearErrors();

    try {
      final normalizedEmail = _email.trim().toLowerCase();
      debugPrint('[AuthHook] Attempting sign in for: $normalizedEmail');

      final result = await _auth.signIn(
        normalizedEmail,
        _password.trim(),
      );

      debugPrint(
          '[AuthHook] Sign in result - success: ${result.success}, error: ${result.error}');

      if (result.success) {
        debugPrint('[AuthHook] Sign in successful, saving credentials');
        await _saveCredentialsAndComplete(normalizedEmail);
        _isTokenReady = true;
        return true;
      }

      // Check if email verification is needed
      if (result.error?.contains('verify') == true ||
          result.error?.contains('confirmation') == true) {
        debugPrint('[AuthHook] Email verification needed');
        _showVerification = true;
        _isSignUp = false;
        return false;
      }

      _loginError = result.error ?? 'Login failed';
      debugPrint('[AuthHook] Login failed: $_loginError');
      return false;
    } catch (e) {
      _loginError = e.toString();
      debugPrint('[AuthHook] Login exception: $e');
      debugPrint('Login error: $e');
      return false;
    } finally {
      _setLoading(false);
      debugPrint('[AuthHook] Login completed, loading: $_loading');
    }
  }

  // Signup flow
  Future<bool> handleSignup({
    required String firstName,
    required String lastName,
  }) async {
    debugPrint(
        '[AuthHook] handleSignup called for: $_email, firstName: $firstName, lastName: $lastName');

    if (!_validateLogin()) {
      debugPrint('[AuthHook] Signup validation failed');
      return false;
    }

    _setLoading(true);
    _clearErrors();

    try {
      final normalizedEmail = _email.trim().toLowerCase();
      debugPrint('[AuthHook] Attempting sign up for: $normalizedEmail');

      final result = await _auth.signUp(
        email: normalizedEmail,
        password: _password.trim(),
        firstName: firstName,
        lastName: lastName,
      );

      debugPrint(
          '[AuthHook] Sign up result - success: ${result.success}, error: ${result.error}');

      if (result.success) {
        debugPrint('[AuthHook] Sign up successful, saving credentials');
        await _saveCredentialsAndComplete(normalizedEmail);
        _isTokenReady = true;
        return true;
      }

      // Check if email verification is needed
      if (result.error?.contains('verify') == true ||
          result.error?.contains('confirmation') == true) {
        debugPrint('[AuthHook] Email verification needed for signup');
        _showVerification = true;
        _isSignUp = true;
        return false;
      }

      _loginError = result.error ?? 'Signup failed';
      debugPrint('[AuthHook] Signup failed: $_loginError');
      return false;
    } catch (e) {
      _loginError = e.toString();
      debugPrint('[AuthHook] Signup exception: $e');
      debugPrint('Signup error: $e');
      return false;
    } finally {
      _setLoading(false);
      debugPrint('[AuthHook] Signup completed, loading: $_loading');
    }
  }

  // Verification flow
  Future<bool> handleVerify() async {
    debugPrint('[AuthHook] handleVerify called with code: $_code');

    if (!_validateVerification()) {
      debugPrint('[AuthHook] Verification validation failed');
      return false;
    }

    _setLoading(true);
    _verificationError = '';

    try {
      // Since your backend handles verification automatically,
      // this is a placeholder. If verification is needed, you'd call:
      // final result = await _auth.verify(_code.trim());

      // For now, just simulate verification
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('[AuthHook] Verification simulated success');

      _resetVerificationState();
      _isTokenReady = true;
      return true;
    } catch (e) {
      _verificationError = e.toString();
      debugPrint('[AuthHook] Verification error: $e');
      debugPrint('Verification error: $e');
      return false;
    } finally {
      _setLoading(false);
      debugPrint('[AuthHook] Verification completed, loading: $_loading');
    }
  }

  // Resend code
  Future<void> resendCode() async {
    debugPrint('[AuthHook] resendCode requested');
    try {
      // Placeholder for resend functionality
      debugPrint('Resend code requested');
    } catch (e) {
      debugPrint('[AuthHook] Resend code error: $e');
      debugPrint('Resend code error: $e');
    }
  }

  Future<void> _saveCredentialsAndComplete(String email) async {
    debugPrint(
        '[AuthHook] Saving credentials - email: $email, rememberMe: $_rememberMe');
    await _auth.saveCredentials(email, _password, _rememberMe);
    debugPrint('[AuthHook] Credentials saved');
  }

  // Session management
  Future<void> signOut() async {
    debugPrint('[AuthHook] Signing out');
    await _auth.signOut();
    _resetToInitialState();
    _notify();
    debugPrint('[AuthHook] Sign out complete');
  }

  void _resetToInitialState() {
    debugPrint('[AuthHook] Resetting to initial state');
    _email = '';
    _password = '';
    _code = '';
    _isSignUp = false;
    _showPassword = false;
    _showVerification = false;
    _loginError = '';
    _verificationError = '';
    _isTokenReady = false;
  }

  Future<bool> isAuthenticated() async {
    final authenticated = await _auth.isAuthenticated();
    debugPrint('[AuthHook] isAuthenticated: $authenticated');
    return authenticated;
  }

  Future<String?> getAuthToken() async {
    final token = await _auth.getToken();
    debugPrint(
        '[AuthHook] getAuthToken - exists: ${token != null}, length: ${token?.length ?? 0}');
    return token;
  }
}
