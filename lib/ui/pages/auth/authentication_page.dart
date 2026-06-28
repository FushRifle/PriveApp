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

class _AuthenticationPageState extends State<AuthenticationPage> {
  final _authService = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _EmailStage? _stage;
  bool _existingUser = true;
  bool _checking = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.error && state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),
              );
              context.read<AuthBloc>().add(const ClearAuthError());
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
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
        Image.asset('assets/icons/clique-new.png', width: 88, height: 88),
        const SizedBox(height: 48),
        _methodButton(
          icon: Icons.mail_outline_rounded,
          label: 'Continue with Email',
          onPressed: () => setState(() => _stage = _EmailStage.email),
        ),
        const SizedBox(height: 12),
        _methodButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Continue with Google',
          onPressed: state.isLoading ? null : _continueWithGoogle,
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
          Text(
            passwordStage
                ? (_existingUser ? 'Enter your password' : 'Create a password')
                : 'Enter your email',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (passwordStage)
            Text(
              _email.text.trim().toLowerCase(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 28),
          if (!passwordStage)
            TextFormField(
              controller: _email,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(value?.trim() ?? '')
                  ? null
                  : 'Enter a valid email address',
              onFieldSubmitted: (_) => _checkEmail(),
            )
          else
            TextFormField(
              controller: _password,
              autofocus: true,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: _existingUser
                  ? const [AutofillHints.password]
                  : const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
              validator: (value) => (value?.length ?? 0) < 8
                  ? 'Password must be at least 8 characters'
                  : null,
              onFieldSubmitted: (_) => _submitPassword(),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.isLoading || _checking
                ? null
                : passwordStage
                    ? _submitPassword
                    : _checkEmail,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
            ),
            child: state.isLoading || _checking
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _methodButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        foregroundColor: AppColors.text,
        side: BorderSide(color: AppColors.cardBorderColor),
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
            title: const Text("User doesn't exist. Create an account?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Create account'),
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
          SnackBar(content: Text(error.toString())),
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
        SnackBar(content: Text(result.error ?? 'Google sign in failed.')),
      );
    }
  }
}
