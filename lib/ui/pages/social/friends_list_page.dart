import 'package:clique/core/services/friends/friends_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/friends/friends_bloc.dart';
import 'package:clique/core/router/named_routes.dart';

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
      appBar: AppBar(
        backgroundColor: AppColors.cardColor,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Connections',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.person_add_outlined, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Find friends feature coming soon'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.text,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'FOLLOWERS'),
            Tab(text: 'FOLLOWING'),
          ],
        ),
      ),
      body: BlocListener<FriendsBloc, FriendsState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.card,
              ),
            );
            context.read<FriendsBloc>().add(ClearFriendsError());
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTheme.blackTextStyle.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search friends...',
                    hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColors.greyColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),
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

  Widget _buildFollowersList() {
    return BlocBuilder<FriendsBloc, FriendsState>(
      builder: (context, state) {
        if (state.followersStatus == FollowersStatus.loading &&
            state.followers.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final followers = _filterUsers(state.followers);

        if (followers.isEmpty &&
            state.followersStatus != FollowersStatus.loading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColors.greyColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No followers yet',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
                ),
              ],
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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: followers.length + (state.followersHasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == followers.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              return _buildFriendItem(followers[index]);
            },
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
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final following = _filterUsers(state.following);

        if (following.isEmpty &&
            state.followingStatus != FollowingStatus.loading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_outlined,
                  size: 64,
                  color: AppColors.greyColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Not following anyone yet',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
                ),
              ],
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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: following.length + (state.followingHasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == following.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              return _buildFriendItem(following[index]);
            },
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(
                  context,
                  NamedRoutes.otherProfileScreen,
                  arguments: friend.id,
                );
              },
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: friend.avatar != null && friend.avatar!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: friend.avatar!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.grey.shade200,
                                child: const Icon(Icons.person,
                                    color: AppColors.grey),
                              ),
                              errorWidget: (context, url, error) => Container(
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
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              friend.name,
                              style: AppTheme.blackTextStyle.copyWith(
                                fontWeight: AppTheme.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (friend.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.verified,
                                  size: 14, color: AppColors.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${friend.username}',
                          style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                        ),
                        if (friend.bio != null && friend.bio!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            friend.bio!,
                            style: AppTheme.greyTextStyle.copyWith(
                              fontSize: 11,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Action button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (isFollowing) {
                context
                    .read<FriendsBloc>()
                    .add(UnfollowUser(userId: friend.id));
              } else {
                context.read<FriendsBloc>().add(FollowUser(userId: friend.id));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isFollowing ? AppColors.transparent : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFollowing ? AppColors.border : AppColors.primary,
                ),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  color: isFollowing ? AppColors.text : AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
