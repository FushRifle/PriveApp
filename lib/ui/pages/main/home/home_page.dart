import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/named_routes.dart';

import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';

import 'package:clique/core/models/status_model.dart';
import 'package:clique/core/services/notification/notification_service.dart';

import 'package:clique/ui/pages/main/status/create_status_page.dart';
import 'package:clique/ui/pages/main/home/create_post_page.dart';
import 'package:clique/ui/pages/main/status/status_page.dart';
import 'package:clique/ui/pages/main/status/status_view_page.dart';

import 'package:clique/ui/widgets/post/normal-post/post_card.dart';
import 'package:clique/ui/widgets/status/status_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePalette {
  final bool isDark;
  final Color background;
  final Color card;
  final Color elevatedCard;
  final Color border;
  final Color text;
  final Color mutedText;
  final Color subtleText;
  final Color primary;
  final Color secondary;
  final Color shadow;
  final SystemUiOverlayStyle overlayStyle;

  const _HomePalette({
    required this.isDark,
    required this.background,
    required this.card,
    required this.elevatedCard,
    required this.border,
    required this.text,
    required this.mutedText,
    required this.subtleText,
    required this.primary,
    required this.secondary,
    required this.shadow,
    required this.overlayStyle,
  });

  factory _HomePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return _HomePalette(
      isDark: isDark,
      background: theme.scaffoldBackgroundColor,
      card: scheme.surface,
      elevatedCard: isDark ? const Color(0xFF1E2633) : AppColors.white,
      border: isDark
          ? AppColors.darkCardBorder.withOpacity(0.5)
          : AppColors.lightCardBorder.withOpacity(0.5),
      text: scheme.onSurface,
      mutedText:
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      subtleText: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
      primary: scheme.primary,
      secondary: scheme.secondary,
      shadow: isDark
          ? Colors.black.withOpacity(0.25)
          : Colors.grey.withOpacity(0.08),
      overlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );
  }
}

class _StoryGroup {
  final int userId;
  final dynamic user;
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

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _initialize();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;

    context.read<FeedBloc>().add(SilentRefreshFeed());
    context.read<StoriesBloc>().add(GetStories());
  }

  void _initialize() {
    if (_initialized) return;
    _initialized = true;

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
    final palette = _HomePalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.overlayStyle,
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: palette.primary,
            backgroundColor: palette.card,
            edgeOffset: MediaQuery.paddingOf(context).top + 60,
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeAppBar(palette: palette),
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
                        palette: palette,
                        state: state,
                        groups: _getGroupedStories(state.stories),
                        onCreateStory: () => _openCreateStatus(context),
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
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: palette.primary,
                            strokeWidth: 3,
                          ),
                        ),
                      );
                    }

                    if (posts.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyFeed(palette: palette),
                      );
                    }

                    return SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                        child: _FeedHeader(
                          palette: palette,
                          isRefreshing:
                              state.postsStatus == FeedStatus.loading,
                          onOpenTopics: () {
                            Navigator.pushNamed(
                              context,
                              NamedRoutes.topicsScreen,
                            );
                          },
                          onOpenCreate: () => _openCreatePost(context),
                        ),
                      ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList.separated(
                            itemCount:
                                posts.length + (state.hasMorePosts ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              if (index >= posts.length) {
                                return _LoadMoreIndicator(
                                  palette: palette,
                                  isLoading: state.postsStatus ==
                                      FeedStatus.loadingMore,
                                );
                              }

                              final post = posts[index];

                              return CardPost(
                                key: ValueKey('post_${post.id}'),
                                post: post,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreatePost(BuildContext context) async {
    HapticFeedback.lightImpact();

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<FeedBloc>(),
          child: const CreatePostPage(),
        ),
      ),
    );

    if (created == true && context.mounted) {
      context.read<FeedBloc>().add(RefreshFeed());
    }
  }

  Future<void> _openCreateStatus(BuildContext context) async {
    HapticFeedback.lightImpact();

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<StoriesBloc>(),
          child: const CreateStatusPage(),
        ),
      ),
    );

    if (created != true || !context.mounted) return;

    context.read<StoriesBloc>().add(GetStories());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Story shared successfully'),
        behavior: SnackBarBehavior.floating,
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
  static final NotificationService _notificationService = NotificationService();

  final _HomePalette palette;

  const _HomeAppBar({
    required this.palette,
  });

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

        return Container(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + 16,
            16,
            12,
          ),
          color: palette.background,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, NamedRoutes.settingsScreen);
                },
                child: _Avatar(
                  palette: palette,
                  avatar: avatar,
                  fallback: fallback,
                  size: 44,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clique',
                      style: AppTheme.blackTextStyle.copyWith(
                        color: palette.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Your Vibe, Your Clique.',
                      style: AppTheme.greyTextStyle.copyWith(
                        color: palette.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, NamedRoutes.notificationScreen);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.border),
                    boxShadow: [
                      BoxShadow(
                        color: palette.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: AppColors.white,
                        size: 22,
                      ),
                      FutureBuilder<Map<String, dynamic>>(
                        future: _notificationService.getNotifications(
                          page: 1,
                          pageSize: 1,
                        ),
                        builder: (context, snapshot) {
                          final count = _readInt(
                            snapshot.data?['unreadCount'],
                          );
                          if (count <= 0) return const SizedBox.shrink();

                          return Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: palette.elevatedCard,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  count > 99 ? '99+' : '$count',
                                  style: const TextStyle(
                                    color: AppColors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _StoriesSection extends StatelessWidget {
  final _HomePalette palette;
  final StoriesState state;
  final List<_StoryGroup> groups;
  final VoidCallback onCreateStory;

  const _StoriesSection({
    required this.palette,
    required this.state,
    required this.groups,
    required this.onCreateStory,
  });

  @override
  Widget build(BuildContext context) {
    final stories = state.stories;
    final isLoading = state.status == StoriesStatus.loading;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Text(
                  'Stories',
                  style: AppTheme.blackTextStyle.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (isLoading && stories.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: palette.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ],
                const Spacer(),
                if (stories.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<StoriesBloc>(),
                            child: const StatusPage(stories: []),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'See All',
                      style: AppTheme.greyTextStyle.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: groups.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return BlocSelector<UserBloc, UserState, String>(
                    selector: (state) =>
                        state.currentUser?['avatar']?.toString() ?? '',
                    builder: (context, avatar) {
                      return StatusWidget(
                        name: 'Add Story',
                        avatar: avatar,
                        isAddStatus: true,
                        statusCount: 0,
                        hasUnviewed: false,
                        onTap: onCreateStory,
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
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final _HomePalette palette;
  final String avatar;
  final String fallback;
  final double size;

  const _Avatar({
    required this.palette,
    required this.avatar,
    required this.fallback,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.background,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: avatar.isNotEmpty && avatar.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: avatar,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _fallback(),
                  errorWidget: (_, __, ___) => _fallback(),
                )
              : avatar.isNotEmpty
                  ? Image.asset(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: palette.isDark
          ? AppColors.white.withOpacity(0.08)
          : AppColors.black.withOpacity(0.08),
      alignment: Alignment.center,
      child: Text(
        fallback,
        style: TextStyle(
          color: palette.text,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.35,
        ),
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  final _HomePalette palette;
  final bool isRefreshing;
  final VoidCallback onOpenTopics;
  final VoidCallback onOpenCreate;

  const _FeedHeader({
    required this.palette,
    required this.isRefreshing,
    required this.onOpenTopics,
    required this.onOpenCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 5, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feeds',
                  style: AppTheme.blackTextStyle.copyWith(
                    color: palette.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fresh perspectives from your circle',
                  style: AppTheme.greyTextStyle.copyWith(
                    color: palette.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isRefreshing) ...[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                color: palette.primary,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
          ],
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onOpenTopics();
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: palette.secondary.withOpacity(
                  palette.isDark ? 0.18 : 0.08,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.secondary.withOpacity(0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: palette.secondary,
                    size: 19,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Topics',
                    style: AppTheme.greyTextStyle.copyWith(
                      color: palette.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onOpenCreate();
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color:
                    palette.primary.withOpacity(palette.isDark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.primary.withOpacity(0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: palette.primary,
                    size: 19,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Post',
                    style: AppTheme.greyTextStyle.copyWith(
                      color: palette.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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
}

class _LoadMoreIndicator extends StatelessWidget {
  final _HomePalette palette;
  final bool isLoading;

  const _LoadMoreIndicator({
    required this.palette,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox(height: 24);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: palette.primary,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final _HomePalette palette;

  const _EmptyFeed({
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: palette.card,
                shape: BoxShape.circle,
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                Icons.bubble_chart_outlined,
                size: 40,
                color: palette.subtleText,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quiet in the circle',
              style: AppTheme.blackTextStyle.copyWith(
                color: palette.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to break the ice or refresh the feed to look for updates.',
              style: AppTheme.greyTextStyle.copyWith(
                color: palette.mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
