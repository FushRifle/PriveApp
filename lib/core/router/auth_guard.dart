import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clique/app/configs/colors.dart';

import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';

import 'package:clique/ui/pages/auth/authentication_page.dart';
import 'package:clique/ui/pages/auth/onboarding_page.dart';
import 'package:clique/ui/pages/auth/unified_onboarding_page.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'main_wrapper.dart';

class AuthGuard extends StatefulWidget {
  final VoidCallback? onBootstrapComplete;

  const AuthGuard({
    super.key,
    this.onBootstrapComplete,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  String? _configuredToken;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        return previous.isAuthenticated != current.isAuthenticated ||
            previous.token != current.token ||
            previous.status != current.status;
      },
      builder: (context, authState) {
        if (authState.status == AuthStatus.initial ||
            authState.status == AuthStatus.loading) {
          return const _SplashScreen();
        }

        if (!authState.isAuthenticated || authState.token == null) {
          return const _PreAuthGate();
        }

        if (_configuredToken != authState.token) {
          _configuredToken = authState.token;
          final profileBloc = context.read<ProfileBloc>();

          final userBloc = context.read<UserBloc>();

          profileBloc.setAuthToken(
            authState.token!,
          );

          userBloc.setAuthToken(
            authState.token!,
          );
        }

        return _Bootstrapper(
          key: ValueKey(authState.token),
          token: authState.token!,
          isNewRegistration: authState.isNewRegistration,
          onBootstrapComplete: widget.onBootstrapComplete,
        );
      },
    );
  }
}

class _PreAuthGate extends StatefulWidget {
  const _PreAuthGate();

  @override
  State<_PreAuthGate> createState() => _PreAuthGateState();
}

class _PreAuthGateState extends State<_PreAuthGate> {
  static const _onboardingSeenKey = 'pre_auth_onboarding_seen_v1';

  bool _loading = true;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    var hasSeenOnboarding = false;
    try {
      final preferences = await SharedPreferences.getInstance();
      hasSeenOnboarding = preferences.getBool(_onboardingSeenKey) ?? false;
    } catch (_) {
      // A local preference failure should not block access to authentication.
    }
    if (!mounted) return;
    setState(() {
      _hasSeenOnboarding = hasSeenOnboarding;
      _loading = false;
    });
  }

  Future<void> _completeOnboarding() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_onboardingSeenKey, true);
    } catch (_) {
      // Continue into auth even if the local completion flag cannot be saved.
    }
    if (!mounted) return;
    setState(() => _hasSeenOnboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SplashScreen();
    if (!_hasSeenOnboarding) {
      return OnboardingPage(onComplete: _completeOnboarding);
    }
    return const AuthenticationPage();
  }
}

class _Bootstrapper extends StatefulWidget {
  final String token;
  final bool isNewRegistration;
  final VoidCallback? onBootstrapComplete;

  const _Bootstrapper({
    super.key,
    required this.token,
    required this.isNewRegistration,
    this.onBootstrapComplete,
  });

  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  bool _loading = true;
  bool _isOnboarded = false;
  bool _isSeenOnboarding = false;
  bool _isSeenDemographics = false;
  String? _error;
  Future<void>? _bootstrapFuture;
  bool _didNotifyBootstrapComplete = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final existingBootstrap = _bootstrapFuture;
    if (existingBootstrap != null) {
      return existingBootstrap;
    }

    final future = _runBootstrap();
    _bootstrapFuture = future;

    try {
      await future;
    } finally {
      if (_bootstrapFuture == future) {
        _bootstrapFuture = null;
      }
    }
  }

  Future<void> _runBootstrap() async {
    try {
      final profileBloc = context.read<ProfileBloc>();

      final userBloc = context.read<UserBloc>();

      final currentUser = userBloc.state.currentUser;

      _isOnboarded = _readOnboarded(currentUser);
      _isSeenOnboarding = _readFlag(
        currentUser,
        'isSeenOnboarding',
        fallback: _isOnboarded,
      );
      _isSeenDemographics = _readFlag(
        currentUser,
        'isSeenDemographics',
        fallback: _isOnboarded,
      );

      final futures = <Future>[];

      // Prime profile state, but optional profile data must never hold up
      // authentication or registration.
      if (profileBloc.state.myProfile == null &&
          profileBloc.state.status != ProfileStatus.loading) {
        profileBloc.add(LoadMyProfile());
      }

      if (currentUser == null) {
        futures.add(
          userBloc.stream.firstWhere(
            (state) {
              return state.status == UserStatus.success ||
                  state.status == UserStatus.error;
            },
          ),
        );

        if (userBloc.state.status != UserStatus.loading) {
          userBloc.add(
            LoadCurrentUser(),
          );
        }
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures).timeout(const Duration(seconds: 20));
      }

      if (!mounted) return;

      final userFailed = userBloc.state.currentUser == null &&
          userBloc.state.status == UserStatus.error;

      setState(() {
        _isOnboarded = _readOnboarded(userBloc.state.currentUser);
        _isSeenOnboarding = _readFlag(
          userBloc.state.currentUser,
          'isSeenOnboarding',
          fallback: _isOnboarded,
        );
        _isSeenDemographics = _readFlag(
          userBloc.state.currentUser,
          'isSeenDemographics',
          fallback: _isOnboarded,
        );
        _loading = false;
        _error = userFailed
            ? (userBloc.state.error ??
                'Unable to load your account. Check your connection and retry.')
            : null;
      });
      if (!_isSeenOnboarding || widget.isNewRegistration) {
        try {
          await UserService().markOnboardingSeen();
        } catch (_) {
          // Progress is optimistic: a transient flag-write failure must not
          // send a newly registered user backwards in the flow.
        }
        if (mounted) setState(() => _isSeenOnboarding = true);
      }
      if (_error == null) _notifyBootstrapComplete();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error is TimeoutException
            ? 'Loading your account took too long. Check your connection and try again.'
            : 'We could not finish loading your account. Please try again.';
      });
    }
  }

  void _notifyBootstrapComplete() {
    if (_didNotifyBootstrapComplete) return;
    _didNotifyBootstrapComplete = true;
    if (mounted) widget.onBootstrapComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _SplashScreen();
    }

    if (_error != null) {
      return _ErrorScreen(
        error: _error!,
        onRetry: () {
          setState(() {
            _loading = true;
            _error = null;
          });

          _bootstrap();
        },
        onBackToSignIn: () {
          context.read<AuthBloc>().add(const SignOutRequested());
        },
      );
    }

    if (!_isSeenDemographics) {
      return UnifiedOnboardingPage(
        onComplete: () => setState(() {
          _isSeenDemographics = true;
          _isOnboarded = true;
        }),
      );
    }

    return const MainWrapper();
  }

  bool _readOnboarded(Map<String, dynamic>? user) {
    final value = user?['onboarded'] ?? user?['isOnboarded'];

    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return false;
  }

  bool _readFlag(
    Map<String, dynamic>? user,
    String camelKey, {
    required bool fallback,
  }) {
    final snakeKey = camelKey.replaceAllMapped(
        RegExp(r'[A-Z]'), (match) => '_${match[0]!.toLowerCase()}');
    final value = user?[camelKey] ?? user?[snakeKey];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 170,
              height: 170,
              child: Lottie.asset(
                'assets/animations/loading.json',
                repeat: true,
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onBackToSignIn;

  const _ErrorScreen({
    required this.error,
    required this.onRetry,
    required this.onBackToSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onBackToSignIn();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Back to sign in',
            onPressed: onBackToSignIn,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 56,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onBackToSignIn,
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
