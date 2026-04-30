import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';

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

  final List<Map<String, dynamic>> _friends = [
    {
      'name': 'Sarah Johnson',
      'username': '@sarahj',
      'avatar': 'profiles/profile_1.jpeg',
      'isFollowing': true,
      'isOnline': true,
      'mutualFriends': '12 mutual',
    },
    {
      'name': 'Michael Chen',
      'username': '@mikechen',
      'avatar': 'profiles/profile_2.jpeg',
      'isFollowing': true,
      'isOnline': false,
      'mutualFriends': '8 mutual',
    },
    {
      'name': 'Emma Wilson',
      'username': '@emmaw',
      'avatar': 'profiles/profile_3.jpeg',
      'isFollowing': false,
      'isOnline': true,
      'mutualFriends': '3 mutual',
    },
    {
      'name': 'James Rodriguez',
      'username': '@james.r',
      'avatar': 'profiles/profile_4.jpeg',
      'isFollowing': true,
      'isOnline': false,
      'mutualFriends': '15 mutual',
    },
    {
      'name': 'Lisa Kim',
      'username': '@lisak',
      'avatar': 'profiles/profile_1.jpeg',
      'isFollowing': false,
      'isOnline': true,
      'mutualFriends': '5 mutual',
    },
    {
      'name': 'David Brown',
      'username': '@davidb',
      'avatar': 'profiles/profile_2.jpeg',
      'isFollowing': true,
      'isOnline': false,
      'mutualFriends': '7 mutual',
    },
    {
      'name': 'Sophie Anderson',
      'username': '@sophie',
      'avatar': 'profiles/profile_3.jpeg',
      'isFollowing': false,
      'isOnline': true,
      'mutualFriends': '20 mutual',
    },
    {
      'name': 'Alex Thompson',
      'username': '@alex.t',
      'avatar': 'profiles/profile_4.jpeg',
      'isFollowing': true,
      'isOnline': true,
      'mutualFriends': '10 mutual',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.isFollowers ? 0 : 1,
    );
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
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Friends',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.purpleColor,
          indicatorWeight: 3,
          labelColor: Colors.black,
          unselectedLabelColor: AppColors.greyColor,
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                style: AppTheme.blackTextStyle.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search friends...',
                  hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.greyColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          // Friends list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsList(isFollowers: true),
                _buildFriendsList(isFollowers: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList({required bool isFollowers}) {
    final filteredList = isFollowers
        ? _friends // Show all as followers for demo
        : _friends.where((f) => f['isFollowing'] == true).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final friend = filteredList[index];
        return _buildFriendItem(friend);
      },
    );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.purpleColor.withOpacity(0.3),
                    width: 2,
                  ),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(friend['avatar']),
                  ),
                ),
              ),
              if (friend['isOnline'])
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.greenColor,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['name'],
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  friend['username'],
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  friend['mutualFriends'],
                  style: AppTheme.greyTextStyle.copyWith(
                    fontSize: 11,
                    color: AppColors.purpleColor,
                  ),
                ),
              ],
            ),
          ),
          // Action button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                friend['isFollowing'] = !friend['isFollowing'];
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: friend['isFollowing']
                    ? Colors.transparent
                    : AppColors.purpleColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: friend['isFollowing']
                      ? AppColors.greyColor.withOpacity(0.3)
                      : AppColors.purpleColor,
                ),
              ),
              child: Text(
                friend['isFollowing'] ? 'Following' : 'Follow',
                style: TextStyle(
                  color: friend['isFollowing'] ? Colors.black : Colors.white,
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
