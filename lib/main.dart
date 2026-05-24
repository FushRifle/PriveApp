import 'package:clique/app/configs/api_config.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/app/resources/constant/named_routes.dart';

import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/cloudinary/cloudinary_cubit.dart';

import 'package:clique/data/providers/theme_provider.dart';

import 'package:clique/managers/auth_guard.dart';

import 'package:clique/ui/pages/auth/demographic_page.dart';
import 'package:clique/ui/pages/auth/login_page.dart';
import 'package:clique/ui/pages/auth/register_page.dart';
import 'package:clique/ui/pages/auth/security/active_sessions_page.dart';
import 'package:clique/ui/pages/auth/security/change_password_page.dart';
import 'package:clique/ui/pages/auth/security/lock_screen_page.dart';
import 'package:clique/ui/pages/auth/security/two_factor_page.dart';
import 'package:clique/ui/pages/auth/success_page.dart';

import 'package:clique/ui/pages/main/home/create_post_page.dart';
import 'package:clique/ui/pages/main/home/post_detail_page.dart';

import 'package:clique/ui/pages/main/match/matches_page.dart';

import 'package:clique/ui/pages/main/notification/notification_page.dart';

import 'package:clique/ui/pages/main/profile/edit_profile_page.dart';
import 'package:clique/ui/pages/main/profile/profile_page.dart';

import 'package:clique/ui/pages/main/status/create_status_page.dart';
import 'package:clique/ui/pages/main/status/status_page.dart';

import 'package:clique/ui/pages/settings/clique/about_page.dart';
import 'package:clique/ui/pages/settings/clique/help_page.dart';
import 'package:clique/ui/pages/settings/clique/privacy_page.dart';
import 'package:clique/ui/pages/settings/clique/terms_page.dart';

import 'package:clique/ui/pages/settings/settings_page.dart';
import 'package:clique/ui/pages/settings/subscribe_page.dart';

import 'package:clique/ui/pages/social/friends_list_page.dart';
import 'package:clique/ui/pages/social/insights_page.dart';

import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeApp();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _initializeApp() async {
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
    debug: false,
  );

  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(
    cloudName: 'dug6225go',
  );

  FlutterError.onError = FlutterError.presentError;
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  late final AuthBloc _authBloc;

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  DateTime? _lastAuthCheck;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _authBloc = AuthBloc()..add(CheckAuthStatus());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _authBloc.close();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();

      if (_lastAuthCheck == null ||
          now.difference(_lastAuthCheck!) > const Duration(seconds: 20)) {
        _lastAuthCheck = now;

        _authBloc.add(CheckAuthStatus());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(
          value: _authBloc,
        ),

        // GLOBAL ONLY
        BlocProvider(
          create: (_) => CloudinaryCubit(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.error != current.error,
            listener: (context, state) {
              final error = state.error?.toLowerCase() ?? '';

              if (_isCriticalAuthError(error)) {
                context.read<AuthBloc>().add(SignOutRequested());
              }
            },
          ),
        ],
        child: MaterialApp(
          title: 'Clique',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _scaffoldMessengerKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          scrollBehavior: const CustomScrollBehavior(),
          home: const AuthGuard(),
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }

  bool _isCriticalAuthError(String error) {
    const criticalErrors = [
      'token',
      'session',
      'unauthorized',
      'forbidden',
      'blocked',
      'suspended',
      'invalid credentials',
    ];

    return criticalErrors.any(
      error.contains,
    );
  }
}

class AppRouter {
  static Route<dynamic> generateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case NamedRoutes.postDetailScreen:
        final postId = settings.arguments;

        if (postId is! int) {
          return _errorRoute(
            'Invalid post ID',
          );
        }

        return _route(
          PostDetailPage(
            postId: postId,
          ),
        );

      case NamedRoutes.loginScreen:
        return _route(
          const LoginPage(),
        );

      case NamedRoutes.registerScreen:
        return _route(
          const RegisterPage(),
        );

      case NamedRoutes.demographicScreen:
        return _route(
          const OnboardingDemographicPage(),
        );

      case NamedRoutes.onboardingSuccessScreen:
        return _route(
          const OnboardingSuccessPage(),
        );

      case NamedRoutes.profileScreen:
        return _route(
          const ProfilePage(
            isOwnProfile: true,
          ),
        );

      case NamedRoutes.editProfileScreen:
        return _route(
          const EditProfilePage(),
        );

      case NamedRoutes.friendListScreen:
        return _route(
          const FriendsListPage(),
        );

      case NamedRoutes.insightsScreen:
        return _route(
          const InsightsPage(),
        );

      case NamedRoutes.matchScreen:
        return _route(
          const MatchesPage(),
        );

      case NamedRoutes.createPostScreen:
        return _route(
          const CreatePostPage(),
        );

      case NamedRoutes.createStatusScreen:
        return _route(
          const CreateStatusPage(),
        );

      case NamedRoutes.statusScreen:
        return _route(
          const StatusPage(
            stories: [],
          ),
        );

      case NamedRoutes.settingsScreen:
        return _route(
          const SettingsPage(),
        );

      case NamedRoutes.aboutScreen:
        return _route(
          const AboutPage(),
        );

      case NamedRoutes.termsScreen:
        return _route(
          const TermsPage(),
        );

      case NamedRoutes.privacyScreen:
        return _route(
          const PrivacyPage(),
        );

      case NamedRoutes.helpScreen:
        return _route(
          const HelpPage(),
        );

      case NamedRoutes.subscribeScreen:
        return _route(
          const SubscribePage(),
        );

      case NamedRoutes.notificationScreen:
        return _route(
          const NotificationPage(),
        );

      case NamedRoutes.twoFactorScreen:
        return _route(
          const TwoFactorPage(),
        );

      case NamedRoutes.changePasswordScreen:
        return _route(
          const ChangePasswordPage(),
        );

      case NamedRoutes.activeSessionsScreen:
        return _route(
          const ActiveSessionsPage(),
        );

      case NamedRoutes.lockScreenScreen:
        return _route(
          const LockScreenPage(),
        );

      default:
        return _route(
          const AuthGuard(),
        );
    }
  }

  static MaterialPageRoute _route(
    Widget page,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
    );
  }

  static Route<dynamic> _errorRoute(
    String message,
  ) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text(message),
        ),
      ),
    );
  }
}

class CustomScrollBehavior extends ScrollBehavior {
  const CustomScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(
    BuildContext context,
  ) {
    return const BouncingScrollPhysics();
  }
}
