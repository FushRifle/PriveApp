import 'package:flutter/foundation.dart';
import 'package:social_media_app/data/services/auth/clerk_direct.dart';

class AuthHook extends ChangeNotifier {
  final ClerkDirectAuth _clerkAuth = ClerkDirectAuth();

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

  // Helper to notify listeners safely
  void _notify() {
    if (hasListeners) notifyListeners();
  }

  // Clear errors helper
  void _clearErrors() {
    _loginError = '';
    _verificationError = '';
  }

  // Reset loading state
  void _setLoading(bool value) {
    _loading = value;
    _notify();
  }

  // Initialize auth state
  Future<void> initialize() async {
    _isLoadingStorage = true;
    _notify();

    try {
      final hasToken = await _clerkAuth.isAuthenticated();
      if (hasToken) {
        _isTokenReady = true;
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
    final saved = await _clerkAuth.getSavedCredentials();
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
      _clerkAuth.saveCredentials('', '', false);
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
    if (_currentSignInId.isEmpty) {
      _verificationError = 'Session expired. Please login again';
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
      final result = await _clerkAuth.signIn(normalizedEmail, _password.trim());

      if (result.success) {
        await _saveCredentialsAndComplete(normalizedEmail);
        return true;
      }

      if (result.status == 'needs_verification') {
        return _handleVerificationRequired(result, isSignUp: false);
      }

      _loginError = result.error ?? 'Login failed';
      return false;
    } catch (e) {
      _loginError = 'Login failed. Please try again';
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
      final result = await _clerkAuth.signUp(
        normalizedEmail,
        _password.trim(),
        firstName,
        lastName,
      );

      if (result.success) {
        await _saveCredentialsAndComplete(normalizedEmail);
        return true;
      }

      if (result.status == 'needs_verification') {
        return _handleVerificationRequired(result, isSignUp: true);
      }

      _loginError = result.error ?? 'Signup failed';
      return false;
    } catch (e) {
      _loginError = 'Signup failed. Please try again';
      debugPrint('Signup error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveCredentialsAndComplete(String email) async {
    await _clerkAuth.saveCredentials(email, _password, _rememberMe);
  }

  bool _handleVerificationRequired(ClerkDirectResult result,
      {required bool isSignUp}) {
    _currentSignInId = result.signInId ?? '';
    _isSignUp = isSignUp;
    _showVerification = true;
    return false;
  }

  // Verification flow
  Future<bool> handleVerify() async {
    if (!_validateVerification()) return false;

    _setLoading(true);
    _verificationError = '';

    try {
      final result = await _clerkAuth.verify(
        _currentSignInId,
        _code.trim(),
        isSignUp: _isSignUp,
      );

      if (result.success) {
        await _clerkAuth.saveCredentials(_email, _password, _rememberMe);
        _resetVerificationState();
        return true;
      }

      _verificationError = result.error ?? 'Verification failed';
      return false;
    } catch (e) {
      _verificationError = 'Verification failed. Please try again';
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
    if (_currentSignInId.isEmpty) return;

    try {
      await _clerkAuth.resendCode(_currentSignInId, isSignUp: _isSignUp);
      // Optional: Show success message
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
    await _clerkAuth.signOut();
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
    return await _clerkAuth.isAuthenticated();
  }

  // Get auth token for API calls
  Future<String?> getAuthToken() async {
    return await _clerkAuth.getAuthToken();
  }

  // Clean up
  @override
  void dispose() {
    super.dispose();
  }
}
