import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';
import 'package:Prive/data/models/post_model.dart';
import 'package:Prive/ui/pages/main/discover/discover_page.dart';
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
import 'package:Prive/ui/pages/auth/onboarding_page.dart';
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Prive',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const CustomScrollBehavior(),
      initialRoute: NamedRoutes.onboardingScreen,
      onGenerateRoute: (settings) {
        // Handle routes with arguments safely
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

            PostModel post;
            if (args is PostModel) {
              post = args;
            } else if (args is Map<String, dynamic>) {
              post = PostModel.fromJson(args);
            } else {
              post = const PostModel(
                name: 'User',
                imgProfile: '',
                picture: '',
                caption: '',
              );
            }

            return MaterialPageRoute(
              builder: (context) => PostDetailPage(post: post),
            );

          case NamedRoutes.onboardingScreen:
            return MaterialPageRoute(
                builder: (context) => const OnboardingPage());
          case NamedRoutes.loginScreen:
            return MaterialPageRoute(builder: (context) => const LoginPage());
          case NamedRoutes.registerScreen:
            return MaterialPageRoute(
                builder: (context) => const RegisterPage());
          case NamedRoutes.homeScreen:
            return MaterialPageRoute(builder: (context) => const MainWrapper());
          case NamedRoutes.profileScreen:
            return MaterialPageRoute(builder: (context) => const ProfilePage());
          case NamedRoutes.editProfileScreen:
            return MaterialPageRoute(
                builder: (context) => const EditProfilePage());
          case NamedRoutes.friendListScreen:
            return MaterialPageRoute(
                builder: (context) => const FriendsListPage());
          case NamedRoutes.insightsScreen:
            return MaterialPageRoute(
                builder: (context) => const InsightsPage());
          case NamedRoutes.matchScreen:
            return MaterialPageRoute(builder: (context) => const MatchesPage());
          case NamedRoutes.createPostScreen:
            return MaterialPageRoute(
                builder: (context) => const CreatePostPage());
          case NamedRoutes.createStatusScreen:
            return MaterialPageRoute(
                builder: (context) => const CreateStatusPage());
          case NamedRoutes.settingsScreen:
            return MaterialPageRoute(
                builder: (context) => const SettingsPage());
          case NamedRoutes.subscribeScreen:
            return MaterialPageRoute(
                builder: (context) => const SubscribePage());
          case NamedRoutes.notificationScreen:
            return MaterialPageRoute(
                builder: (context) => const NotificationPage());
          default:
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Page not found')),
              ),
            );
        }
      },
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }

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
}

// Custom scroll behavior to hide scroll indicators
class CustomScrollBehavior extends ScrollBehavior {
  const CustomScrollBehavior();

  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

// MainWrapper stays exactly the same...
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

  @override
  Widget build(BuildContext context) {
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
          if (_currentIndex != 2) _buildBottomNavBar(),
        ],
      ),
    );
  }

  Container _buildBottomNavBar() {
    return Container(
      width: double.infinity,
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      margin: const EdgeInsets.only(
        right: 14,
        left: 14,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildItemBottomNavBar(
              Icons.home,
              "Home",
              0,
            ),
          ),
          Expanded(
            child: _buildItemBottomNavBar(
              Icons.explore,
              "Discover",
              1,
            ),
          ),
          Expanded(
            child: _buildItemBottomNavBar(
              Icons.play_circle_fill,
              "Reels",
              2,
            ),
          ),
          Expanded(
            child: _buildItemBottomNavBar(
              Icons.message,
              "Inbox",
              3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemBottomNavBar(
    IconData icon,
    String title,
    int index,
  ) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isSelected ? AppColors.whiteColor : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.blackColor.withOpacity(0.1),
                    blurRadius: 35,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.purpleColor : AppColors.blackColor,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: isSelected ? AppTheme.bold : AppTheme.medium,
                    fontSize: 11,
                    color: isSelected
                        ? AppColors.purpleColor
                        : AppColors.blackColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildBackgroundGradient() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.whiteColor.withOpacity(0),
            AppColors.whiteColor.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
