import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';
import 'package:Prive/data/models/feeds_models.dart';
import 'package:Prive/data/providers/feed_provider.dart';
import 'package:Prive/ui/pages/main/status/status_view_page.dart';
import 'package:Prive/ui/pages/settings/settings_page.dart';
import 'package:Prive/ui/widgets/home/card_post.dart';
import 'package:Prive/ui/widgets/status/status_widget.dart';
import '../../../widgets/home/custom_app_bar.dart';
import 'package:Prive/data/services/user/user_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final UserService _userService = UserService();
  Map<String, dynamic> _currentUser = {};
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).fetchData();
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    await _loadCurrentUser();
    await ref.read(feedProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final feedState = ref.watch(feedProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildCustomAppBar(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshAll,
              child: _buildBody(feedState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CachedFeedData feedState) {
    if (feedState.isLoading && feedState.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (feedState.error != null && feedState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              feedState.error!,
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(feedProvider.notifier).fetchData(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 48),
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stories = feedState.stories.cast<Story>();
    final groupedStories = _groupStoriesByUser(stories);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 130),
      children: [
        // Stories Header
        _buildStoriesHeader(),
        const SizedBox(height: 12),
        _buildStatusBar(groupedStories),
        const SizedBox(height: 18),
        _buildPostsList(feedState),
      ],
    );
  }

  Widget _buildStoriesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Stories',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, NamedRoutes.statusScreen);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'More',
              style: AppTheme.greyTextStyle.copyWith(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_StoryGroup> _groupStoriesByUser(List<Story> stories) {
    final Map<int, List<Story>> grouped = {};

    for (final story in stories) {
      if (!grouped.containsKey(story.userId)) {
        grouped[story.userId] = [];
      }
      grouped[story.userId]!.add(story);
    }

    final List<_StoryGroup> groups = [];

    grouped.forEach((userId, userStories) {
      userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final firstStory = userStories.first;

      groups.add(_StoryGroup(
        userId: userId,
        user: firstStory.user,
        stories: userStories,
        hasUnseen: userStories.any((s) => !s.isSeen),
        latestStory: firstStory.createdAt,
      ));
    });

    // Sort: unviewed first, then by latest story
    groups.sort((a, b) {
      if (a.hasUnseen && !b.hasUnseen) return -1;
      if (!a.hasUnseen && b.hasUnseen) return 1;
      return b.latestStory.compareTo(a.latestStory);
    });

    return groups;
  }

  Widget _buildPostsList(CachedFeedData feedState) {
    final posts = feedState.posts;
    final isLoadingMore = feedState.isLoadingMore;
    final hasMore = feedState.hasMore;

    if (posts.isEmpty) {
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
        for (final post in posts)
          SizedBox(
            width: double.infinity,
            child: CardPost(post: post),
          ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : TextButton(
                      onPressed: () =>
                          ref.read(feedProvider.notifier).loadMore(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(
                        'Load More',
                        style: AppTheme.blackTextStyle.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatusBar(List<_StoryGroup> groupedStories) {
    return SizedBox(
      height: 104,
      width: double.infinity,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: groupedStories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            // My Story button
            return StatusWidget(
              name: 'My Status',
              avatar: _getUserAvatar(),
              isAddStatus: true,
              statusCount: 0,
              hasUnviewed: false,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, NamedRoutes.createStatusScreen);
              },
            );
          }

          final group = groupedStories[index - 1];
          return StatusWidget(
            name: group.user.name,
            avatar: group.user.avatar,
            statusCount: group.stories.length,
            hasUnviewed: group.hasUnseen,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatusViewPage(
                    stories: group.stories,
                    initialIndex: 0,
                    statuses: [],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getUserDisplayName() {
    if (_isLoadingUser) {
      return 'Loading...';
    }

    final name = _currentUser['name'];
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }

    final username = _currentUser['username'];
    if (username != null && username.toString().trim().isNotEmpty) {
      return username.toString().trim();
    }

    return 'User';
  }

  String _getUserAvatar() {
    if (_isLoadingUser) {
      return '';
    }
    return (_currentUser['avatar'] ??
            _currentUser['avatarUrl'] ??
            _currentUser['avatar_url'] ??
            _currentUser['image'] ??
            '')
        .toString();
  }

  Widget _buildCustomAppBar() {
    final userName = _getUserDisplayName();
    final userAvatar = _getUserAvatar();
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return CustomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            // App logo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/images/prive.png',
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(width: 10),
            // Notification button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, NamedRoutes.notificationScreen);
              },
              child: Icon(
                Icons.notifications_active,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            // Search button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Navigate to search
              },
              child: Icon(
                Icons.search_outlined,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const Spacer(),
            // Profile button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  color: AppColors.primary,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAvatar(userAvatar,
                        size: 32, fallbackText: firstLetter),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.whiteTextStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (_currentUser['verified'] == true) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: Colors.white,
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

  Widget _buildAvatar(String avatar,
      {required double size, required String fallbackText}) {
    if (avatar.isNotEmpty && avatar.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(size, fallbackText),
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
          errorBuilder: (_, __, ___) => _avatarFallback(size, fallbackText),
        ),
      );
    }

    return _avatarFallback(size, fallbackText);
  }

  Widget _avatarFallback(double size, String fallbackText) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.25),
      ),
      child: Center(
        child: Text(
          fallbackText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _StoryGroup {
  final int userId;
  final StoryUser user;
  final List<Story> stories;
  final bool hasUnseen;
  final DateTime latestStory;

  _StoryGroup({
    required this.userId,
    required this.user,
    required this.stories,
    required this.hasUnseen,
    required this.latestStory,
  });
}
