import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/chat/gallery/chat_gallery_cubit.dart';
import 'package:clique/bloc/cloudinary/cloudinary_cubit.dart';
import 'package:clique/bloc/insights/insights_bloc.dart';
import 'package:clique/bloc/match/match_bloc.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/ui/pages/auth/security/active_sessions_page.dart';
import 'package:clique/ui/pages/auth/security/change_password_page.dart';
import 'package:clique/ui/pages/auth/security/lock_screen_page.dart';
import 'package:clique/ui/pages/auth/security/two_factor_page.dart';
import 'package:clique/ui/pages/auth/success_page.dart';
import 'package:clique/ui/pages/settings/clique/about_page.dart';
import 'package:clique/ui/pages/settings/clique/help_page.dart';
import 'package:clique/ui/pages/settings/clique/privacy_page.dart';
import 'package:clique/ui/pages/settings/clique/terms_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/app/resources/constant/named_routes.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/ui/pages/main/home/post_detail_page.dart';
import 'package:clique/ui/pages/main/notification/notification_page.dart';
import 'package:clique/ui/pages/main/profile/edit_profile_page.dart';
import 'package:clique/ui/pages/social/insights_page.dart';
import 'package:clique/ui/pages/main/profile/profile_page.dart';
import 'package:clique/ui/pages/main/home/create_post_page.dart';
import 'package:clique/ui/pages/main/status/create_status_page.dart';
import 'package:clique/ui/pages/main/status/status_page.dart';
import 'package:clique/ui/pages/auth/login_page.dart';
import 'package:clique/ui/pages/auth/register_page.dart';
import 'package:clique/ui/pages/auth/demographic_page.dart';
import 'package:clique/ui/pages/settings/settings_page.dart';
import 'package:clique/ui/pages/settings/subscribe_page.dart';
import 'package:clique/ui/pages/social/friends_list_page.dart';
import 'package:clique/ui/pages/main/match/matches_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:clique/app/configs/api_config.dart';
import 'package:clique/data/providers/theme_provider.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/bloc/friends/friends_bloc.dart';
import 'package:clique/bloc/explore/explore_bloc.dart';
import 'package:clique/bloc/reels/reel_bloc.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:clique/managers/auth_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
    debug: false, // Disable debug in production
  );

  CloudinaryContext.cloudinary =
      Cloudinary.fromCloudName(cloudName: 'dug6225go');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AuthBloc _authBloc;
  late final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  @override
  void initState() {
    super.initState();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _authBloc = AuthBloc();
    _authBloc.add(CheckAuthStatus());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MultiBlocProvider(
      providers: [
        // Auth providers
        BlocProvider<AuthBloc>.value(value: _authBloc),

        // Core providers
        BlocProvider<CloudinaryCubit>(
          create: (context) => CloudinaryCubit(),
          lazy: false, // Initialize immediately
        ),
        BlocProvider<UserBloc>(
          create: (context) => UserBloc(),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(),
        ),

        // Social providers
        BlocProvider<FriendsBloc>(
          create: (context) => FriendsBloc(),
        ),
        BlocProvider<MatchBloc>(
          create: (context) => MatchBloc(),
        ),
        BlocProvider<InsightsBloc>(
          create: (context) => InsightsBloc(),
        ),

        // Content providers
        BlocProvider<FeedBloc>(
          create: (context) => FeedBloc(),
        ),
        BlocProvider<StoriesBloc>(
          create: (context) => StoriesBloc(),
        ),
        BlocProvider<ExploreBloc>(
          create: (context) => ExploreBloc(),
        ),
        BlocProvider<ReelBloc>(
          create: (context) => ReelBloc(),
        ),

        // Chat providers
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(),
        ),
        BlocProvider<ChatGalleryCubit>(
          create: (context) => ChatGalleryCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'Clique',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        scrollBehavior: const CustomScrollBehavior(),
        scaffoldMessengerKey: _scaffoldMessengerKey,
        home: const AuthGuard(),
        onGenerateRoute: _generateRoute,
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();

          return MultiBlocListener(
            listeners: [
              // Auth listener - critical errors only
              BlocListener<AuthBloc, AuthState>(
                listenWhen: (previous, current) {
                  // Only show errors for auth-related critical issues
                  return current.status == AuthStatus.error &&
                      current.error != null &&
                      _isCriticalAuthError(current.error!);
                },
                listener: (context, state) {
                  if (state.error?.contains('token') == true ||
                      state.error?.contains('session') == true ||
                      state.error?.contains('unauthorized') == true) {
                    _authBloc.add(SignOutRequested());
                  }
                },
              ),

              // Profile listener - success only
              BlocListener<ProfileBloc, ProfileState>(
                listenWhen: (previous, current) {
                  return current.status == ProfileStatus.success &&
                      previous.status != ProfileStatus.success;
                },
                listener: (context, state) {
                  if (mounted) {
                    Navigator.pushReplacementNamed(
                        context, NamedRoutes.onboardingSuccessScreen);
                  }
                },
              ),

              // Cloudinary listener - silent errors
              BlocListener<CloudinaryCubit, CloudinaryState>(
                listenWhen: (previous, current) {
                  return current.status == UploadStatus.error &&
                      current.errorMessage != null &&
                      _shouldShowUploadError(current.errorMessage!);
                },
                listener: (context, state) {
                  debugPrint('Upload error: ${state.errorMessage}');
                },
              ),

              // Chat listener - silent errors
              BlocListener<ChatBloc, ChatState>(
                listenWhen: (previous, current) {
                  return current.error != null &&
                      _isCriticalChatError(current.error!);
                },
                listener: (context, state) {
                  debugPrint('Chat error: ${state.error}');
                },
              ),
            ],
            child: child,
          );
        },
      ),
    );
  }

  bool _isCriticalAuthError(String error) {
    final criticalErrors = [
      'token',
      'session',
      'unauthorized',
      'forbidden',
      'blocked',
      'suspended',
      'invalid credentials'
    ];
    return criticalErrors
        .any((keyword) => error.toLowerCase().contains(keyword));
  }

  bool _shouldShowUploadError(String error) {
    final silentErrors = [
      '401',
      '500',
      '503',
      'network',
      'timeout',
      'connection',
      'internet'
    ];
    return !silentErrors
        .any((keyword) => error.toLowerCase().contains(keyword));
  }

  bool _isCriticalChatError(String error) {
    final criticalErrors = ['blocked', 'banned', 'restricted', 'unauthorized'];
    return criticalErrors
        .any((keyword) => error.toLowerCase().contains(keyword));
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case NamedRoutes.postDetailScreen:
        final args = settings.arguments;
        if (args == null || args is! int) {
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('Invalid post data')),
            ),
          );
        }
        return MaterialPageRoute(
            builder: (context) => PostDetailPage(postId: args));

      case NamedRoutes.loginScreen:
        return MaterialPageRoute(builder: (context) => const LoginPage());

      case NamedRoutes.registerScreen:
        return MaterialPageRoute(builder: (context) => const RegisterPage());

      case NamedRoutes.demographicScreen:
        return MaterialPageRoute(
            builder: (context) => const OnboardingDemographicPage());

      case NamedRoutes.onboardingSuccessScreen:
        return MaterialPageRoute(
            builder: (context) => const OnboardingSuccessPage());

      case NamedRoutes.profileScreen:
        return MaterialPageRoute(
            builder: (context) => const ProfilePage(isOwnProfile: true));

      case NamedRoutes.editProfileScreen:
        return MaterialPageRoute(builder: (context) => const EditProfilePage());

      case NamedRoutes.friendListScreen:
        return MaterialPageRoute(builder: (context) => const FriendsListPage());

      case NamedRoutes.insightsScreen:
        return MaterialPageRoute(builder: (context) => const InsightsPage());

      case NamedRoutes.matchScreen:
        return MaterialPageRoute(builder: (context) => const MatchesPage());

      case NamedRoutes.createPostScreen:
        return MaterialPageRoute(builder: (context) => const CreatePostPage());

      case NamedRoutes.createStatusScreen:
        return MaterialPageRoute(
            builder: (context) => const CreateStatusPage());

      case NamedRoutes.statusScreen:
        return MaterialPageRoute(
            builder: (context) => const StatusPage(stories: []));

      case NamedRoutes.settingsScreen:
        return MaterialPageRoute(builder: (context) => const SettingsPage());

      case NamedRoutes.aboutScreen:
        return MaterialPageRoute(builder: (context) => const AboutPage());

      case NamedRoutes.termsScreen:
        return MaterialPageRoute(builder: (context) => const TermsPage());

      case NamedRoutes.privacyScreen:
        return MaterialPageRoute(builder: (context) => const PrivacyPage());

      case NamedRoutes.helpScreen:
        return MaterialPageRoute(builder: (context) => const HelpPage());

      case NamedRoutes.subscribeScreen:
        return MaterialPageRoute(builder: (context) => const SubscribePage());

      case NamedRoutes.notificationScreen:
        return MaterialPageRoute(
            builder: (context) => const NotificationPage());

      case NamedRoutes.twoFactorScreen:
        return MaterialPageRoute(builder: (context) => const TwoFactorPage());

      case NamedRoutes.changePasswordScreen:
        return MaterialPageRoute(
            builder: (context) => const ChangePasswordPage());

      case NamedRoutes.activeSessionsScreen:
        return MaterialPageRoute(
            builder: (context) => const ActiveSessionsPage());

      case NamedRoutes.lockScreenScreen:
        return MaterialPageRoute(builder: (context) => const LockScreenPage());

      default:
        return MaterialPageRoute(
          builder: (context) => const AuthGuard(),
        );
    }
  }
}

class CustomScrollBehavior extends ScrollBehavior {
  const CustomScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
