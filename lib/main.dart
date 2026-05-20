import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/chat/gallery/chat_gallery_cubit.dart';
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
    debug: true,
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
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
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
        BlocProvider<AuthBloc>.value(
          value: _authBloc,
        ),
        BlocProvider<UserBloc>(
          create: (context) => UserBloc(),
        ),
        BlocProvider<FriendsBloc>(
          create: (context) => FriendsBloc(),
        ),
        BlocProvider<InsightsBloc>(
          create: (context) => InsightsBloc(),
        ),
        BlocProvider<MatchBloc>(
          create: (context) => MatchBloc(),
        ),
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
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(),
        ),
        BlocProvider<ChatGalleryCubit>(
          create: (context) => ChatGalleryCubit(),
        ),
        BlocProvider(create: (context) => ProfileBloc()),
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
          MediaQuery.of(context);
          return MultiBlocListener(
            listeners: [
              BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state.status == AuthStatus.error &&
                      state.error?.contains('token') == true) {
                    _authBloc.add(SignOutRequested());
                  }
                },
              ),
              BlocListener<ProfileBloc, ProfileState>(
                listener: (context, state) {
                  if (state.status == ProfileStatus.success && mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.pushReplacementNamed(
                            context, NamedRoutes.onboardingSuccessScreen);
                      }
                    });
                  }
                  if (state.status == ProfileStatus.error &&
                      state.error != null &&
                      mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text(state.error!),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
                  }
                },
              ),
            ],
            child: child,
          );
        },
      ),
    );
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

      case NamedRoutes.homeScreen:
        return MaterialPageRoute(builder: (context) => const AuthGuard());

      case NamedRoutes.profileScreen:
        return MaterialPageRoute(
            builder: (context) => const ProfilePage(
                  isOwnProfile: true,
                ));

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
          builder: (context) => const StatusPage(
            stories: [],
          ),
        );

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
