import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';

import 'package:clique/app/configs/api_config.dart';
import 'package:clique/app/configs/theme.dart';

import 'package:clique/data/providers/theme_provider.dart';

import 'package:clique/app/resources/constant/named_routes.dart';

import 'package:clique/managers/auth_guard.dart';

import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/chat/gallery/chat_gallery_cubit.dart';
import 'package:clique/bloc/cloudinary/cloudinary_cubit.dart';
import 'package:clique/bloc/explore/explore_bloc.dart';
import 'package:clique/bloc/friends/friends_bloc.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/insights/insights_bloc.dart';
import 'package:clique/bloc/match/match_bloc.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/reels/reel_bloc.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';

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

import 'package:clique/ui/pages/main/notification/notification_page.dart';

import 'package:clique/ui/pages/main/profile/edit_profile_page.dart';
import 'package:clique/ui/pages/main/profile/profile_page.dart';

import 'package:clique/ui/pages/main/status/create_status_page.dart';
import 'package:clique/ui/pages/main/status/status_page.dart';

import 'package:clique/ui/pages/settings/settings_page.dart';
import 'package:clique/ui/pages/settings/subscribe_page.dart';

import 'package:clique/ui/pages/settings/clique/about_page.dart';
import 'package:clique/ui/pages/settings/clique/help_page.dart';
import 'package:clique/ui/pages/settings/clique/privacy_page.dart';
import 'package:clique/ui/pages/settings/clique/terms_page.dart';

import 'package:clique/ui/pages/social/friends_list_page.dart';
import 'package:clique/ui/pages/social/insights_page.dart';

import 'package:clique/ui/pages/main/match/matches_page.dart';

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

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  late final AuthBloc _authBloc;

  late final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
      _authBloc.add(CheckAuthStatus());
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
        BlocProvider(
          create: (_) => CloudinaryCubit(),
        ),
        BlocProvider(
          create: (_) => UserBloc(),
        ),
        BlocProvider(
          create: (_) => ProfileBloc(),
        ),
        BlocProvider(
          create: (_) => FeedBloc(),
        ),
        BlocProvider(
          create: (_) => FriendsBloc(),
        ),
        BlocProvider(
          create: (_) => MatchBloc(),
        ),
        BlocProvider(
          create: (_) => InsightsBloc(),
        ),
        BlocProvider(
          create: (_) => StoriesBloc(),
        ),
        BlocProvider(
          create: (_) => ExploreBloc(),
        ),
        BlocProvider(
          create: (_) => ReelBloc(),
        ),
        BlocProvider(
          create: (_) => ChatBloc(),
        ),
        BlocProvider(
          create: (_) => ChatGalleryCubit(),
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
      (e) => error.contains(e),
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

        return MaterialPageRoute(
          builder: (_) => PostDetailPage(
            postId: postId,
          ),
        );

      case NamedRoutes.loginScreen:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );

      case NamedRoutes.registerScreen:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
        );

      case NamedRoutes.demographicScreen:
        return MaterialPageRoute(
          builder: (_) => const OnboardingDemographicPage(),
        );

      case NamedRoutes.onboardingSuccessScreen:
        return MaterialPageRoute(
          builder: (_) => const OnboardingSuccessPage(),
        );

      case NamedRoutes.profileScreen:
        return MaterialPageRoute(
          builder: (_) => const ProfilePage(
            isOwnProfile: true,
          ),
        );

      case NamedRoutes.editProfileScreen:
        return MaterialPageRoute(
          builder: (_) => const EditProfilePage(),
        );

      case NamedRoutes.friendListScreen:
        return MaterialPageRoute(
          builder: (_) => const FriendsListPage(),
        );

      case NamedRoutes.insightsScreen:
        return MaterialPageRoute(
          builder: (_) => const InsightsPage(),
        );

      case NamedRoutes.matchScreen:
        return MaterialPageRoute(
          builder: (_) => const MatchesPage(),
        );

      case NamedRoutes.createPostScreen:
        return MaterialPageRoute(
          builder: (_) => const CreatePostPage(),
        );

      case NamedRoutes.createStatusScreen:
        return MaterialPageRoute(
          builder: (_) => const CreateStatusPage(),
        );

      case NamedRoutes.statusScreen:
        return MaterialPageRoute(
          builder: (_) => const StatusPage(
            stories: [],
          ),
        );

      case NamedRoutes.settingsScreen:
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
        );

      case NamedRoutes.aboutScreen:
        return MaterialPageRoute(
          builder: (_) => const AboutPage(),
        );

      case NamedRoutes.termsScreen:
        return MaterialPageRoute(
          builder: (_) => const TermsPage(),
        );

      case NamedRoutes.privacyScreen:
        return MaterialPageRoute(
          builder: (_) => const PrivacyPage(),
        );

      case NamedRoutes.helpScreen:
        return MaterialPageRoute(
          builder: (_) => const HelpPage(),
        );

      case NamedRoutes.subscribeScreen:
        return MaterialPageRoute(
          builder: (_) => const SubscribePage(),
        );

      case NamedRoutes.notificationScreen:
        return MaterialPageRoute(
          builder: (_) => const NotificationPage(),
        );

      case NamedRoutes.twoFactorScreen:
        return MaterialPageRoute(
          builder: (_) => const TwoFactorPage(),
        );

      case NamedRoutes.changePasswordScreen:
        return MaterialPageRoute(
          builder: (_) => const ChangePasswordPage(),
        );

      case NamedRoutes.activeSessionsScreen:
        return MaterialPageRoute(
          builder: (_) => const ActiveSessionsPage(),
        );

      case NamedRoutes.lockScreenScreen:
        return MaterialPageRoute(
          builder: (_) => const LockScreenPage(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const AuthGuard(),
        );
    }
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
