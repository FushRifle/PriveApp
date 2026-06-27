import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/friends/friends_service.dart';
import 'package:clique/core/services/user/user_service.dart';

import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';

import 'package:clique/core/models/status_model.dart';
import 'package:clique/core/services/notification/notification_service.dart';

import 'package:clique/ui/pages/main/status/create_status_page.dart';
import 'package:clique/ui/pages/main/home/create_post_page.dart';
import 'package:clique/ui/pages/main/status/status_page.dart';
import 'package:clique/ui/pages/main/status/status_view_page.dart';

import 'package:clique/ui/widgets/home/home_feed_shimmer.dart';
import 'package:clique/ui/widgets/post/normal-post/repost_card.dart';
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
  bool _showJumpToTop = false;

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
    final shouldShowJump = position.pixels > 1400;
    if (shouldShowJump != _showJumpToTop && mounted) {
      setState(() {
        _showJumpToTop = shouldShowJump;
      });
    }

    if (position.extentAfter <= 1800) {
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

  Future<void> _jumpToTop() async {
    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
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
        floatingActionButton: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          offset: _showJumpToTop ? Offset.zero : const Offset(0, 0.2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _showJumpToTop ? 1 : 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _jumpToTop,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.keyboard_double_arrow_up_rounded,
                    size: 27,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: AppColors.secondary,
            backgroundColor: palette.card,
            edgeOffset: MediaQuery.paddingOf(context).top + 60,
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scrollController,
              cacheExtent: 1000,
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
                    final posts = _buildBalancedFeed(state.posts);

                    if (state.postsStatus == FeedStatus.loading &&
                        posts.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: HomeFeedLoadingShimmer(),
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
                                state.postsStatus == FeedStatus.loading &&
                                    posts.isEmpty,
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
                            itemCount: posts.length + (posts.length ~/ 6),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              if ((index + 1) % 7 == 0) {
                                return _PeopleYouMayKnowCard(
                                  palette: palette,
                                );
                              }

                              final postIndex = index - (index ~/ 7);
                              final post = posts[postIndex];

                              return RepostCard(
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

  List<FeedPost> _buildBalancedFeed(List<FeedPost> posts) {
    if (posts.isEmpty) return posts;
    return List<FeedPost>.from(posts);
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

class _PeopleYouMayKnowCard extends StatefulWidget {
  final _HomePalette palette;

  const _PeopleYouMayKnowCard({
    required this.palette,
  });

  @override
  State<_PeopleYouMayKnowCard> createState() => _PeopleYouMayKnowCardState();
}

class _PeopleYouMayKnowCardState extends State<_PeopleYouMayKnowCard> {
  final UserService _userService = UserService();
  final FriendsService _friendsService = FriendsService();
  late Future<List<_SuggestedUser>> _future;
  final Set<int> _following = {};

  @override
  void initState() {
    super.initState();
    _future = _loadSuggestions();
  }

  Future<List<_SuggestedUser>> _loadSuggestions() async {
    final currentUser = context.read<UserBloc>().state.currentUser;
    final currentUserId = _readInt(currentUser?['id']);
    final raw = await _userService.getUserSuggestions(limit: 12);

    final suggestions = raw
        .map(_SuggestedUser.fromJson)
        .where((user) => user.id > 0)
        .where((user) => user.id != currentUserId)
        .where((user) => !user.isFollowing)
        .take(10)
        .toList();

    return suggestions;
  }

  Future<void> _follow(_SuggestedUser user) async {
    if (_following.contains(user.id)) return;
    setState(() => _following.add(user.id));

    try {
      await _friendsService.followUser(user.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _following.remove(user.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openProfile(int userId) {
    Navigator.pushNamed(
      context,
      NamedRoutes.otherProfileScreen,
      arguments: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_SuggestedUser>>(
      future: _future,
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? const <_SuggestedUser>[];
        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: widget.palette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.palette.border),
            boxShadow: [
              BoxShadow(
                color: widget.palette.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'People you may know',
                      style: TextStyle(
                        color: widget.palette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'See more people',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(
                        context,
                        NamedRoutes.peopleYouMayKnowScreen,
                      );
                    },
                    icon: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: widget.palette.primary,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 178,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final user = suggestions[index];
                    final followed = _following.contains(user.id);
                    return _SuggestionTile(
                      palette: widget.palette,
                      user: user,
                      followed: followed,
                      onFollow: () => _follow(user),
                      onOpenProfile: () => _openProfile(user.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _SuggestionTile extends StatelessWidget {
  final _HomePalette palette;
  final _SuggestedUser user;
  final bool followed;
  final VoidCallback onFollow;
  final VoidCallback onOpenProfile;

  const _SuggestionTile({
    required this.palette,
    required this.user,
    required this.followed,
    required this.onFollow,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      child: Material(
        color: palette.elevatedCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onOpenProfile,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _SuggestionAvatar(user: user),
                const SizedBox(height: 10),
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  user.username.isEmpty ? 'View profile' : '@${user.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (user.mutualConnections > 0)
                  Text(
                    '${user.mutualConnections} mutual',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.subtleText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: followed ? null : onFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: palette.border,
                      disabledForegroundColor: palette.mutedText,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      followed ? 'Following' : 'Follow',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionAvatar extends StatelessWidget {
  final _SuggestedUser user;

  const _SuggestionAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final fallback =
        user.name.trim().isNotEmpty ? user.name.trim()[0].toUpperCase() : 'U';

    return ClipOval(
      child: SizedBox(
        width: 54,
        height: 54,
        child: user.avatar.isNotEmpty && user.avatar.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: user.avatar,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _fallback(fallback),
              )
            : _fallback(fallback),
      ),
    );
  }

  Widget _fallback(String fallback) {
    return ColoredBox(
      color: AppColors.primary.withOpacity(0.14),
      child: Center(
        child: Text(
          fallback,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SuggestedUser {
  final int id;
  final String name;
  final String username;
  final String avatar;
  final bool isFollowing;
  final int mutualConnections;

  const _SuggestedUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
    required this.isFollowing,
    required this.mutualConnections,
  });

  factory _SuggestedUser.fromJson(Map<String, dynamic> json) {
    return _SuggestedUser(
      id: _readInt(json['id'] ?? json['userId'] ?? json['user_id']),
      name: (json['name'] ?? json['displayName'] ?? json['username'] ?? 'User')
          .toString(),
      username: (json['username'] ?? json['handle'] ?? '').toString(),
      avatar: (json['avatar'] ?? json['avatarUrl'] ?? '').toString(),
      isFollowing: json['isFollowing'] == true ||
          json['following'] == true ||
          json['is_following'] == true,
      mutualConnections: _readInt(
        json['mutualConnections'] ??
            json['mutual_connections'] ??
            json['mutualCount'],
      ),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _HomeAppBar extends StatefulWidget {
  static final NotificationService _notificationService = NotificationService();

  final _HomePalette palette;

  const _HomeAppBar({
    required this.palette,
  });

  @override
  State<_HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<_HomeAppBar> {
  late Future<Map<String, dynamic>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<Map<String, dynamic>> _loadNotifications() {
    return _HomeAppBar._notificationService.getNotifications(
      page: 1,
      pageSize: 1,
    );
  }

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
        final topInset = MediaQuery.paddingOf(context).top;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 390;
            final avatarSize = isCompact ? 40.0 : 44.0;
            final titleFontSize = isCompact ? 21.0 : 24.0;

            return Container(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 14 : 16,
                topInset + (isCompact ? 12 : 16),
                isCompact ? 14 : 16,
                12,
              ),
              color: widget.palette.background,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, NamedRoutes.profileScreen);
                    },
                    child: _Avatar(
                      palette: widget.palette,
                      avatar: avatar,
                      fallback: fallback,
                      size: avatarSize,
                    ),
                  ),
                  SizedBox(width: isCompact ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Clique',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.blackTextStyle.copyWith(
                            color: AppColors.secondary,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (!isCompact)
                          Text(
                            'Your Vibe, Your Clique.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.greyTextStyle.copyWith(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
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
                      width: isCompact ? 40 : 44,
                      height: isCompact ? 40 : 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.palette.border),
                        boxShadow: [
                          BoxShadow(
                            color: widget.palette.shadow,
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
                            size: isCompact ? 22 : 24,
                          ),
                          FutureBuilder<Map<String, dynamic>>(
                            future: _notificationsFuture,
                            builder: (context, snapshot) {
                              final count = _readInt(
                                snapshot.data?['unreadCount'],
                              );
                              if (count <= 0) {
                                return const SizedBox.shrink();
                              }

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
                                      color: widget.palette.elevatedCard,
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
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 14),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
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
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
                          builder: (_) => BlocProvider.value(
                            value: context.read<StoriesBloc>(),
                            child: StatusViewPage(
                              stories: group.stories,
                              initialIndex: 0,
                            ),
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
      padding: const EdgeInsets.fromLTRB(20, 10, 18, 24),
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
                  'Perspectives from your Circle.',
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
        ],
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
