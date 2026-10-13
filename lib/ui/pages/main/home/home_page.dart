import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import 'package:clique/app/configs/colors.dart';
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
import 'package:clique/ui/pages/main/status/status_view_page.dart';

import 'package:clique/ui/widgets/home/home_feed_shimmer.dart';
import 'package:clique/ui/widgets/home/people_you_may_know_dialog.dart';
import 'package:clique/ui/widgets/home/quick_post_sheet.dart';
import 'package:clique/ui/widgets/post/normal-post/repost_card.dart';
import 'package:clique/ui/widgets/status/status_widget.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';
import 'package:clique/ui/widgets/common/main_tab_header.dart';

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
        // Account drawer disabled. The header avatar opens Profile directly.
        // endDrawer: const _HomeAccountDrawer(),
        // drawerScrimColor: AppColors.black.withOpacity(0.42),
        body: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.background,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const _HomeAppBar(),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.secondary,
                    backgroundColor: palette.card,
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
                                  onCreateStory: () =>
                                      _openCreateStatus(context),
                                );
                              },
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _HomeContentWidth(
                            child: _HomeComposer(
                              palette: palette,
                              onTextPost: () => _openQuickPost(
                                context,
                                QuickPostMode.text,
                              ),
                              onMediaPost: () => _openQuickPost(
                                context,
                                QuickPostMode.media,
                              ),
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
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 2, 10, 0),
                                  sliver: SliverList.separated(
                                    addAutomaticKeepAlives: false,
                                    itemCount:
                                        posts.length + (posts.length ~/ 6),
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
              ],
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

  Future<void> _openQuickPost(
    BuildContext context,
    QuickPostMode mode,
  ) async {
    HapticFeedback.lightImpact();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.black.withOpacity(0.48),
      builder: (_) => QuickPostSheet(
        feedBloc: context.read<FeedBloc>(),
        mode: mode,
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
  final VoidCallback onTextPost;
  final VoidCallback onMediaPost;
  final VoidCallback onTopics;

  const _HomeComposer({
    required this.palette,
    required this.onTextPost,
    required this.onMediaPost,
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
                onTap: onTextPost,
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
            onTap: onMediaPost,
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
    return BlocSelector<UserBloc, UserState, String>(
      selector: (state) {
        final user = state.currentUser;
        final name = user?['name']?.toString() ??
            user?['username']?.toString() ??
            'User';
        return name.trim().split(RegExp(r'\s+')).first;
      },
      builder: (context, firstName) {
        return MainTabHeader(
          title: 'Clique',
          subtitle: '${_greeting()}, $firstName',
          actions: [
            const MainTabProfileAction(),
            FutureBuilder<Map<String, dynamic>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                return MainTabHeaderAction(
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
          ],
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

// ignore: unused_element
class _HomeAccountDrawer extends StatelessWidget {
  const _HomeAccountDrawer();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: SafeArea(
        bottom: false,
        child: Material(
          color: AppColors.background,
          elevation: 18,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          child: SizedBox(
            width: 200,
            child: BlocSelector<UserBloc, UserState, Map<String, dynamic>?>(
              selector: (state) => state.currentUser,
              builder: (context, user) {
                final name = _displayName(user);
                final avatar = user?['avatar']?.toString().trim() ?? '';

                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.border.withOpacity(0.55),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 32,
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: avatar.startsWith('http')
                                    ? AppNetworkImage(
                                        imageUrl: avatar,
                                        fit: BoxFit.cover,
                                        preset: AppNetworkImagePreset.avatar,
                                        errorBuilder: (_) =>
                                            _DrawerAvatarFallback(name),
                                        placeholder: (_) =>
                                            _DrawerAvatarFallback(name),
                                      )
                                    : _DrawerAvatarFallback(name),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AccountDrawerItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        onTap: () =>
                            _openRoute(context, NamedRoutes.profileScreen),
                      ),
                      _AccountDrawerItem(
                        icon: Icons.tune_rounded,
                        label: 'Settings',
                        onTap: () =>
                            _openRoute(context, NamedRoutes.settingsScreen),
                      ),
                      _AccountDrawerItem(
                        icon: Icons.group_add_outlined,
                        label: 'Invite',
                        onTap: () => _refer(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Divider(
                          height: 1,
                          color: AppColors.border.withOpacity(0.55),
                        ),
                      ),
                      _AccountDrawerItem(
                        icon: Icons.logout_rounded,
                        label: 'Log out',
                        destructive: true,
                        showChevron: false,
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static String _displayName(Map<String, dynamic>? user) {
    final name = user?['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
    final username = user?['username']?.toString().trim() ?? '';
    return username.isEmpty ? 'Clique member' : username;
  }

  void _openRoute(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  Future<void> _refer(BuildContext context) async {
    Navigator.pop(context);
    await Share.share(
      'Join me on Clique — a better place to share, connect, and find your people.',
      subject: 'Join me on Clique',
    );
  }

  void _logout(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    authBloc.add(const SignOutRequested());
  }
}

class _AccountDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool showChevron;

  const _AccountDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.error : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: destructive ? AppColors.error : AppColors.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerAvatarFallback extends StatelessWidget {
  final String name;

  const _DrawerAvatarFallback(this.name);

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'C' : name.trim()[0].toUpperCase();
    return ColoredBox(
      color: AppColors.card,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
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
