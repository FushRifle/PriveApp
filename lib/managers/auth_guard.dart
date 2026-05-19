import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cirqle/bloc/auth/auth_bloc.dart';
import 'package:cirqle/bloc/profile/profile_bloc.dart';
import 'package:cirqle/bloc/user/user_bloc.dart';
import 'package:cirqle/app/resources/constant/named_routes.dart';
import './main_wrapper.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isChecking = true;
  String? _redirectRoute;
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndOnboarding();
  }

  Future<void> _checkAuthAndOnboarding() async {
    if (_hasChecked) return;
    _hasChecked = true;

    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;

    // Check 1: Valid token?
    if (!authState.isAuthenticated || authState.token == null) {
      if (mounted) {
        setState(() {
          _redirectRoute = NamedRoutes.loginScreen;
          _isChecking = false;
        });
      }
      return;
    }

    final token = authState.token!;

    // Initialize all blocs with the auth token
    final profileBloc = context.read<ProfileBloc>();
    final userBloc = context.read<UserBloc>();

    profileBloc.setAuthToken(token);
    userBloc.setAuthToken(token);

    // Load profile if not loaded yet
    if (profileBloc.state.myProfile == null) {
      profileBloc.add(LoadMyProfile());
      await for (final state in profileBloc.stream) {
        if (state.status == ProfileStatus.success ||
            state.status == ProfileStatus.error) {
          break;
        }
      }
    }

    // Load user if not loaded yet
    if (userBloc.state.currentUser == null) {
      userBloc.add(LoadCurrentUser());
      await for (final state in userBloc.stream) {
        if (state.status == UserStatus.success ||
            state.status == UserStatus.error) {
          break;
        }
      }
    }

    final profile = profileBloc.state.myProfile;
    if (profile != null && profile.userId > 0) {
      if (mounted) {
        setState(() {
          _redirectRoute = null;
          _isChecking = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _redirectRoute = NamedRoutes.demographicScreen;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_redirectRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, _redirectRoute!);
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const MainWrapper();
  }
}
