import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/app/resources/constant/named_routes.dart';
import 'package:clique/data/models/status_model.dart';
import 'package:clique/ui/pages/main/status/status_view_page.dart';
import 'package:clique/ui/pages/settings/settings_page.dart';
import 'package:clique/ui/widgets/home/card_post.dart';
import 'package:clique/ui/widgets/status/status_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadInitialData();
  }

  void _loadCurrentUser() {
    context.read<UserBloc>().add(LoadCurrentUser());
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FeedBloc>().add(GetFeedPosts());
        context.read<StoriesBloc>().add(GetStories());
      }
    });
  }

  void _silentRefresh() {
    context.read<FeedBloc>().add(RefreshFeed());
    context.read<StoriesBloc>().add(GetStories());
    context.read<UserBloc>().add(RefreshCurrentUser());
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Column(
        children: [
          _buildCustomAppBar(),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.pixels <= 0 &&
                    scrollInfo.metrics.axisDirection == AxisDirection.down) {
                  _silentRefresh();
                }
                return false;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Stories section
                    BlocBuilder<StoriesBloc, StoriesState>(
                      builder: (context, storiesState) {
                        return _buildStoriesSection(storiesState);
                      },
                    ),
                    // Feed section
                    BlocBuilder<FeedBloc, FeedState>(
                      builder: (context, feedState) {
                        return _buildFeedSection(feedState);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection(StoriesState storiesState) {
    final stories = storiesState.stories;
    final isLoading = storiesState.status == StoriesStatus.loading;

    if (isLoading && _isInitialLoad && stories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (stories.isNotEmpty && _isInitialLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _isInitialLoad = false;
      });
    }

    final groupedStories = _groupStoriesByUser(stories);
    final hasStories = stories.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
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
              if (hasStories)
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, NamedRoutes.statusScreen);
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'More',
                    style: AppTheme.greyTextStyle.copyWith(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: SizedBox(
            height: 100,
            width: double.infinity,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: hasStories ? groupedStories.length + 1 : 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return BlocBuilder<UserBloc, UserState>(
                    builder: (context, userState) {
                      final userAvatar = userState.currentUser?['avatar'] ?? '';
                      return StatusWidget(
                        name: 'Your Story',
                        avatar: userAvatar,
                        isAddStatus: true,
                        statusCount: 0,
                        hasUnviewed: false,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pushNamed(
                              context, NamedRoutes.createStatusScreen);
                        },
                      );
                    },
                  );
                }

                if (!hasStories) return const SizedBox.shrink();

                final group = groupedStories[index - 1];
                return StatusWidget(
                  name: group.user.name,
                  avatar: group.user.avatar,
                  statusCount: group.stories.length,
                  hasUnviewed: group.hasUnseen,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    for (final story in group.stories) {
                      if (!story.isSeen && mounted) {
                        context
                            .read<StoriesBloc>()
                            .add(MarkStorySeen(storyId: story.id));
                      }
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StatusViewPage(
                          stories: group.stories,
                          initialIndex: 0,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFeedSection(FeedState feedState) {
    final posts = feedState.posts;
    final isLoading = feedState.postsStatus == FeedStatus.loading;
    final isLoadingMore = feedState.postsStatus == FeedStatus.loadingMore;
    final hasMore = feedState.hasMorePosts;
    final error = feedState.postsError;

    if (isLoading && _isInitialLoad && posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (feedState.postsStatus == FeedStatus.error && posts.isEmpty) {
      return _buildErrorWidget(error);
    }

    if (posts.isEmpty && !_isInitialLoad) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      );
    }

    return Column(
      children: [
        for (final post in posts)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: CardPost(post: post),
            ),
          ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : TextButton(
                      onPressed: () {
                        context.read<FeedBloc>().add(LoadMoreFeedPosts());
                      },
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

  Widget _buildErrorWidget(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.greyColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: AppTheme.greyTextStyle,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              _silentRefresh();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 48),
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Try Again'),
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

    groups.sort((a, b) {
      if (a.hasUnseen && !b.hasUnseen) return -1;
      if (!a.hasUnseen && b.hasUnseen) return 1;
      return b.latestStory.compareTo(a.latestStory);
    });

    return groups;
  }

  String _getUserDisplayName() {
    final userState = context.read<UserBloc>().state;
    final user = userState.currentUser;
    if (user != null) {
      final name = user['name'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString().trim();
      }
      final username = user['username'];
      if (username != null && username.toString().trim().isNotEmpty) {
        return username.toString().trim();
      }
    }
    return 'User';
  }

  Widget _buildCustomAppBar() {
    final userState = context.watch<UserBloc>().state;
    final userAvatar = userState.currentUser?['avatar'] ?? '';
    final displayName = _getUserDisplayName();
    final fallbackText =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 60, 20, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User Avatar (Left)
          GestureDetector(
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: _buildAvatar(
                    userAvatar,
                    size: 42,
                    fallbackText: fallbackText,
                  ),
                ),
              ),
            ),
          ),

          // Logo (Center)
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/clique_logo.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),

          // Notification Icon (Right)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, NamedRoutes.notificationScreen);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.notifications_none_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
