import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/friends/friends_service.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'package:clique/core/services/user/first_home_experience.dart';

import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';

import 'package:clique/core/models/status_model.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/notification/notification_service.dart';

import 'package:clique/ui/pages/main/status/create_status_page.dart';
import 'package:clique/ui/pages/main/home/create_post_page.dart';
import 'package:clique/ui/pages/main/status/status_view_page.dart';

import 'package:clique/ui/widgets/home/home_feed_shimmer.dart';
import 'package:clique/ui/widgets/home/people_you_may_know_dialog.dart';
import 'package:clique/ui/widgets/post/normal-post/repost_card.dart';
import 'package:clique/ui/widgets/status/status_widget.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';

class HomePageController {
  Future<void> Function()? _scrollToTop;

  Future<void> scrollToTop() async => _scrollToTop?.call();

  void _attach(Future<void> Function() callback) => _scrollToTop = callback;

  void _detach() => _scrollToTop = null;
}

class HomePage extends StatefulWidget {
  final HomePageController? controller;

  const HomePage({
    super.key,
    this.controller,
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
      background: isDark ? const Color(0xFF0B1118) : const Color(0xFFF3F6F9),
      card: isDark ? const Color(0xFF121B25) : const Color(0xFFFCFDFE),
      elevatedCard: isDark ? const Color(0xFF17222E) : const Color(0xFFFFFFFF),
      border: isDark
          ? const Color(0xFF2A3746).withOpacity(0.62)
          : const Color(0xFFD9E1E8).withOpacity(0.72),
      text: scheme.onSurface,
      mutedText:
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      subtleText: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
      primary: scheme.primary,
      secondary: scheme.secondary,
      shadow: isDark
          ? Colors.black.withOpacity(0.24)
          : const Color(0xFF243B53).withOpacity(0.07),
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
  bool _checkingFirstHomeExperience = false;

  List<_StoryGroup> _cachedGroups = [];
  List<Story> _lastStories = [];
  late final Future<List<_SuggestedUser>> _suggestionsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _suggestionsFuture = _loadSuggestions();
    _initialize();
    _scrollController.addListener(_onScroll);
    widget.controller?._attach(_scrollToTop);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFirstHomeExperience();
    });
  }

  Future<void> _showFirstHomeExperience() async {
    if (_checkingFirstHomeExperience || !mounted) return;
    _checkingFirstHomeExperience = true;
    try {
      final authUserId =
          context.read<AuthBloc>().state.user?['id']?.toString() ?? '';
      final tracker = const FirstHomeExperience();
      final pending = await tracker.pendingDisplayCount(authUserId);
      if (pending == null || !mounted) return;
      for (var index = 0; index < pending && mounted; index++) {
        if (!mounted) return;
        await PeopleYouMayKnowDialog.show(context);
        await tracker.recordDisplay(authUserId);
      }
    } finally {
      _checkingFirstHomeExperience = false;
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller?._detach();
    widget.controller?._attach(_scrollToTop);
  }

  @override
  void dispose() {
    widget.controller?._detach();
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

  Future<void> _scrollToTop() async {
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
        body: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.background,
          ),
          child: SafeArea(
            top: false,
            child: RefreshIndicator(
              color: AppColors.secondary,
              backgroundColor: palette.card,
              edgeOffset: MediaQuery.paddingOf(context).top + 60,
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                cacheExtent: 900,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _HomeContentWidth(
                      child: const _HomeAppBar(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _HomeContentWidth(
                      child: BlocBuilder<StoriesBloc, StoriesState>(
                        buildWhen: (previous, current) {
                          return previous.stories != current.stories ||
                              previous.status != current.status ||
                              previous.error != current.error;
                        },
                        builder: (context, state) {
                          return _StoriesSection(
                            palette: palette,
                            groups: _getGroupedStories(state.stories),
                            onCreateStory: () => _openCreateStatus(context),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _HomeContentWidth(
                      child: _HomeComposer(
                        palette: palette,
                        onCreatePost: () => _openCreatePost(context),
                        onTopics: () => Navigator.pushNamed(
                          context,
                          NamedRoutes.topicsScreen,
                        ),
                      ),
                    ),
                  ),
                  BlocBuilder<FeedBloc, FeedState>(
                    buildWhen: (previous, current) {
                      if (!_hasSamePostStructure(
                        previous.posts,
                        current.posts,
                      )) {
                        return true;
                      }
                      return current.posts.isEmpty &&
                          (previous.postsStatus != current.postsStatus ||
                              previous.postsError != current.postsError);
                    },
                    builder: (context, state) {
                      final posts = state.posts;

                      if (state.postsStatus == FeedStatus.loading &&
                          posts.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: _HomeContentWidth(
                            child: HomeFeedLoadingShimmer(),
                          ),
                        );
                      }

                      if (posts.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: SizedBox.shrink(),
                        );
                      }

                      return SliverMainAxisGroup(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                            sliver: SliverList.separated(
                              addAutomaticKeepAlives: false,
                              itemCount: posts.length + (posts.length ~/ 6),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if ((index + 1) % 7 == 0) {
                                  return _HomeContentWidth(
                                    child: _PeopleYouMayKnowCard(
                                      palette: palette,
                                      suggestions: _suggestionsFuture,
                                    ),
                                  );
                                }

                                final postIndex = index - (index ~/ 7);
                                final post = posts[postIndex];

                                return _HomeContentWidth(
                                  child: _FeedPostSlot(
                                    key: ValueKey('post_${post.id}'),
                                    postId: post.id,
                                    fallback: post,
                                  ),
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
      ),
    );
  }

  Future<List<_SuggestedUser>> _loadSuggestions() async {
    final currentUserId = _readInt(
      context.read<AuthBloc>().state.user?['id'],
    );
    final raw = await UserService().getUserSuggestions(limit: 12);

    return raw
        .map(_SuggestedUser.fromJson)
        .where((user) => user.id > 0)
        .where((user) => user.id != currentUserId)
        .where((user) => !user.isFollowing)
        .take(10)
        .toList();
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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

bool _hasSamePostStructure(List<FeedPost> previous, List<FeedPost> current) {
  if (identical(previous, current)) return true;
  if (previous.length != current.length) return false;
  for (var index = 0; index < previous.length; index++) {
    if (previous[index].id != current[index].id) return false;
  }
  return true;
}

class _FeedPostSlot extends StatelessWidget {
  final int postId;
  final FeedPost fallback;

  const _FeedPostSlot({
    super.key,
    required this.postId,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<FeedBloc, FeedState, FeedPost?>(
      selector: (state) {
        for (final post in state.posts) {
          if (post.id == postId) return post;
        }
        return null;
      },
      builder: (context, post) => RepostCard(post: post ?? fallback),
    );
  }
}

class _PeopleYouMayKnowCard extends StatefulWidget {
  final _HomePalette palette;
  final Future<List<_SuggestedUser>> suggestions;

  const _PeopleYouMayKnowCard({
    required this.palette,
    required this.suggestions,
  });

  @override
  State<_PeopleYouMayKnowCard> createState() => _PeopleYouMayKnowCardState();
}

class _PeopleYouMayKnowCardState extends State<_PeopleYouMayKnowCard> {
  final FriendsService _friendsService = FriendsService();
  final Set<int> _following = {};

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
      future: widget.suggestions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _SuggestionLoadingCard(palette: widget.palette);
        }
        final suggestions = snapshot.data ?? const <_SuggestedUser>[];
        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
          decoration: BoxDecoration(
            color: widget.palette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.palette.border.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: widget.palette.shadow,
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grow your circle',
                          style: TextStyle(
                            color: widget.palette.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'People you may vibe with',
                          style: TextStyle(
                            color: widget.palette.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
              const SizedBox(height: 8),
              SizedBox(
                height: 158,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
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
}

class _SuggestionLoadingCard extends StatelessWidget {
  final _HomePalette palette;

  const _SuggestionLoadingCard({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 142,
            height: 16,
            decoration: BoxDecoration(
              color: palette.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                for (var index = 0; index < 3; index++) ...[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.elevatedCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: palette.border),
                      ),
                    ),
                  ),
                  if (index != 2) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
      width: 128,
      child: Material(
        color: palette.elevatedCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onOpenProfile,
          borderRadius: BorderRadius.circular(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _SuggestionAvatar(user: user),
                  const SizedBox(height: 7),
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    user.username.isEmpty
                        ? 'View profile'
                        : '@${user.username}',
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
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
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
        width: 48,
        height: 48,
        child: user.avatar.isNotEmpty && user.avatar.startsWith('http')
            ? AppNetworkImage(
                imageUrl: user.avatar,
                fit: BoxFit.cover,
                preset: AppNetworkImagePreset.avatar,
                errorBuilder: (_) => _fallback(fallback),
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

class _HomeContentWidth extends StatelessWidget {
  final Widget child;

  const _HomeContentWidth({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: child,
      ),
    );
  }
}

class _HomeComposer extends StatelessWidget {
  final _HomePalette palette;
  final VoidCallback onCreatePost;
  final VoidCallback onTopics;

  const _HomeComposer({
    required this.palette,
    required this.onCreatePost,
    required this.onTopics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.elevatedCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: palette.background,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onCreatePost,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Start a post…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.mutedText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          _ComposerAction(
            icon: Icons.add_photo_alternate_outlined,
            label: 'Add media',
            color: palette.primary,
            onTap: onCreatePost,
          ),
          _ComposerAction(
            icon: Icons.tag_rounded,
            label: 'Topics',
            color: palette.secondary,
            onTap: onTopics,
          ),
        ],
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ComposerAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 40,
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

class _HomeAppBar extends StatefulWidget {
  static final NotificationService _notificationService = NotificationService();

  const _HomeAppBar();

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

        final firstName = name.trim().split(RegExp(r'\s+')).first;
        return Container(
          padding: EdgeInsets.fromLTRB(12, topInset + 10, 12, 12),
          child: Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/icons/clique-new.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: AppColors.primary,
                    child: const Icon(
                      Icons.hub_rounded,
                      color: AppColors.white,
                      size: 19,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Clique',
                      maxLines: 1,
                      style: AppTheme.blackTextStyle.copyWith(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${_greeting()}, $firstName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              FutureBuilder<Map<String, dynamic>>(
                future: _notificationsFuture,
                builder: (context, snapshot) {
                  return _HeaderAction(
                    icon: Icons.notifications_active_outlined,
                    tooltip: 'Notifications',
                    badgeCount: _readInt(snapshot.data?['unreadCount']),
                    onTap: () => Navigator.pushNamed(
                      context,
                      NamedRoutes.notificationScreen,
                    ),
                  );
                },
              ),
              const SizedBox(width: 5),
              Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, NamedRoutes.profileScreen);
                  },
                  customBorder: const CircleBorder(),
                  child: _Avatar(
                    avatar: avatar,
                    fallback: fallback,
                    size: 38,
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: AppColors.white,
                  size: 20,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondary),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
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

class _StoriesSection extends StatelessWidget {
  final _HomePalette palette;
  final List<_StoryGroup> groups;
  final VoidCallback onCreateStory;

  const _StoriesSection({
    required this.palette,
    required this.groups,
    required this.onCreateStory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withOpacity(0.46)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 74,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: groups.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
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
                    compact: true,
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
                compact: true,
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
    );
  }
}

class _Avatar extends StatelessWidget {
  final String avatar;
  final String fallback;
  final double size;

  const _Avatar({
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
          color: AppColors.background,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: avatar.isNotEmpty && avatar.startsWith('http')
              ? AppNetworkImage(
                  imageUrl: avatar,
                  fit: BoxFit.cover,
                  preset: AppNetworkImagePreset.avatar,
                  placeholder: (_) => _fallback(),
                  errorBuilder: (_) => _fallback(),
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
      color: AppColors.isDarkMode
          ? AppColors.white.withOpacity(0.08)
          : AppColors.black.withOpacity(0.08),
      alignment: Alignment.center,
      child: Text(
        fallback,
        style: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.35,
        ),
      ),
    );
  }
}
