import 'dart:ui';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/core/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _EmailStage { email, password }

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _EmailStage? _stage;
  bool _existingUser = true;
  bool _obscurePassword = true;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _stage == null
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                tooltip: 'Back',
                onPressed: () => setState(() {
                  _stage =
                      _stage == _EmailStage.password ? _EmailStage.email : null;
                  _password.clear();
                }),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/profiles/profile_1.jpeg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.32),
                  Colors.black.withOpacity(0.52),
                  Colors.black.withOpacity(0.76),
                ],
                stops: const [0, 0.48, 1],
              ),
            ),
          ),
          SafeArea(
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state.status == AuthStatus.error && state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(state.error!)),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                  context.read<AuthBloc>().add(const ClearAuthError());
                }
              },
              builder: (context, state) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.24),
                                  blurRadius: 32,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                textTheme: Theme.of(context).textTheme.apply(
                                      bodyColor: Colors.white,
                                      displayColor: Colors.white,
                                    ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.05, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _stage == null
                                    ? _buildMethods(state)
                                    : _buildEmailFlow(state),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethods(AuthState state) {
    return Column(
      key: const ValueKey('auth-methods'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 48),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/clique-new.png',
              width: 80,
              height: 80,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Welcome to Clique',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Connect and share with your community',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.72),
              ),
        ),
        const SizedBox(height: 48),
        // Divider with text
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Login or Register',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.65),
                      letterSpacing: 1.5,
                    ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
          ],
        ),
        const SizedBox(height: 24),
        _methodButton(
          icon: Icons.email_outlined,
          label: 'Email',
          onPressed: () => setState(() => _stage = _EmailStage.email),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(
              icon: Icons.g_mobiledata,
              tooltip: 'Continue with Google',
              iconSize: 32,
              onPressed: state.isLoading ? null : _continueWithGoogle,
            ),
            const SizedBox(width: 18),
            _socialButton(
              icon: Icons.apple,
              tooltip: 'Continue with Apple',
              onPressed: state.isLoading ? null : _continueWithApple,
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'By continuing, you agree to our Terms & Privacy Policy',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.58),
              ),
        ),
      ],
    );
  }

  Widget _buildEmailFlow(AuthState state) {
    final passwordStage = _stage == _EmailStage.password;
    return Form(
      key: _formKey,
      child: Column(
        key: ValueKey(_stage),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStepIndicator(1, true),
              Container(
                width: 40,
                height: 2,
                color: passwordStage
                    ? AppColors.primary
                    : AppColors.cardBorderColor.withOpacity(0.3),
              ),
              _buildStepIndicator(2, passwordStage),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            passwordStage
                ? (_existingUser ? 'Welcome back' : 'Create your account')
                : 'What\'s your email?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            passwordStage
                ? 'Enter your password for\n${_email.text.trim().toLowerCase()}'
                : 'Enter your email, then choose whether to sign in or create an account',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.72),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 36),
          if (!passwordStage)
            // Email input
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _email,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                style: const TextStyle(fontSize: 16, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email address',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.24),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.primary.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.red.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.length > 254) return 'Email address is too long';
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                      ? null
                      : 'Please enter a valid email';
                },
                onFieldSubmitted: (_) => _checkEmail(),
              ),
            )
          else
            // Password input
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _password,
                autofocus: true,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: _existingUser
                    ? const [AutofillHints.password]
                    : const [AutofillHints.newPassword],
                style: const TextStyle(fontSize: 16, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  suffixIcon: IconButton(
                    tooltip:
                        _obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.24),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.primary.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.red.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                validator: (value) {
                  final length = value?.length ?? 0;
                  if (length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  if (length > 128) return 'Password is too long';
                  return null;
                },
                onFieldSubmitted: (_) => _submitPassword(),
              ),
            ),
          const SizedBox(height: 32),
          // Continue button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: state.isLoading
                  ? null
                  : passwordStage
                      ? _submitPassword
                      : _checkEmail,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.grey.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: state.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            passwordStage
                                ? (_existingUser ? 'Sign in' : 'Create account')
                                : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
          ),
          if (passwordStage) ...[
            const SizedBox(height: 24),
            TextButton(
              onPressed: state.isLoading
                  ? null
                  : () => setState(() {
                        _existingUser = !_existingUser;
                        _password.clear();
                      }),
              child: Text(
                _existingUser
                    ? 'New to Clique? Create an account'
                    : 'Already have an account? Sign in',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_existingUser)
              TextButton(
                onPressed: state.isLoading ? null : _sendPasswordReset,
                child: Text(
                  'Forgot your password?',
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primary : Colors.black.withOpacity(0.22),
        border: Border.all(
          color: isActive
              ? AppColors.secondary
              : AppColors.secondary.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: isActive
            ? Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              )
            : Text(
                '$step',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _methodButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          'Continue with $label',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: Colors.white.withOpacity(0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.black.withOpacity(0.18),
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    double iconSize = 25,
  }) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 58,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.45),
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.28),
          ),
          child: Icon(icon, size: iconSize, color: Colors.white),
        ),
      ),
    );
  }

  void _checkEmail() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _existingUser = true;
      _stage = _EmailStage.password;
    });
  }

  Future<void> _sendPasswordReset() async {
    final sent = await _authService.sendPasswordReset(_email.text);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'Password reset instructions were sent if the account exists.'
              : 'Unable to request a password reset. Please try again.',
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _submitPassword() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bloc = context.read<AuthBloc>();
    if (_existingUser) {
      bloc.add(SignInRequested(
        email: _email.text,
        password: _password.text,
        rememberMe: false,
      ));
    } else {
      bloc.add(SignUpRequested(
        email: _email.text,
        password: _password.text,
        firstName: '',
        lastName: '',
      ));
    }
  }

  Future<void> _continueWithGoogle() async {
    final result = await _authService.signInWithGoogle();
    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(result.error ?? 'Google sign in failed.'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _continueWithApple() async {
    final result = await _authService.signInWithApple();
    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(result.error ?? 'Apple sign in failed.'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
