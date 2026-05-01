import 'package:flutter/foundation.dart';
import 'package:social_media_app/data/services/auth/clerk_auth_service.dart';

class RegisterHook extends ChangeNotifier {
  final ClerkAuthService _clerkAuth = ClerkAuthService();

  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _fullName = '';
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _code = '';
  bool _showVerification = false;
  String _verificationError = '';
  String _registerError = '';
  String? _currentSignUpId;

  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get fullName => _fullName;
  bool get loading => _loading;
  bool get showPassword => _showPassword;
  bool get showConfirmPassword => _showConfirmPassword;
  String get code => _code;
  bool get showVerification => _showVerification;
  String get verificationError => _verificationError;
  String get registerError => _registerError;

  void updateForm(String key, String value) {
    switch (key) {
      case 'email':
        _email = value;
      case 'password':
        _password = value;
      case 'confirmPassword':
        _confirmPassword = value;
      case 'fullName':
        _fullName = value;
    }
    _registerError = '';
    notifyListeners();
  }

  void toggleShowPassword() {
    _showPassword = !_showPassword;
    notifyListeners();
  }

  void toggleShowConfirmPassword() {
    _showConfirmPassword = !_showConfirmPassword;
    notifyListeners();
  }

  void updateCode(String value) {
    _code = value;
    _verificationError = '';
  }

  bool validateForm() {
    if (_fullName.trim().isEmpty) {
      _registerError = 'Please enter your full name';
      notifyListeners();
      return false;
    }
    if (_email.trim().isEmpty) {
      _registerError = 'Please enter your email address';
      notifyListeners();
      return false;
    }
    if (_password.trim().isEmpty) {
      _registerError = 'Please enter a password';
      notifyListeners();
      return false;
    }
    if (_password.length < 8) {
      _registerError = 'Password must be at least 8 characters';
      notifyListeners();
      return false;
    }
    if (_password != _confirmPassword) {
      _registerError = 'Passwords do not match';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> handleRegister() async {
    if (!validateForm()) return false;

    _loading = true;
    _registerError = '';
    notifyListeners();

    try {
      final firstName = _fullName.trim().split(' ').first;
      final lastName = _fullName.trim().split(' ').skip(1).join(' ');

      final result = await _clerkAuth.signUp(
        _email.trim(),
        _password,
        firstName,
        lastName.isEmpty ? '' : lastName,
      );

      if (result.status == 'needs_verification') {
        _currentSignUpId = result.signInId;
        _showVerification = true;
        _loading = false;
        notifyListeners();
        return false;
      } else if (result.success) {
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _registerError = result.error ?? 'Registration failed';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _registerError = 'Registration failed. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> handleVerify() async {
    if (_code.trim().isEmpty) {
      _verificationError = 'Please enter the verification code';
      notifyListeners();
      return false;
    }

    if (_currentSignUpId == null) {
      _verificationError = 'Session expired. Please register again.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _verificationError = '';
    notifyListeners();

    try {
      final result = await _clerkAuth.verify(
        _currentSignUpId!,
        _code.trim(),
        isSignUp: true,
      );

      if (result.success) {
        _showVerification = false;
        _code = '';
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _verificationError = result.error ?? 'Verification failed';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _verificationError = 'Invalid verification code. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> resendCode() async {
    if (_currentSignUpId == null) return;
    await _clerkAuth.resendCode(_currentSignUpId!, isSignUp: true);
  }

  void backToRegister() {
    _showVerification = false;
    _code = '';
    _verificationError = '';
    notifyListeners();
  }
}
