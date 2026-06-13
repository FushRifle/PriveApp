import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import 'package:clique/app/configs/colors.dart';

import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';

import 'package:clique/ui/pages/auth/login_page.dart';
import 'package:clique/ui/pages/auth/onboarding_page.dart';
import 'main_wrapper.dart';
import 'named_routes.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

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
          return const LoginPage();
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
          token: authState.token!,
        );
      },
    );
  }
}

class _Bootstrapper extends StatefulWidget {
  final String token;

  const _Bootstrapper({
    required this.token,
  });

  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  bool _loading = true;

  bool _hasProfile = false;

  bool _hasUser = false;

  bool _isOnboarded = false;

  String? _error;

  Future<void>? _bootstrapFuture;

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

      final profile = profileBloc.state.myProfile;

      _hasProfile = profile != null && profile.userId > 0;

      final currentUser = userBloc.state.currentUser;

      _hasUser = currentUser != null;
      _isOnboarded = _readOnboarded(currentUser);

      final futures = <Future>[];

      if (!_hasProfile) {
        futures.add(
          profileBloc.stream.firstWhere(
            (state) {
              return state.status == ProfileStatus.success ||
                  state.status == ProfileStatus.error;
            },
          ),
        );

        if (profileBloc.state.status != ProfileStatus.loading) {
          profileBloc.add(
            LoadMyProfile(),
          );
        }
      }

      if (!_hasUser) {
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
        await Future.wait(futures);
      }

      if (!mounted) return;

      final updatedProfile = profileBloc.state.myProfile;

      final hasValidProfile =
          updatedProfile != null && updatedProfile.userId > 0;

      setState(() {
        _hasProfile = hasValidProfile;
        _hasUser = userBloc.state.currentUser != null;
        _isOnboarded = _readOnboarded(userBloc.state.currentUser);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
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
      );
    }

    if (!_isOnboarded || !_hasProfile) {
      return const OnboardingPage(
        completionRoute: NamedRoutes.demographicScreen,
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
              width: 116,
              height: 116,
              child: Lottie.asset(
                'assets/json/auth_guard_loader.json',
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

  const _ErrorScreen({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                child: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
