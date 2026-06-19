import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/core/router/auth_guard.dart';
import 'package:clique/core/router/named_routes.dart';

import 'package:clique/bloc/friends/friends_bloc.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/insights/insights_bloc.dart';
import 'package:clique/bloc/match/match_bloc.dart';
import 'package:clique/bloc/reels/reel_bloc.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/bloc/community/community_bloc.dart';
import 'package:clique/bloc/event/event_bloc.dart';
import 'package:clique/bloc/settings/settings_bloc.dart';

import 'package:clique/ui/pages/auth/demographic_page.dart';
import 'package:clique/ui/pages/auth/onboarding_page.dart';
import 'package:clique/ui/pages/auth/register_page.dart';
import 'package:clique/ui/pages/auth/security/active_sessions_page.dart';
import 'package:clique/ui/pages/auth/security/change_password_page.dart';
import 'package:clique/ui/pages/auth/security/lock_screen_page.dart';
import 'package:clique/ui/pages/auth/security/two_factor_page.dart';
import 'package:clique/ui/pages/auth/success_page.dart';

import 'package:clique/ui/pages/main/home/create_post_page.dart';
import 'package:clique/ui/pages/main/home/edit_post_page.dart';
import 'package:clique/ui/pages/main/home/post_detail_page.dart';
import 'package:clique/ui/pages/main/topics/topics_page.dart';
import 'package:clique/ui/pages/main/chat/chat_page.dart';
import 'package:clique/ui/pages/main/community/create_community_page.dart';
import 'package:clique/ui/pages/main/community/community_group_chat_page.dart';
import 'package:clique/ui/pages/main/community/community_group_info_page.dart';
import 'package:clique/core/models/community_model.dart';
import 'package:clique/core/models/event_model.dart';
import 'package:clique/ui/pages/main/event/create_event_page.dart';
import 'package:clique/ui/pages/main/event/event_details_page.dart';
import 'package:clique/ui/pages/main/reels/create_reel_page.dart';

import 'package:clique/ui/pages/main/match/matches_page.dart';
import 'package:clique/core/models/status_model.dart';

import 'package:clique/ui/pages/main/notification/notification_page.dart';

import 'package:clique/ui/pages/main/profile/edit_profile_page.dart';
import 'package:clique/ui/pages/main/profile/account_switch_page.dart';
import 'package:clique/ui/pages/main/profile/other_profile_page.dart';
import 'package:clique/ui/pages/main/profile/profile_page.dart';

import 'package:clique/ui/pages/main/status/create_status_page.dart';
import 'package:clique/ui/pages/main/status/edit_status_page.dart';
import 'package:clique/ui/pages/main/status/status_page.dart';

import 'package:clique/ui/pages/settings/settings_page.dart';
import 'package:clique/ui/pages/settings/subscribe_page.dart';

import 'package:clique/ui/pages/Clique/about_page.dart';
import 'package:clique/ui/pages/Clique/help_page.dart';
import 'package:clique/ui/pages/Clique/privacy_page.dart';
import 'package:clique/ui/pages/Clique/terms_page.dart';

import 'package:clique/ui/pages/social/friends_list_page.dart';
import 'package:clique/ui/pages/social/insights_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case NamedRoutes.homeScreen:
      case NamedRoutes.discoverScreen:
      case NamedRoutes.communityScreen:
      case NamedRoutes.eventsScreen:
      case NamedRoutes.inboxScreen:
      case NamedRoutes.reelsScreen:
        return _page(
          const AuthGuard(),
        );

      case NamedRoutes.loginScreen:
        return _page(
          const AuthGuard(),
        );

      case NamedRoutes.registerScreen:
        return _page(
          const RegisterPage(),
        );

      case NamedRoutes.onboardingScreen:
        return _page(
          const OnboardingPage(),
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
          const ProfilePage(),
        );

      case NamedRoutes.otherProfileScreen:
        final userId = _readUserId(settings.arguments);
        final parsedUserId = int.tryParse(userId ?? '');
        if (parsedUserId == null || parsedUserId <= 0) {
          return _errorRoute('Invalid user ID');
        }

        return _page(
          OtherProfilePage(
            userId: parsedUserId,
          ),
        );

      case NamedRoutes.editProfileScreen:
        return _page(
          const EditProfilePage(),
        );

      case NamedRoutes.accountSwitchScreen:
        return _page(
          const AccountSwitchPage(),
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

      case NamedRoutes.chatScreen:
        final args = _readChatArgs(settings.arguments);
        final conversationId = args['conversationId'] as int;
        if (conversationId <= 0) {
          return _errorRoute('Invalid conversation ID');
        }

        return _page(
          BlocProvider(
            create: (_) => ChatBloc(),
            child: ChatPage(
              conversationId: conversationId,
              userName: args['userName'] as String,
              userAvatar: args['userAvatar'] as String,
              userId: args['userId'] as int,
              maxOutgoingMessages: args['messageLimit'] as int? ?? 0,
              messageLimitHint: args['messageLimitHint'] as String?,
            ),
          ),
        );

      case NamedRoutes.createPostScreen:
        return _page(
          BlocProvider(
            create: (_) => FeedBloc(),
            child: const CreatePostPage(),
          ),
        );

      case NamedRoutes.topicsScreen:
        return _page(
          BlocProvider(
            create: (_) => FeedBloc(),
            child: const TopicsPage(),
          ),
        );

      case NamedRoutes.editPostScreen:
        final postArgs = settings.arguments;
        if (postArgs is! Map) {
          return _errorRoute('Invalid post edit arguments');
        }

        final postId = _readInt(postArgs['postId'] ?? postArgs['id']);
        final ownerId = _readInt(postArgs['ownerId'] ?? postArgs['userId']);
        final initialContent = (postArgs['content'] ?? '').toString();
        final createdAtRaw = postArgs['createdAt'] ?? postArgs['created_at'];
        final createdAt = createdAtRaw is DateTime
            ? createdAtRaw
            : DateTime.tryParse(createdAtRaw?.toString() ?? '');
        if (postId <= 0) {
          return _errorRoute('Invalid post ID');
        }
        if (ownerId <= 0) {
          return _errorRoute('Invalid post owner');
        }
        if (createdAt == null) {
          return _errorRoute('Invalid post timestamp');
        }

        return _page(
          BlocProvider(
            create: (_) => FeedBloc(),
            child: EditPostPage(
              postId: postId,
              ownerId: ownerId,
              initialContent: initialContent,
              createdAt: createdAt,
            ),
          ),
        );

      case NamedRoutes.createStatusScreen:
        return _page(
          BlocProvider(
            create: (_) => StoriesBloc(),
            child: const CreateStatusPage(),
          ),
        );

      case NamedRoutes.editStatusScreen:
        final story = settings.arguments;
        if (story is! Story) {
          return _errorRoute('Invalid story');
        }

        return _page(
          BlocProvider(
            create: (_) => StoriesBloc(),
            child: EditStatusPage(story: story),
          ),
        );

      case NamedRoutes.createReelScreen:
        return _page(
          BlocProvider(
            create: (_) => ReelBloc(),
            child: const CreateReelPage(),
          ),
        );

      case NamedRoutes.createCommunityScreen:
        return _page(
          BlocProvider(
            create: (_) => CommunityBloc(),
            child: const CreateCommunityPage(),
          ),
        );

      case NamedRoutes.createEventScreen:
        return _page(
          BlocProvider(
            create: (_) => EventBloc(),
            child: const CreateEventPage(),
          ),
        );

      case NamedRoutes.eventDetailsScreen:
        final event = settings.arguments;
        if (event is! EventModel) {
          return _errorRoute('Invalid event');
        }

        return _page(
          BlocProvider(
            create: (_) => EventBloc(),
            child: EventDetailsPage(event: event),
          ),
        );

      case NamedRoutes.communityGroupChatScreen:
        final args = _readCommunityGroupArgs(settings.arguments);
        final group = args['group'];
        if (group is! CommunityGroupModel) {
          return _errorRoute('Invalid group');
        }
        return _page(
          BlocProvider(
            create: (_) => CommunityBloc(),
            child: CommunityGroupChatPage(group: group),
          ),
        );

      case NamedRoutes.communityGroupInfoScreen:
        final args = _readCommunityGroupArgs(settings.arguments);
        final group = args['group'];
        if (group is! CommunityGroupModel) {
          return _errorRoute('Invalid group');
        }
        return _page(
          CommunityGroupInfoPage(
            group: group,
            members: args['members'] is List<CommunityMemberModel>
                ? args['members'] as List<CommunityMemberModel>
                : const <CommunityMemberModel>[],
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
          BlocProvider(
            create: (_) => SettingsBloc(),
            child: const SettingsPage(),
          ),
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
        final args = settings.arguments;
        final userId = args is Map
            ? _readInt(args['userId'])
            : _readInt(settings.arguments);
        final verifyOnly = args is Map && args['verifyOnly'] == true;
        return _page(
          LockScreenPage(
            userId: userId > 0 ? userId : null,
            verifyOnly: verifyOnly,
          ),
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

  static String? _readUserId(Object? arguments) {
    if (arguments == null) return null;
    if (arguments is int) return arguments.toString();
    if (arguments is String) return arguments;
    if (arguments is Map) {
      final value =
          arguments['userId'] ?? arguments['user_id'] ?? arguments['id'];
      return value?.toString();
    }

    return null;
  }

  static Map<String, Object?> _readChatArgs(Object? arguments) {
    if (arguments is! Map) {
      return {
        'conversationId': 0,
        'userName': '',
        'userAvatar': '',
        'userId': 0,
        'messageLimit': 0,
        'messageLimitHint': null,
      };
    }

    return {
      'conversationId': _readInt(
        arguments['conversationId'] ?? arguments['conversation_id'],
      ),
      'userName': (arguments['userName'] ?? arguments['name'] ?? '').toString(),
      'userAvatar':
          (arguments['userAvatar'] ?? arguments['avatar'] ?? '').toString(),
      'userId': _readInt(arguments['userId'] ?? arguments['user_id']),
      'messageLimit':
          _readInt(arguments['messageLimit'] ?? arguments['message_limit']),
      'messageLimitHint':
          arguments['messageLimitHint'] ?? arguments['message_limit_hint'],
    };
  }

  static Map<String, Object?> _readCommunityGroupArgs(Object? arguments) {
    if (arguments is! Map) {
      return const {};
    }

    return {
      'group': arguments['group'],
      'members': arguments['members'],
    };
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
