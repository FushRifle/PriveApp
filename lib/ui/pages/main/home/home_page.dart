import 'package:clique/ui/pages/main/profile/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/app/resources/constant/named_routes.dart';

import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';

import 'package:clique/data/models/status_model.dart';

import 'package:clique/ui/pages/main/status/status_view_page.dart';

import 'package:clique/ui/widgets/post/post_card.dart';
import 'package:clique/ui/widgets/status/status_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  bool _initialized = false;
  bool _isLoadingMore = false;

  List<_StoryGroup> _cachedGroups = [];
  List<Story> _lastStories = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _initialize();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    super.dispose();
  }

  void _initialize() {
    if (_initialized) return;

    _initialized = true;

    context.read<UserBloc>().add(LoadCurrentUser());
    context.read<FeedBloc>().add(GetFeedPosts());
    context.read<StoriesBloc>().add(GetStories());
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 700) {
      final feedBloc = context.read<FeedBloc>();
      final state = feedBloc.state;

      if (state.hasMorePosts && state.postsStatus != FeedStatus.loadingMore) {
        _isLoadingMore = true;

        feedBloc.add(LoadMoreFeedPosts());

        Future<void>.delayed(
          const Duration(milliseconds: 450),
          () {
            _isLoadingMore = false;
          },
        );
      }
    }
  }

  Future<void> _refresh() async {
    context.read<FeedBloc>().add(RefreshFeed());
    context.read<StoriesBloc>().add(GetStories());
    context.read<UserBloc>().add(RefreshCurrentUser());

    await Future<void>.delayed(
      const Duration(milliseconds: 450),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(
                child: _HomeAppBar(),
              ),
              SliverToBoxAdapter(
                child: BlocBuilder<StoriesBloc, StoriesState>(
                  buildWhen: (previous, current) {
                    return previous.stories != current.stories ||
                        previous.status != current.status ||
                        previous.error != current.error;
                  },
                  builder: (context, state) {
                    return _StoriesSection(
                      state: state,
                      groups: _getGroupedStories(state.stories),
                    );
                  },
                ),
              ),
              BlocBuilder<FeedBloc, FeedState>(
                buildWhen: (previous, current) {
                  return previous.posts != current.posts ||
                      previous.postsStatus != current.postsStatus ||
                      previous.postsError != current.postsError ||
                      previous.hasMorePosts != current.hasMorePosts;
                },
                builder: (context, state) {
                  final posts = state.posts;

                  if (state.postsStatus == FeedStatus.loading &&
                      posts.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  if (state.postsStatus == FeedStatus.error && posts.isEmpty) {
                    return SliverFillRemaining(
                      child: _ErrorWidget(
                        error: state.postsError,
                        onRetry: () {
                          context.read<FeedBloc>().add(RefreshFeed());
                        },
                      ),
                    );
                  }

                  if (posts.isEmpty) {
                    return const SliverFillRemaining(
                      child: _EmptyFeed(),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= posts.length) {
                          return _LoadMoreIndicator(
                            isLoading:
                                state.postsStatus == FeedStatus.loadingMore,
                          );
                        }

                        final post = posts[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          child: CardPost(
                            key: ValueKey('post_${post.id}'),
                            post: post,
                          ),
                        );
                      },
                      childCount: posts.length + (state.hasMorePosts ? 1 : 0),
                    ),
                  );
                },
              ),
              const SliverPadding(
                padding: EdgeInsets.only(
                  bottom: 120,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_StoryGroup> _getGroupedStories(List<Story> stories) {
    if (identical(_lastStories, stories) && _cachedGroups.isNotEmpty) {
      return _cachedGroups;
    }

    _lastStories = stories;

    final grouped = <int, List<Story>>{};

    for (final story in stories) {
      grouped.putIfAbsent(story.userId, () => []);
      grouped[story.userId]!.add(story);
    }

    final groups = grouped.entries.map((entry) {
      final userStories = [...entry.value];

      userStories.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      final firstStory = userStories.first;

      return _StoryGroup(
        userId: entry.key,
        user: firstStory.user,
        stories: userStories,
        hasUnseen: userStories.any((story) => !story.isSeen),
        latestStory: firstStory.createdAt,
      );
    }).toList();

    groups.sort((a, b) {
      if (a.hasUnseen && !b.hasUnseen) return -1;
      if (!a.hasUnseen && b.hasUnseen) return 1;

      return b.latestStory.compareTo(a.latestStory);
    });

    _cachedGroups = groups;

    return groups;
  }
}

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserBloc, UserState, Map<String, dynamic>?>(
      selector: (state) => state.currentUser,
      builder: (context, user) {
        final avatar = user?['avatar']?.toString() ?? '';
        final name = user?['name']?.toString() ??
            user?['username']?.toString() ??
            'User';

        final fallback =
            name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 10,
            20,
            12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfilePage(),
                    ),
                  );
                },
                child: _Avatar(
                  avatar: avatar,
                  fallback: fallback,
                ),
              ),
              Image.asset(
                'assets/images/clique.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return Text(
                    'Clique',
                    style: AppTheme.blackTextStyle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();

                  Navigator.pushNamed(
                    context,
                    NamedRoutes.notificationScreen,
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_none_outlined,
                          color: AppColors.primary,
                          size: 25,
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
      },
    );
  }
}

class _StoriesSection extends StatelessWidget {
  final StoriesState state;
  final List<_StoryGroup> groups;

  const _StoriesSection({
    required this.state,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    final stories = state.stories;
    final isLoading = state.status == StoriesStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
          child: Row(
            children: [
              Text(
                'Stories',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (isLoading && stories.isNotEmpty) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ],
              const Spacer(),
              if (stories.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      NamedRoutes.statusScreen,
                    );
                  },
                  style: TextButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    'More',
                    style: AppTheme.greyTextStyle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 102,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: groups.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return BlocSelector<UserBloc, UserState, String>(
                  selector: (state) {
                    return state.currentUser?['avatar']?.toString() ?? '';
                  },
                  builder: (context, avatar) {
                    return StatusWidget(
                      name: 'Your Story',
                      avatar: avatar,
                      isAddStatus: true,
                      statusCount: 0,
                      hasUnviewed: false,
                      onTap: () {
                        HapticFeedback.lightImpact();

                        Navigator.pushNamed(
                          context,
                          NamedRoutes.createStatusScreen,
                        );
                      },
                    );
                  },
                );
              }

              final group = groups[index - 1];

              return RepaintBoundary(
                child: StatusWidget(
                  name: group.user.name,
                  avatar: group.user.avatar,
                  statusCount: group.stories.length,
                  hasUnviewed: group.hasUnseen,
                  onTap: () {
                    HapticFeedback.lightImpact();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) {
                          return StatusViewPage(
                            stories: group.stories,
                            initialIndex: 0,
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String avatar;
  final String fallback;

  const _Avatar({
    required this.avatar,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: avatar.isNotEmpty && avatar.startsWith('http')
            ? Image.network(
                avatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : avatar.isNotEmpty
                ? Image.asset(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(),
                  )
                : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.white.withOpacity(0.2),
      alignment: Alignment.center,
      child: Text(
        fallback,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  final bool isLoading;

  const _LoadMoreIndicator({
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return const SizedBox(height: 20);
    }

    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.post_add_rounded,
              size: 68,
              color: AppColors.greyColor.withOpacity(0.45),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to refresh or create your first post.',
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 68,
              color: AppColors.greyColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(130, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
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

  const _StoryGroup({
    required this.userId,
    required this.user,
    required this.stories,
    required this.hasUnseen,
    required this.latestStory,
  });
}
