import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    final authBloc = context.read<AuthBloc>();
    authBloc.add(LoadSavedCredentials());

    // Wait for credentials to load
    Future.delayed(const Duration(milliseconds: 100), () {
      final state = authBloc.state;
      if (state.savedCredentials['rememberMe'] == true) {
        setState(() {
          _rememberMe = true;
          _emailController.text = state.savedCredentials['email'] ?? '';
          _passwordController.text = state.savedCredentials['password'] ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              Navigator.pushReplacementNamed(context, NamedRoutes.homeScreen);
            } else if (state.status == AuthStatus.error &&
                state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: AppColors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
              // Clear error after showing
              context.read<AuthBloc>().add(ClearAuthError());
            }
          },
          builder: (context, state) {
            if (state.status == AuthStatus.loading &&
                state.isLoading &&
                _emailController.text.isEmpty) {
              return _buildLoadingScreen();
            }

            if (state.needsVerification) {
              return _buildVerificationView(state);
            }

            return _buildLoginView(state);
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
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icons/clique-new.png',
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
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginView(AuthState state) {
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
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/icons/clique-new.png',
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
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outlined,
            obscureText: _obscurePassword,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _rememberMe
                                ? AppColors.primary
                                : AppColors.greyColor,
                            width: 2),
                        color: _rememberMe
                            ? AppColors.primary
                            : AppColors.transparent,
                      ),
                      child: _rememberMe
                          ? const Icon(Icons.check,
                              size: 14, color: AppColors.white)
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
                onTap: () {
                  // Navigate to forgot password
                },
                child: Text('Forgot Password?',
                    style: AppTheme.blackTextStyle.copyWith(
                        color: AppColors.primary,
                        fontWeight: AppTheme.bold,
                        fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: state.isLoading ? null : _handleLogin,
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
                child: state.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2))
                    : Text('Sign In',
                        style: AppTheme.whiteTextStyle
                            .copyWith(fontWeight: AppTheme.bold, fontSize: 18)),
              ),
            ),
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
                icon: Icons.g_mobiledata, color: AppColors.red, onTap: () {}),
            const SizedBox(width: 20),
            _buildSocialButton(
                icon: Icons.apple, color: AppColors.text, onTap: () {}),
            const SizedBox(width: 20),
            _buildSocialButton(
                icon: Icons.facebook, color: AppColors.blue, onTap: () {}),
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
                      color: AppColors.primary,
                      fontWeight: AppTheme.bold,
                      fontSize: 14)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildVerificationView(AuthState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              context.read<AuthBloc>().add(const ClearAuthError());
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.black, size: 18),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.email_outlined,
                  color: AppColors.primary, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          Text('Verify Your Email',
              style: AppTheme.blackTextStyle
                  .copyWith(fontWeight: AppTheme.bold, fontSize: 28)),
          const SizedBox(height: 8),
          Text("We've sent a verification link to your email",
              style: AppTheme.greyTextStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 32),
          if (state.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: AppColors.redColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.red2, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(state.error!,
                          style: AppTheme.blackTextStyle.copyWith(
                              color: AppColors.redColor, fontSize: 13))),
                ],
              ),
            ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: state.isLoading ? null : _handleResendVerification,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8)
                ]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: state.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2))
                    : Text('Resend Verification Email',
                        style: AppTheme.whiteTextStyle
                            .copyWith(fontWeight: AppTheme.bold, fontSize: 16)),
              ),
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

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    context.read<AuthBloc>().add(
          SignInRequested(
            email: email,
            password: password,
            rememberMe: _rememberMe,
          ),
        );
  }

  void _handleResendVerification() {
    context.read<AuthBloc>().add(const ResendVerificationCode());
  }
}
