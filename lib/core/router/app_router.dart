import 'package:clique/core/router/main_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/core/router/named_routes.dart';

import 'package:clique/bloc/friends/friends_bloc.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/insights/insights_bloc.dart';
import 'package:clique/bloc/match/match_bloc.dart';
import 'package:clique/bloc/reels/reel_bloc.dart';
import 'package:clique/bloc/status/stories_bloc.dart';

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
import 'package:clique/ui/pages/main/reels/create_reel_page.dart';

import 'package:clique/ui/pages/main/match/matches_page.dart';

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

class AppRouter {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case NamedRoutes.homeScreen:
      case NamedRoutes.discoverScreen:
      case NamedRoutes.inboxScreen:
      case NamedRoutes.reelsScreen:
        return _page(
          const MainWrapper(),
        );

      case NamedRoutes.loginScreen:
        return _page(
          const LoginPage(),
        );

      case NamedRoutes.registerScreen:
        return _page(
          const RegisterPage(),
        );

      case NamedRoutes.demographicScreen:
        return _page(
          const OnboardingDemographicPage(),
        );

      case NamedRoutes.onboardingSuccessScreen:
        return _page(
          const OnboardingSuccessPage(),
        );

      case NamedRoutes.profileScreen:
        return _page(
          const ProfilePage(
            isOwnProfile: true,
          ),
        );

      case NamedRoutes.editProfileScreen:
        return _page(
          const EditProfilePage(),
        );

      case NamedRoutes.friendListScreen:
        return _page(
          BlocProvider(
            create: (_) => FriendsBloc(),
            child: const FriendsListPage(),
          ),
        );

      case NamedRoutes.insightsScreen:
        return _page(
          BlocProvider(
            create: (_) => InsightsBloc(),
            child: const InsightsPage(),
          ),
        );

      case NamedRoutes.matchScreen:
        return _page(
          BlocProvider(
            create: (_) => MatchBloc(),
            child: const MatchesPage(),
          ),
        );

      case NamedRoutes.createPostScreen:
        return _page(
          BlocProvider(
            create: (_) => FeedBloc(),
            child: const CreatePostPage(),
          ),
        );

      case NamedRoutes.createStatusScreen:
        return _page(
          BlocProvider(
            create: (_) => StoriesBloc(),
            child: const CreateStatusPage(),
          ),
        );

      case NamedRoutes.createReelScreen:
        return _page(
          BlocProvider(
            create: (_) => ReelBloc(),
            child: const CreateReelPage(),
          ),
        );

      case NamedRoutes.statusScreen:
      case NamedRoutes.statusViewScreen:
        return _page(
          BlocProvider(
            create: (_) => StoriesBloc(),
            child: const StatusPage(
              stories: [],
            ),
          ),
        );

      case NamedRoutes.settingsScreen:
        return _page(
          const SettingsPage(),
        );

      case NamedRoutes.aboutScreen:
        return _page(
          const AboutPage(),
        );

      case NamedRoutes.termsScreen:
        return _page(
          const TermsPage(),
        );

      case NamedRoutes.privacyScreen:
        return _page(
          const PrivacyPage(),
        );

      case NamedRoutes.helpScreen:
        return _page(
          const HelpPage(),
        );

      case NamedRoutes.subscribeScreen:
        return _page(
          const SubscribePage(),
        );

      case NamedRoutes.notificationScreen:
      case NamedRoutes.notificationsScreen:
        return _page(
          const NotificationPage(),
        );

      case NamedRoutes.twoFactorScreen:
        return _page(
          const TwoFactorPage(),
        );

      case NamedRoutes.changePasswordScreen:
        return _page(
          const ChangePasswordPage(),
        );

      case NamedRoutes.activeSessionsScreen:
        return _page(
          const ActiveSessionsPage(),
        );

      case NamedRoutes.lockScreenScreen:
        return _page(
          const LockScreenPage(),
        );

      case NamedRoutes.postDetailScreen:
        final postId = settings.arguments;

        if (postId is! int) {
          return _errorRoute(
            'Invalid post ID',
          );
        }

        return _page(
          BlocProvider(
            create: (_) => FeedBloc(),
            child: PostDetailPage(
              postId: postId,
            ),
          ),
        );

      default:
        debugPrint(
          'ROUTE NOT FOUND: ${settings.name}',
        );

        return _errorRoute(
          'Route not found: ${settings.name}',
        );
    }
  }

  static PageRoute _page(
    Widget child,
  ) {
    return MaterialPageRoute(
      builder: (_) => child,
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
