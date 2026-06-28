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
  bool _checking = false;
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
      backgroundColor: AppColors.background,
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
                    color: AppColors.cardBorderColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 20),
                ),
              ),
            ),
      body: SafeArea(
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
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
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
            );
          },
        ),
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
                color: AppColors.text.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 48),
        // Divider with text
        Row(
          children: [
            Expanded(
                child:
                    Divider(color: AppColors.cardBorderColor.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'continue with',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.text.withOpacity(0.5),
                      letterSpacing: 1.5,
                    ),
              ),
            ),
            Expanded(
                child:
                    Divider(color: AppColors.cardBorderColor.withOpacity(0.3))),
          ],
        ),
        const SizedBox(height: 24),
        _methodButton(
          icon: Icons.mail_outline_rounded,
          label: 'Email',
          onPressed: () => setState(() => _stage = _EmailStage.email),
        ),
        const SizedBox(height: 14),
        _methodButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Google',
          onPressed: state.isLoading ? null : _continueWithGoogle,
        ),
        const SizedBox(height: 32),
        Text(
          'By continuing, you agree to our Terms & Privacy Policy',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.text.withOpacity(0.4),
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
                : 'We\'ll check if you have an account',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text.withOpacity(0.6),
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
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Email address',
                  labelStyle: TextStyle(color: AppColors.text.withOpacity(0.5)),
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
                  fillColor: AppColors.cardBorderColor.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.cardBorderColor.withOpacity(0.2),
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
                validator: (value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Please enter a valid email',
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
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: AppColors.text.withOpacity(0.5)),
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
                      color: AppColors.text.withOpacity(0.5),
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.cardBorderColor.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.cardBorderColor.withOpacity(0.2),
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
                validator: (value) => (value?.length ?? 0) < 8
                    ? 'Password must be at least 8 characters'
                    : null,
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
              onPressed: state.isLoading || _checking
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
                child: state.isLoading || _checking
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
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
          if (!passwordStage) ...[
            const SizedBox(height: 24),
            // Forgot password link for returning users
            TextButton(
              onPressed: () {
                // Handle forgot password
              },
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
        color: isActive ? AppColors.primary : AppColors.card,
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
                  color: AppColors.text.withOpacity(0.5),
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
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: AppColors.text,
          side: BorderSide(
            color: AppColors.cardBorderColor.withOpacity(0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.cardBorderColor.withOpacity(0.03),
        ),
      ),
    );
  }

  Future<void> _checkEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _checking = true);
    try {
      final exists = await _authService.emailExists(_email.text);
      if (!mounted) return;
      if (!exists) {
        final create = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Create an account?",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: const Text(
              "This email isn't registered yet. Would you like to create a new account?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create account'),
                ),
              ),
            ],
          ),
        );
        if (create != true || !mounted) return;
      }
      setState(() {
        _existingUser = exists;
        _stage = _EmailStage.password;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(error.toString())),
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
    } finally {
      if (mounted) setState(() => _checking = false);
    }
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
}
