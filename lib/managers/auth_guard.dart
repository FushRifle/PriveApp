import 'package:clique/app/configs/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/app/resources/constant/named_routes.dart';
import './main_wrapper.dart';

class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (!authState.isAuthenticated || authState.token == null) {
          return const _Redirector(route: NamedRoutes.loginScreen);
        }

        return _AuthenticatedGuard(token: authState.token!);
      },
    );
  }
}

class _AuthenticatedGuard extends StatelessWidget {
  final String token;

  const _AuthenticatedGuard({required this.token});

  @override
  Widget build(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>();
    final userBloc = context.read<UserBloc>();

    // Set tokens immediately
    profileBloc.setAuthToken(token);
    userBloc.setAuthToken(token);

    // Check if profile is already loaded
    final hasProfile = profileBloc.state.myProfile != null &&
        profileBloc.state.myProfile!.userId > 0;
    final hasUser = userBloc.state.currentUser != null;

    if (hasProfile && hasUser) {
      return const MainWrapper();
    }

    return _ProfileLoader(
      token: token,
      hasProfile: hasProfile,
      hasUser: hasUser,
    );
  }
}

class _ProfileLoader extends StatefulWidget {
  final String token;
  final bool hasProfile;
  final bool hasUser;

  const _ProfileLoader({
    required this.token,
    required this.hasProfile,
    required this.hasUser,
  });

  @override
  State<_ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends State<_ProfileLoader> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profileBloc = context.read<ProfileBloc>();
    final userBloc = context.read<UserBloc>();

    final futures = <Future>[];

    if (!widget.hasProfile) {
      profileBloc.add(LoadMyProfile());
      futures.add(profileBloc.stream.firstWhere(
        (state) =>
            state.status == ProfileStatus.success ||
            state.status == ProfileStatus.error,
      ));
    }

    if (!widget.hasUser) {
      userBloc.add(LoadCurrentUser());
      futures.add(userBloc.stream.firstWhere(
        (state) =>
            state.status == UserStatus.success ||
            state.status == UserStatus.error,
      ));
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    if (!mounted) return;

    final profile = profileBloc.state.myProfile;
    final hasValidProfile = profile != null && profile.userId > 0;

    if (!hasValidProfile) {
      Navigator.pushReplacementNamed(context, NamedRoutes.demographicScreen);
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/clique.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Redirector extends StatelessWidget {
  final String route;

  const _Redirector({required this.route});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, route);
      }
    });
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/icons/clique.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
