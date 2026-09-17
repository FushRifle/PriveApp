import 'package:clique/app/configs/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/auth/auth_service.dart';

InputDecoration _authFieldDecoration(
  BuildContext context, {
  required String labelText,
  required String hintText,
  required Widget prefixIcon,
  Widget? suffixIcon,
  String? errorText,
}) {
  final theme = Theme.of(context);
  final enabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: AppColors.border.withOpacity(0.7)),
  );

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    errorText: errorText,
    labelStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
    floatingLabelStyle: theme.textTheme.bodySmall?.copyWith(
      color: AppColors.primary,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
    border: enabledBorder,
    enabledBorder: enabledBorder,
    focusedBorder: enabledBorder.copyWith(
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: enabledBorder.copyWith(
      borderSide: const BorderSide(color: AppColors.error, width: 1.2),
    ),
    focusedErrorBorder: enabledBorder.copyWith(
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
  );
}

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final _authService = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  TextEditingController? _confirmPasswordController;
  final _formKey = GlobalKey<FormState>();

  bool _existingUser = true;
  bool _obscurePassword = true;
  bool? _confirmPasswordObscured;
  bool _rememberMe = true;
  String? _emailError;
  String? _passwordError;

  TextEditingController get _confirmPassword =>
      _confirmPasswordController ??= TextEditingController();

  bool get _obscureConfirmPassword => _confirmPasswordObscured ?? true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPasswordController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.error && state.error != null) {
              _applyAuthFieldError(state.error!);
              _showErrorMessage(state.error!);
              context.read<AuthBloc>().add(const ClearAuthError());
            }
          },
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth >= 600 ? 32 : 14,
                    vertical: 24,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight > 48
                          ? constraints.maxHeight - 48
                          : 0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540),
                        child: _buildAuthPanel(state),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthPanel(AuthState state) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width >= 600 ? 30 : 20,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AuthWordmark(),
              const SizedBox(height: 24),
              _AuthModeSwitch(
                existingUser: _existingUser,
                onChanged: _setMode,
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.025, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(_existingUser),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _existingUser ? 'Welcome back' : 'Create your Clique',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.45,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _existingUser
                          ? 'Sign in to catch up with your people and moments.'
                          : 'A quieter, more personal social space starts here.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _ProviderButton(
                      label: 'Google',
                      semanticLabel: 'Continue with Google',
                      enabled: !state.isLoading,
                      leading: Text(
                        'G',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      onPressed: _continueWithGoogle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProviderButton(
                      label: 'Apple',
                      semanticLabel: 'Continue with Apple',
                      enabled: !state.isLoading,
                      leading: Icon(
                        Icons.apple,
                        color: colors.onSurface,
                        size: 21,
                      ),
                      onPressed: _continueWithApple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const _AuthDivider(),
              const SizedBox(height: 26),
              TextFormField(
                controller: _email,
                enabled: !state.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                style: theme.textTheme.bodyMedium,
                decoration: _authFieldDecoration(
                  context,
                  labelText: 'Email address',
                  hintText: 'you@example.com',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  errorText: _emailError,
                ),
                validator: (value) => _emailError ?? _validateEmail(value),
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                enabled: !state.isLoading,
                obscureText: _obscurePassword,
                textInputAction:
                    _existingUser ? TextInputAction.done : TextInputAction.next,
                autofillHints: _existingUser
                    ? const [AutofillHints.password]
                    : const [AutofillHints.newPassword],
                style: theme.textTheme.bodyMedium,
                decoration: _authFieldDecoration(
                  context,
                  labelText: 'Password',
                  hintText: _existingUser
                      ? 'Enter your password'
                      : '8–128 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  errorText: _passwordError,
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
                      color: colors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
                validator: (value) =>
                    _passwordError ?? _validatePassword(value),
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
                onFieldSubmitted: (_) {
                  if (_existingUser) _submitPassword();
                },
              ),
              if (!_existingUser) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassword,
                  enabled: !state.isLoading,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  style: theme.textTheme.bodyMedium,
                  decoration: _authFieldDecoration(
                    context,
                    labelText: 'Confirm password',
                    hintText: 'Enter your password again',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmPassword
                          ? 'Show confirmed password'
                          : 'Hide confirmed password',
                      onPressed: () => setState(
                        () =>
                            _confirmPasswordObscured = !_obscureConfirmPassword,
                      ),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: colors.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                  validator: _validateConfirmPassword,
                  onFieldSubmitted: (_) => _submitPassword(),
                ),
              ],
              const SizedBox(height: 8),
              if (_existingUser)
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: state.isLoading
                          ? null
                          : (value) =>
                              setState(() => _rememberMe = value ?? false),
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(
                      'Remember me',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: state.isLoading ? null : _sendPasswordReset,
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: colors.secondary,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Use at least 8 characters.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: _existingUser ? 8 : 10),
              FilledButton(
                onPressed: state.isLoading ? null : _submitPassword,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: state.isLoading
                      ? SizedBox.square(
                          key: ValueKey('loading'),
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: colors.onPrimary,
                          ),
                        )
                      : Row(
                          key: ValueKey(_existingUser),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _existingUser ? 'Sign in' : 'Create account',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _existingUser
                        ? 'New to Clique?'
                        : 'Already have an account?',
                    style: theme.textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed:
                        state.isLoading ? null : () => _setMode(!_existingUser),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(
                      _existingUser ? 'Create account' : 'Sign in',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              _LegalLinks(
                onTerms: () => Navigator.pushNamed(
                  context,
                  NamedRoutes.termsScreen,
                ),
                onPrivacy: () => Navigator.pushNamed(
                  context,
                  NamedRoutes.privacyScreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setMode(bool existingUser) {
    if (_existingUser == existingUser) return;
    setState(() {
      _existingUser = existingUser;
      _password.clear();
      _confirmPassword.clear();
      _emailError = null;
      _passwordError = null;
      _obscurePassword = true;
      _confirmPasswordObscured = true;
    });
  }

  void _applyAuthFieldError(String message) {
    final normalized = message.toLowerCase();
    setState(() {
      if (normalized.contains('email address') ||
          normalized.contains('no account') ||
          normalized.contains('account was found')) {
        _emailError = message;
      } else if (normalized.contains('password') ||
          normalized.contains('credentials')) {
        _passwordError = message;
      }
    });
  }

  void _showErrorMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    final colors = Theme.of(context).colorScheme;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: colors.onInverseSurface,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  Future<void> _sendPasswordReset() async {
    final emailError = _validateEmail(_email.text);
    if (emailError != null) {
      setState(() => _emailError = emailError);
      return;
    }

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
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bloc = context.read<AuthBloc>();
    if (_existingUser) {
      bloc.add(SignInRequested(
        email: _email.text.trim(),
        password: _password.text,
        rememberMe: _rememberMe,
      ));
    } else {
      bloc.add(SignUpRequested(
        email: _email.text.trim(),
        password: _password.text,
        firstName: '',
        lastName: '',
      ));
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (email.length > 254) return 'Email address is too long.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Invalid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final length = value?.length ?? 0;
    if (length == 0) return 'Enter your password.';
    if (length < 8) return 'Password must be at least 8 characters.';
    if (length > 128) return 'Password is too long.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_existingUser) return null;
    if (value == null || value.isEmpty) return 'Confirm your password.';
    if (value != _password.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _continueWithGoogle() async {
    final result = await _authService.signInWithGoogle();
    if (!result.success && mounted) {
      _showErrorMessage(result.error ?? 'Google sign in failed.');
    }
  }

  Future<void> _continueWithApple() async {
    final result = await _authService.signInWithApple();
    if (!result.success && mounted) {
      _showErrorMessage(result.error ?? 'Apple sign in failed.');
    }
  }
}

class _AuthModeSwitch extends StatelessWidget {
  final bool existingUser;
  final ValueChanged<bool> onChanged;

  const _AuthModeSwitch({
    required this.existingUser,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Choose authentication mode',
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border.withOpacity(0.7)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ModeOption(
                label: 'Sign in',
                selected: existingUser,
                onTap: () => onChanged(true),
              ),
            ),
            Expanded(
              child: _ModeOption(
                label: 'Create account',
                selected: !existingUser,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surface.withOpacity(0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? theme.cardColor : colors.surface.withOpacity(0),
            borderRadius: BorderRadius.circular(11),
            border: selected
                ? Border.all(color: AppColors.border.withOpacity(0.7))
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: selected ? colors.onSurface : colors.onSurfaceVariant,
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final Widget leading;
  final bool enabled;
  final VoidCallback onPressed;

  const _ProviderButton({
    required this.label,
    required this.semanticLabel,
    required this.leading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: colors.onSurface,
          backgroundColor: theme.cardColor,
          side: BorderSide(color: AppColors.border.withOpacity(0.7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border.withOpacity(0.7))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH EMAIL',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border.withOpacity(0.7))),
      ],
    );
  }
}

class _AuthWordmark extends StatelessWidget {
  const _AuthWordmark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.asset(
            'assets/icons/clique-new.png',
            width: 34,
            height: 34,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'Clique',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _LegalLinks extends StatelessWidget {
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  const _LegalLinks({required this.onTerms, required this.onPrivacy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 10,
      height: 1.4,
    );
    final linkStyle = baseStyle?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('By continuing, you agree to Clique’s ', style: baseStyle),
        InkWell(
          onTap: onTerms,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('Terms of Service', style: linkStyle),
          ),
        ),
        Text(' and ', style: baseStyle),
        InkWell(
          onTap: onPrivacy,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('Privacy Policy', style: linkStyle),
          ),
        ),
        Text('.', style: baseStyle),
      ],
    );
  }
}
