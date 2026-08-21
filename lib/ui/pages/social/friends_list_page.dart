import 'package:clique/core/services/friends/friends_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/friends/friends_bloc.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';

class FriendsListPage extends StatefulWidget {
  final bool isFollowers;

  const FriendsListPage({
    super.key,
    this.isFollowers = true,
  });

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.isFollowers ? 0 : 1,
    );
    _loadData();
  }

  void _loadData() {
    context.read<FriendsBloc>().add(LoadFollowers());
    context.read<FriendsBloc>().add(LoadFollowing());
    context.read<FriendsBloc>().add(LoadFollowStats());
  }

  Future<void> _refreshFollowers() async {
    final bloc = context.read<FriendsBloc>()..add(LoadFollowers());
    await bloc.stream.firstWhere(
      (state) =>
          state.followersStatus == FollowersStatus.success ||
          state.followersStatus == FollowersStatus.error,
    );
  }

  Future<void> _refreshFollowing() async {
    final bloc = context.read<FriendsBloc>()..add(LoadFollowing());
    await bloc.stream.firstWhere(
      (state) =>
          state.followingStatus == FollowingStatus.success ||
          state.followingStatus == FollowingStatus.error,
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(count >= 10000000 ? 0 : 1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count >= 10000 ? 0 : 1)}K';
    }
    return '$count';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: BlocListener<FriendsBloc, FriendsState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.card,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<FriendsBloc>().add(ClearFriendsError());
          }
        },
        child: Column(
          children: [
            AppPageHeader(
              title: 'Connections',
              subtitle: 'The people in your circle',
              leadingIcon: Icons.arrow_back_ios_new_rounded,
              onLeadingTap: () => Navigator.pop(context),
              actionIcon: Icons.person_add_alt_1_rounded,
              onActionTap: () => Navigator.pushNamed(
                context,
                NamedRoutes.peopleYouMayKnowScreen,
              ),
            ),
            _buildConnectionControls(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFollowersList(),
                  _buildFollowingList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionControls() {
    return BlocBuilder<FriendsBloc, FriendsState>(
      buildWhen: (previous, current) =>
          previous.followersTotal != current.followersTotal ||
          previous.followingTotal != current.followingTotal ||
          previous.stats != current.stats,
      builder: (context, state) {
        final followers = state.stats?.followersCount ?? state.followersTotal;
        final following = state.stats?.followingCount ?? state.followingTotal;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: AppColors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: AppColors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: 'Followers  ${_formatCount(followers)}'),
                    Tab(text: 'Following  ${_formatCount(following)}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                style: AppTheme.blackTextStyle.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name or username',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: AppColors.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFollowersList() {
    return BlocBuilder<FriendsBloc, FriendsState>(
      builder: (context, state) {
        if (state.followersStatus == FollowersStatus.loading &&
            state.followers.isEmpty) {
          return const _ConnectionsLoadingList();
        }

        final followers = _filterUsers(state.followers);

        if (followers.isEmpty &&
            state.followersStatus != FollowersStatus.loading) {
          return _ConnectionEmptyState(
            searching: _searchController.text.trim().isNotEmpty,
            query: _searchController.text.trim(),
            followers: true,
            onClear: () {
              _searchController.clear();
              setState(() {});
            },
            onDiscover: () => Navigator.pushNamed(
              context,
              NamedRoutes.peopleYouMayKnowScreen,
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200 &&
                state.followersHasMore &&
                state.followersStatus != FollowersStatus.loadingMore) {
              context.read<FriendsBloc>().add(LoadMoreFollowers());
            }
            return false;
          },
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshFollowers,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 32),
              itemCount: followers.length +
                  (state.followersStatus == FollowersStatus.loadingMore
                      ? 1
                      : 0),
              itemBuilder: (context, index) {
                if (index == followers.length) {
                  return const _InlineLoader();
                }
                return _buildFriendItem(followers[index]);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowingList() {
    return BlocBuilder<FriendsBloc, FriendsState>(
      builder: (context, state) {
        if (state.followingStatus == FollowingStatus.loading &&
            state.following.isEmpty) {
          return const _ConnectionsLoadingList();
        }

        final following = _filterUsers(state.following);

        if (following.isEmpty &&
            state.followingStatus != FollowingStatus.loading) {
          return _ConnectionEmptyState(
            searching: _searchController.text.trim().isNotEmpty,
            query: _searchController.text.trim(),
            followers: false,
            onClear: () {
              _searchController.clear();
              setState(() {});
            },
            onDiscover: () => Navigator.pushNamed(
              context,
              NamedRoutes.peopleYouMayKnowScreen,
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200 &&
                state.followingHasMore &&
                state.followingStatus != FollowingStatus.loadingMore) {
              context.read<FriendsBloc>().add(LoadMoreFollowing());
            }
            return false;
          },
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshFollowing,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 32),
              itemCount: following.length +
                  (state.followingStatus == FollowingStatus.loadingMore
                      ? 1
                      : 0),
              itemBuilder: (context, index) {
                if (index == following.length) {
                  return const _InlineLoader();
                }
                return _buildFriendItem(following[index]);
              },
            ),
          ),
        );
      },
    );
  }

  List<FriendUser> _filterUsers(List<FriendUser> users) {
    if (_searchController.text.isEmpty) {
      return users;
    }
    return users.where((user) {
      return user.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          user.username
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
    }).toList();
  }

  Widget _buildFriendItem(FriendUser friend) {
    final isFollowing = friend.isFollowing;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pushNamed(
              context,
              NamedRoutes.otherProfileScreen,
              arguments: friend.id,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: friend.avatar != null && friend.avatar!.isNotEmpty
                        ? AppNetworkImage(
                            imageUrl: friend.avatar!,
                            fit: BoxFit.cover,
                            preset: AppNetworkImagePreset.avatar,
                            placeholder: (_) => Container(
                              color: AppColors.grey.shade200,
                              child: const Icon(Icons.person,
                                  color: AppColors.grey),
                            ),
                            errorBuilder: (_) => Container(
                              color: AppColors.grey.shade200,
                              child: const Icon(Icons.person,
                                  color: AppColors.grey),
                            ),
                          )
                        : Container(
                            color: AppColors.grey.shade200,
                            child: Center(
                              child: Text(
                                friend.name.isNotEmpty
                                    ? friend.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              friend.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.blackTextStyle.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (friend.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified,
                                size: 14, color: AppColors.primary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@${friend.username}',
                        style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                      ),
                      if (friend.bio != null && friend.bio!.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          friend.bio!,
                          style: AppTheme.greyTextStyle.copyWith(
                            fontSize: 12,
                            height: 1.3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 42,
                  child: isFollowing
                      ? OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.read<FriendsBloc>().add(
                                  UnfollowUser(userId: friend.id),
                                );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text,
                            minimumSize: const Size(94, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: const Text('Following'),
                        )
                      : FilledButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.read<FriendsBloc>().add(
                                  FollowUser(userId: friend.id),
                                );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(84, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: const Text('Follow'),
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

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}

class _ConnectionsLoadingList extends StatelessWidget {
  const _ConnectionsLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 32),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => Container(
        height: 86,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const _ConnectionSkeleton(width: 56, height: 56, radius: 999),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ConnectionSkeleton(width: 140, height: 13),
                  SizedBox(height: 9),
                  _ConnectionSkeleton(width: 96, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const _ConnectionSkeleton(width: 88, height: 42, radius: 13),
          ],
        ),
      ),
    );
  }
}

class _ConnectionSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ConnectionSkeleton({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.55),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ConnectionEmptyState extends StatelessWidget {
  final bool searching;
  final String query;
  final bool followers;
  final VoidCallback onClear;
  final VoidCallback onDiscover;

  const _ConnectionEmptyState({
    required this.searching,
    required this.query,
    required this.followers,
    required this.onClear,
    required this.onDiscover,
  });

  @override
  Widget build(BuildContext context) {
    final title = searching
        ? 'No matches for “$query”'
        : followers
            ? 'Your community starts here'
            : 'Find people worth following';
    final subtitle = searching
        ? 'Try another name or username.'
        : followers
            ? 'When people follow you, they’ll appear here.'
            : 'Discover creators and friends to shape your feed.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                searching ? Icons.manage_search_rounded : Icons.people_rounded,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: searching ? onClear : onDiscover,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                minimumSize: const Size(180, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: Icon(
                searching ? Icons.close_rounded : Icons.person_search_rounded,
              ),
              label: Text(searching ? 'Clear search' : 'Discover people'),
            ),
          ],
        ),
      ),
    );
  }
}
