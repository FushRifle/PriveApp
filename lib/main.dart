import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';
import 'package:Prive/data/models/post_model.dart';
import 'package:Prive/ui/pages/main/explore/explore_page.dart';
import 'package:Prive/ui/pages/main/chat/inbox_page.dart';
import 'package:Prive/ui/pages/main/home/home_page.dart';
import 'package:Prive/ui/pages/main/home/post_detail_page.dart';
import 'package:Prive/ui/pages/main/notification/notification_page.dart';
import 'package:Prive/ui/pages/main/profile/edit_profile_page.dart';
import 'package:Prive/ui/pages/social/insights_page.dart';
import 'package:Prive/ui/pages/main/profile/profile_page.dart';
import 'package:Prive/ui/pages/main/reels/reels_page.dart';
import 'package:Prive/ui/pages/main/home/create_post_page.dart';
import 'package:Prive/ui/pages/main/status/create_status_page.dart';
import 'package:Prive/ui/pages/auth/login_page.dart';
import 'package:Prive/ui/pages/auth/register_page.dart';
import 'package:Prive/ui/pages/settings/settings_page.dart';
import 'package:Prive/ui/pages/settings/subscribe_page.dart';
import 'package:Prive/ui/pages/social/friends_list_page.dart';
import 'package:Prive/ui/pages/social/matches_page.dart';
import 'package:Prive/ui/widgets/home/clip_status_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Prive/app/configs/api_config.dart';
import 'package:Prive/data/providers/theme_provider.dart';

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
  bool _isLoading = true;
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      _initialRoute =
          session != null ? NamedRoutes.homeScreen : NamedRoutes.loginScreen;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Prive',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const CustomScrollBehavior(),
      initialRoute: _initialRoute,
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
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case NamedRoutes.postDetailScreen:
        final args = settings.arguments;
        if (args == null) {
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('Invalid post data')),
            ),
          );
        }

        final post = args is PostModel
            ? args
            : args is Map<String, dynamic>
                ? PostModel.fromJson(args)
                : PostModel(
                    name: 'User',
                    imgProfile: '',
                    picture: '',
                    caption: '',
                    createdAt: DateTime.now(),
                  );

        return MaterialPageRoute(
          builder: (context) => PostDetailPage(post: post),
        );

      case NamedRoutes.loginScreen:
        return MaterialPageRoute(builder: (context) => const LoginPage());

      case NamedRoutes.registerScreen:
        return MaterialPageRoute(builder: (context) => const RegisterPage());

      case NamedRoutes.homeScreen:
        return MaterialPageRoute(builder: (context) => const MainWrapper());

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

      case NamedRoutes.settingsScreen:
        return MaterialPageRoute(builder: (context) => const SettingsPage());

      case NamedRoutes.subscribeScreen:
        return MaterialPageRoute(builder: (context) => const SubscribePage());

      case NamedRoutes.notificationScreen:
        return MaterialPageRoute(
            builder: (context) => const NotificationPage());

      default:
        final session = Supabase.instance.client.auth.currentSession;
        return MaterialPageRoute(
          builder: (context) =>
              session != null ? const MainWrapper() : const LoginPage(),
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

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const DiscoverPage(),
    const ReelsPage(),
    const InboxPage(),
  ];

  final List<BottomNavItem> _navItems = [
    BottomNavItem(icon: Icons.home, label: 'Home'),
    BottomNavItem(icon: Icons.explore, label: 'Discover'),
    BottomNavItem(icon: Icons.play_circle_fill, label: 'Reels'),
    BottomNavItem(icon: Icons.message, label: 'Inbox'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkBackground : Colors.white;

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          if (_currentIndex != 2) _buildBackgroundGradient(),
          if (_currentIndex != 2)
            Positioned(
              bottom: 91,
              child: Transform.rotate(
                angle: 11,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(
                      context,
                      NamedRoutes.createPostScreen,
                    );
                  },
                  child: ClipPath(
                    clipper: ClipStatusBar(),
                    child: Container(
                      height: 110,
                      width: 40,
                      color: AppColors.primary,
                      child: const Icon(
                        Icons.add,
                        size: 24,
                        color: AppColors.whiteColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_currentIndex != 2) _buildBottomNavBar(backgroundColor),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientColor = isDarkMode ? AppColors.darkBackground : Colors.white;

    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColor.withOpacity(0),
            gradientColor.withOpacity(0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(Color backgroundColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor =
        isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 25),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < _navItems.length; i++)
                _buildNavItem(_navItems[i], i, unselectedColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BottomNavItem item, int index, Color unselectedColor) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    Icon(
                      item.icon,
                      size: 24,
                      color: isSelected ? AppColors.primary : unselectedColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : unselectedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.label,
  });
}
