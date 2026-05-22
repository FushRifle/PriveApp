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
import 'package:clique/ui/pages/settings/settings_page.dart';

import 'package:clique/ui/widgets/home/card_post.dart';
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

    _scrollController.addListener(
      _onScroll,
    );
  }

  @override
  void dispose() {
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
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 600) {
      final feedBloc = context.read<FeedBloc>();

      final state = feedBloc.state;

      if (state.hasMorePosts && state.postsStatus != FeedStatus.loadingMore) {
        feedBloc.add(
          LoadMoreFeedPosts(),
        );
      }
    }
  }

  Future<void> _refresh() async {
    context.read<FeedBloc>().add(RefreshFeed());

    context.read<StoriesBloc>().add(GetStories());

    context.read<UserBloc>().add(RefreshCurrentUser());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: RefreshIndicator(
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
                buildWhen: (previous, current) =>
                    previous.stories != current.stories ||
                    previous.status != current.status,
                builder: (
                  context,
                  state,
                ) {
                  return _StoriesSection(
                    state: state,
                    groups: _getGroupedStories(
                      state.stories,
                    ),
                  );
                },
              ),
            ),
            BlocBuilder<FeedBloc, FeedState>(
              buildWhen: (previous, current) =>
                  previous.posts != current.posts ||
                  previous.postsStatus != current.postsStatus,
              builder: (
                context,
                state,
              ) {
                final posts = state.posts;

                if (state.postsStatus == FeedStatus.loading && posts.isEmpty) {
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
                    (
                      context,
                      index,
                    ) {
                      if (index >= posts.length) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: state.postsStatus == FeedStatus.loadingMore
                                ? const CircularProgressIndicator(
                                    color: AppColors.primary,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }

                      final post = posts[index];

                      return RepaintBoundary(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          child: CardPost(
                            post: post,
                          ),
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
    );
  }

  List<_StoryGroup> _getGroupedStories(
    List<Story> stories,
  ) {
    if (_lastStories == stories && _cachedGroups.isNotEmpty) {
      return _cachedGroups;
    }

    _lastStories = stories;

    final grouped = <int, List<Story>>{};

    for (final story in stories) {
      grouped.putIfAbsent(
        story.userId,
        () => [],
      );

      grouped[story.userId]!.add(story);
    }

    final groups = grouped.entries.map((entry) {
      final userStories = entry.value;

      userStories.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return _StoryGroup(
        userId: entry.key,
        user: userStories.first.user,
        stories: userStories,
        hasUnseen: userStories.any(
          (e) => !e.isSeen,
        ),
        latestStory: userStories.first.createdAt,
      );
    }).toList();

    groups.sort((a, b) {
      if (a.hasUnseen && !b.hasUnseen) {
        return -1;
      }

      if (!a.hasUnseen && b.hasUnseen) {
        return 1;
      }

      return b.latestStory.compareTo(
        a.latestStory,
      );
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
        final avatar = user?['avatar'] ?? '';

        final name = user?['name'] ?? user?['username'] ?? 'User';

        final fallback =
            name.toString().trim().isNotEmpty ? name[0].toUpperCase() : 'U';

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            15,
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
                      builder: (_) => const SettingsPage(),
                    ),
                  );
                },
                child: _Avatar(
                  avatar: avatar,
                  fallback: fallback,
                ),
              ),
              Image.asset(
                'images/clique.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
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
                        color: Colors.black.withOpacity(
                          0.05,
                        ),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stories',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (stories.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      NamedRoutes.statusScreen,
                    );
                  },
                  child: Text(
                    'More',
                    style: AppTheme.greyTextStyle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            itemCount: groups.length + 1,
            separatorBuilder: (_, __) => const SizedBox(
              width: 8,
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return BlocSelector<UserBloc, UserState, String>(
                  selector: (state) => state.currentUser?['avatar'] ?? '',
                  builder: (context, avatar) {
                    return StatusWidget(
                      name: 'Your Story',
                      avatar: avatar,
                      isAddStatus: true,
                      statusCount: 0,
                      hasUnviewed: false,
                      onTap: () {
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
                    for (final story in group.stories) {
                      if (!story.isSeen) {
                        context.read<StoriesBloc>().add(
                              MarkStorySeen(
                                storyId: story.id,
                              ),
                            );
                      }
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusViewPage(
                          stories: group.stories,
                          initialIndex: 0,
                        ),
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: avatar.isNotEmpty
              ? Image.network(
                  avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return _fallback();
                  },
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Text(
          fallback,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String? error;

  const _ErrorWidget({
    this.error,
  });

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<FeedBloc>().add(
                    RefreshFeed(),
                  );
            },
            child: const Text('Retry'),
          ),
        ],
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
