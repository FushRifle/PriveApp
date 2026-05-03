import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/app/resources/constant/named_routes.dart';
import 'package:social_media_app/data/models/post_model.dart';
import 'package:social_media_app/ui/pages/main/discover/discover_page.dart';
import 'package:social_media_app/ui/pages/main/chat/inbox_page.dart';
import 'package:social_media_app/ui/pages/main/home/home_page.dart';
import 'package:social_media_app/ui/pages/main/home/post_detail_page.dart';
import 'package:social_media_app/ui/pages/main/notification/notification_page.dart';
import 'package:social_media_app/ui/pages/main/profile/edit_profile_page.dart';
import 'package:social_media_app/ui/pages/social/insights_page.dart';
import 'package:social_media_app/ui/pages/main/profile/profile_page.dart';
import 'package:social_media_app/ui/pages/main/reels/reels_page.dart';
import 'package:social_media_app/ui/pages/main/post/create_post_page.dart';
import 'package:social_media_app/ui/pages/main/status/create_status_page.dart';
import 'package:social_media_app/ui/pages/auth/onboarding_page.dart';
import 'package:social_media_app/ui/pages/auth/login_page.dart';
import 'package:social_media_app/ui/pages/auth/register_page.dart';
import 'package:social_media_app/ui/pages/settings/settings_page.dart';
import 'package:social_media_app/ui/pages/settings/subscribe_page.dart';
import 'package:social_media_app/ui/pages/social/friends_list_page.dart';
import 'package:social_media_app/ui/pages/social/matches_page.dart';
import 'package:social_media_app/ui/widgets/home/clip_status_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ClerkAuth wrapper removed – using plain MaterialApp
    return MaterialApp(
      title: 'Prive',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: NamedRoutes.onboardingScreen,
      routes: {
        NamedRoutes.onboardingScreen: (context) => const OnboardingPage(),
        NamedRoutes.loginScreen: (context) => const LoginPage(),
        NamedRoutes.registerScreen: (context) => const RegisterPage(),
        NamedRoutes.homeScreen: (context) => const MainWrapper(),
        NamedRoutes.profileScreen: (context) => const ProfilePage(),
        NamedRoutes.editProfileScreen: (context) => const EditProfilePage(),
        NamedRoutes.friendListScreen: (context) => const FriendsListPage(),
        NamedRoutes.insightsScreen: (context) => const InsightsPage(),
        NamedRoutes.matchScreen: (context) => const MatchesPage(),
        NamedRoutes.postDetailScreen: (context) {
          final post = ModalRoute.of(context)!.settings.arguments as PostModel;
          return PostDetailPage(post: post);
        },
        NamedRoutes.createPostScreen: (context) => const CreatePostPage(),
        NamedRoutes.createStatusScreen: (context) => const CreateStatusPage(),
        NamedRoutes.settingsScreen: (context) => const SettingsPage(),
        NamedRoutes.subscribeScreen: (context) => const SubscribePage(),
        NamedRoutes.notificationScreen: (context) => const NotificationPage(),
      },
      builder: (context, child) {
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
            child: child!,
          );
        }
        return child!;
      },
    );
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
          IndexedStack(index: _currentIndex, children: _pages),
          if (_currentIndex != 2) _buildBackgroundGradient(),
          if (_currentIndex != 2)
            Positioned(
              bottom: 91,
              child: Transform.rotate(
                angle: 11,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, NamedRoutes.createPostScreen);
                  },
                  child: ClipPath(
                    clipper: ClipStatusBar(),
                    child: Container(
                      height: 110,
                      width: 40,
                      color: AppColors.blackColor,
                      child: const Icon(Icons.add,
                          size: 24, color: AppColors.whiteColor),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(right: 24, left: 24, bottom: 16),
      decoration: BoxDecoration(
          color: AppColors.whiteColor, borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildItemBottomNavBar(Icons.home, "Home", 0)),
          Expanded(child: _buildItemBottomNavBar(Icons.explore, "Discover", 1)),
          Expanded(
              child:
                  _buildItemBottomNavBar(Icons.play_circle_fill, "Reels", 2)),
          Expanded(child: _buildItemBottomNavBar(Icons.message, "Inbox", 3)),
        ],
      ),
    );
  }

  Widget _buildItemBottomNavBar(IconData icon, String title, int index) {
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
                      offset: const Offset(0, 10))
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 24,
                color:
                    isSelected ? AppColors.purpleColor : AppColors.blackColor),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(title,
                    style: AppTheme.blackTextStyle.copyWith(
                      fontWeight: isSelected ? AppTheme.bold : AppTheme.medium,
                      fontSize: 11,
                      color: isSelected
                          ? AppColors.purpleColor
                          : AppColors.blackColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildBackgroundGradient() => Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.whiteColor.withOpacity(0),
              AppColors.whiteColor.withOpacity(0.8)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
}
