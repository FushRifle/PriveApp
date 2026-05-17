import 'package:Prive/bloc/profile/profile_bloc.dart';
import 'package:Prive/bloc/status/stories_bloc.dart';
import 'package:Prive/data/models/feeds_models.dart';
import 'package:Prive/ui/pages/auth/success_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';
import 'package:Prive/bloc/auth/auth_bloc.dart';
import 'package:Prive/data/models/post_model.dart';
import 'package:Prive/ui/pages/main/home/post_detail_page.dart';
import 'package:Prive/ui/pages/main/notification/notification_page.dart';
import 'package:Prive/ui/pages/main/profile/edit_profile_page.dart';
import 'package:Prive/ui/pages/social/insights_page.dart';
import 'package:Prive/ui/pages/main/profile/profile_page.dart';
import 'package:Prive/ui/pages/main/home/create_post_page.dart';
import 'package:Prive/ui/pages/main/status/create_status_page.dart';
import 'package:Prive/ui/pages/main/status/status_page.dart';
import 'package:Prive/ui/pages/auth/login_page.dart';
import 'package:Prive/ui/pages/auth/register_page.dart';
import 'package:Prive/ui/pages/auth/demographic_page.dart';
import 'package:Prive/ui/pages/settings/settings_page.dart';
import 'package:Prive/ui/pages/settings/subscribe_page.dart';
import 'package:Prive/ui/pages/social/friends_list_page.dart';
import 'package:Prive/ui/pages/social/matches_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:Prive/app/configs/api_config.dart';
import 'package:Prive/data/providers/theme_provider.dart';
import 'package:Prive/bloc/home/feed_bloc.dart';
import 'package:Prive/bloc/user/user_bloc.dart';
import 'package:Prive/bloc/friends/friends_bloc.dart';
import 'package:Prive/bloc/explore/explore_bloc.dart';
import 'package:Prive/bloc/reels/reel_bloc.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:Prive/managers/auth_guard.dart';

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
        BlocProvider(create: (context) => ProfileBloc()),
      ],
      child: MultiBlocListener(
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
                    ScaffoldMessenger.of(context).showSnackBar(
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
        child: MaterialApp(
          title: 'Prive',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          scrollBehavior: const CustomScrollBehavior(),
          home: const AuthGuard(),
          onGenerateRoute: _generateRoute,
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            final mediaQueryData = MediaQuery.of(context);

            if (kIsWeb) {
              return MediaQuery(
                data: mediaQueryData.copyWith(
                  viewInsets: EdgeInsets.zero,
                  viewPadding: EdgeInsets.only(
                    top: mediaQueryData.padding.top,
                    bottom: mediaQueryData.padding.bottom,
                  ),
                ),
                child: child,
              );
            }
            return child;
          },
        ),
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case NamedRoutes.postDetailScreen:
        final args = settings.arguments;
        if (args == null || args is! FeedPost) {
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('Invalid post data')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (context) => PostDetailPage(post: args),
        );

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
        return MaterialPageRoute(builder: (context) => const ProfilePage());

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

      case NamedRoutes.subscribeScreen:
        return MaterialPageRoute(builder: (context) => const SubscribePage());

      case NamedRoutes.notificationScreen:
        return MaterialPageRoute(
            builder: (context) => const NotificationPage());

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
