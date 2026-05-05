import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/app/resources/constant/named_routes.dart';
import 'package:social_media_app/data/hooks/home/feed_hook.dart';
import 'package:social_media_app/data/hooks/home/story_hook.dart';
import 'package:social_media_app/data/models/status_model.dart';
import 'package:social_media_app/ui/pages/main/status/status_view_page.dart';
import 'package:social_media_app/ui/widgets/home/card_post.dart';
import 'package:social_media_app/ui/widgets/status/status_widget.dart';

import '../../../widgets/home/custom_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FeedHook _feedHook = FeedHook();
  final StoryHook _storyHook = StoryHook();

  @override
  void initState() {
    super.initState();

    _feedHook.addListener(_onHookChanged);
    _storyHook.addListener(_onHookChanged);

    _feedHook.initialize();
    _storyHook.fetchStories();
  }

  void _onHookChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _feedHook.removeListener(_onHookChanged);
    _storyHook.removeListener(_onHookChanged);
    _feedHook.dispose();
    _storyHook.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _feedHook.refresh(),
      _storyHook.refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
            child: _buildCustomAppBar(context),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.purpleColor,
              onRefresh: _refreshAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 130),
                children: [
                  _buildStatusBar(context),
                  const SizedBox(height: 18),
                  _buildPostsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    final isInitialLoading =
        (_feedHook.loading || _storyHook.loading) && _feedHook.posts.isEmpty;

    if (isInitialLoading) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.purpleColor),
        ),
      );
    }

    if (_feedHook.error != null && _feedHook.posts.isEmpty) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _feedHook.error!,
                textAlign: TextAlign.center,
                style: AppTheme.greyTextStyle,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _feedHook.fetchPosts(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_feedHook.posts.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.post_add,
                size: 64,
                color: AppColors.greyColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh',
                style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final post in _feedHook.posts)
          SizedBox(
            width: double.infinity,
            child: CardPost(post: post),
          ),
        if (_feedHook.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _feedHook.loadingMore
                  ? const CircularProgressIndicator(
                      color: AppColors.purpleColor,
                    )
                  : TextButton(
                      onPressed: _feedHook.loadMorePosts,
                      child: Text(
                        'Load More',
                        style: AppTheme.blackTextStyle.copyWith(
                          color: AppColors.purpleColor,
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    final stories = _storyHook.stories;
    final currentUser = _feedHook.user ?? {};

    return SizedBox(
      height: 104,
      width: double.infinity,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: stories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return StatusWidget(
              status: StatusModel(
                name: 'Your Story',
                imgProfile: _userAvatar(currentUser),
                statusImage: '',
                time: '',
              ),
              isAddStatus: true,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, NamedRoutes.createStatusScreen);
              },
            );
          }

          final story = stories[index - 1];
          final status = _storyToStatus(story);

          return StatusWidget(
            status: status,
            onTap: () {
              HapticFeedback.lightImpact();

              final statuses = stories
                  .map<StatusModel>((item) => _storyToStatus(item))
                  .toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatusViewPage(
                    statuses: statuses,
                    initialIndex: index - 1,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  CustomAppBar _buildCustomAppBar(BuildContext context) {
    final user = _feedHook.user ?? {};
    final name = _displayName(user);
    final avatar = _userAvatar(user);

    return CustomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            Image.asset(
              'assets/images/prive.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 14),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, NamedRoutes.notificationScreen);
              },
              child: Image.asset(
                'assets/images/ic_notification.png',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 14),
            InkWell(
              onTap: () {},
              child: Image.asset(
                'assets/images/ic_search.png',
                width: 28,
                height: 28,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, NamedRoutes.profileScreen);
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 150),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  color: AppColors.backgroundColor,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAvatar(avatar, size: 28),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.blackTextStyle.copyWith(
                          fontWeight: AppTheme.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (user['verified'] == true) ...[
                      const SizedBox(width: 4),
                      Image.asset(
                        'assets/images/ic_checklist.png',
                        width: 16,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  StatusModel _storyToStatus(Map<String, dynamic> story) {
    final user = _asMap(story['user']);
    final attachments = story['attachments'];

    String statusImage = '';

    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;

      if (first is Map) {
        statusImage = (first['url'] ?? first['uri'] ?? '').toString();
      } else if (first is String) {
        statusImage = first;
      }
    }

    return StatusModel(
      name: _displayName(user),
      imgProfile: _userAvatar(user),
      statusImage: statusImage,
      time: (story['time'] ?? story['createdAt'] ?? story['created_at'] ?? '')
          .toString(),
      isViewed: story['isSeen'] == true || story['is_seen'] == true,
    );
  }

  Widget _buildAvatar(String avatar, {required double size}) {
    if (avatar.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(size),
        ),
      );
    }

    if (avatar.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(size),
        ),
      );
    }

    return _avatarFallback(size);
  }

  Widget _avatarFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.greyColor.withOpacity(0.25),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.65,
        color: AppColors.greyColor,
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  String _displayName(Map<String, dynamic> user) {
    final name = user['name'];
    final username = user['username'];
    final email = user['email'];

    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString();
    }

    if (username != null && username.toString().trim().isNotEmpty) {
      return username.toString();
    }

    if (email != null && email.toString().trim().isNotEmpty) {
      return email.toString().split('@').first;
    }

    return 'User';
  }

  String _userAvatar(Map<String, dynamic> user) {
    return (user['avatar'] ??
            user['avatarUrl'] ??
            user['avatar_url'] ??
            user['image'] ??
            '')
        .toString();
  }
}
