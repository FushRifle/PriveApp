import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/app/resources/constant/named_routes.dart';
import 'package:social_media_app/data/hooks/auth/auth_hook.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final AuthHook _authHook = AuthHook();
  bool _obscurePassword = true;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _authHook.initialize();

    if (!mounted) return;

    if (_authHook.savedEmail.isNotEmpty) {
      _emailController.text = _authHook.savedEmail;
    }
    if (_authHook.savedPassword.isNotEmpty) {
      _passwordController.text = _authHook.savedPassword;
    }

    setState(() => _isInitializing = false);

    if (_authHook.isTokenReady) {
      final isAuth = await _authHook.isAuthenticated();
      if (isAuth && mounted) {
        Navigator.pushReplacementNamed(context, NamedRoutes.homeScreen);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _authHook.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    if (_isInitializing || _authHook.isLoadingStorage) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _authHook,
          builder: (context, _) {
            return _authHook.showVerification
                ? _buildVerificationView()
                : _buildLoginView();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/prive.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppColors.purpleColor,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/images/prive.png',
                    width: 80, height: 80, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text('Welcome Back',
              style: AppTheme.blackTextStyle
                  .copyWith(fontWeight: AppTheme.bold, fontSize: 32)),
          const SizedBox(height: 8),
          Text('Sign in to continue',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 40),
          _buildInputField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => _authHook.updateEmail(value),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outlined,
            obscureText: _obscurePassword,
            onChanged: (value) => _authHook.updatePassword(value),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.greyColor),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 16),
          // Reactive error
          ListenableBuilder(
            listenable: _authHook,
            builder: (_, __) {
              if (_authHook.loginError.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.redColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.redColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_authHook.loginError,
                            style: AppTheme.blackTextStyle.copyWith(
                                color: AppColors.redColor, fontSize: 13))),
                  ],
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        _authHook.toggleRememberMe(!_authHook.rememberMe),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _authHook.rememberMe
                                ? AppColors.purpleColor
                                : AppColors.greyColor,
                            width: 2),
                        color: _authHook.rememberMe
                            ? AppColors.purpleColor
                            : Colors.transparent,
                      ),
                      child: _authHook.rememberMe
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Remember me',
                      style: AppTheme.blackTextStyle
                          .copyWith(fontSize: 14, fontWeight: AppTheme.medium)),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Text('Forgot Password?',
                    style: AppTheme.blackTextStyle.copyWith(
                        color: AppColors.purpleColor,
                        fontWeight: AppTheme.bold,
                        fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Reactive button
          ListenableBuilder(
            listenable: _authHook,
            builder: (_, __) {
              return GestureDetector(
                onTap: _authHook.loading ? null : _handleLogin,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primary,
                      AppColors.secondary.withOpacity(0.8)
                    ]),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: _authHook.loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Sign In',
                            style: AppTheme.whiteTextStyle.copyWith(
                                fontWeight: AppTheme.bold, fontSize: 18)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: Container(
                      height: 1, color: AppColors.greyColor.withOpacity(0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('or continue with',
                    style: AppTheme.greyTextStyle.copyWith(fontSize: 14)),
              ),
              Expanded(
                  child: Container(
                      height: 1, color: AppColors.greyColor.withOpacity(0.3))),
            ],
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildSocialButton(
                icon: Icons.g_mobiledata, color: Colors.red, onTap: () {}),
            const SizedBox(width: 20),
            _buildSocialButton(
                icon: Icons.apple, color: Colors.black, onTap: () {}),
            const SizedBox(width: 20),
            _buildSocialButton(
                icon: Icons.facebook, color: Colors.blue, onTap: () {}),
          ]),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Don't have an account? ",
                style: AppTheme.greyTextStyle.copyWith(fontSize: 14)),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushReplacementNamed(
                    context, NamedRoutes.registerScreen);
              },
              child: Text('Sign Up',
                  style: AppTheme.blackTextStyle.copyWith(
                      color: AppColors.purpleColor,
                      fontWeight: AppTheme.bold,
                      fontSize: 14)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildVerificationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _authHook.backToLogin(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.black, size: 18),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: AppColors.purpleColor.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.email_outlined,
                  color: AppColors.purpleColor, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          Text('Verify Your Email',
              style: AppTheme.blackTextStyle
                  .copyWith(fontWeight: AppTheme.bold, fontSize: 28)),
          const SizedBox(height: 8),
          Text("We've sent a verification code to your email",
              style: AppTheme.greyTextStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 32),
          _buildInputField(
            controller: _codeController,
            label: 'Verification Code',
            hint: 'Enter 6-digit code',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            onChanged: (value) => _authHook.updateCode(value),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _authHook,
            builder: (_, __) {
              if (_authHook.verificationError.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.redColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.redColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_authHook.verificationError,
                            style: AppTheme.blackTextStyle.copyWith(
                                color: AppColors.redColor, fontSize: 13))),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: _authHook,
            builder: (_, __) {
              return GestureDetector(
                onTap: _authHook.loading ? null : _handleVerify,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.purpleColor,
                      AppColors.purpleColor.withOpacity(0.8)
                    ]),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: _authHook.loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Verify',
                            style: AppTheme.whiteTextStyle.copyWith(
                                fontWeight: AppTheme.bold, fontSize: 18)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => _authHook.resendCode(),
              child: Text('Resend Code',
                  style: AppTheme.blackTextStyle.copyWith(
                      color: AppColors.purpleColor,
                      fontWeight: AppTheme.bold,
                      fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTheme.blackTextStyle
                .copyWith(fontWeight: AppTheme.medium, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.greyColor.withOpacity(0.2), width: 1),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: AppTheme.blackTextStyle.copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 14),
              prefixIcon: Icon(icon, color: AppColors.greyColor, size: 20),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.greyColor.withOpacity(0.2), width: 1),
        ),
        child: Center(child: Icon(icon, size: 30, color: color)),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final success = await _authHook.handleLogin();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, NamedRoutes.homeScreen);
    }
  }

  Future<void> _handleVerify() async {
    final success = await _authHook.handleVerify();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, NamedRoutes.homeScreen);
    }
  }
}
