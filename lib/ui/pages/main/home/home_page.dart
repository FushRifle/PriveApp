import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';
import 'package:Prive/data/models/status_model.dart';
import 'package:Prive/data/providers/feed_provider.dart';
import 'package:Prive/ui/pages/main/status/status_view_page.dart';
import 'package:Prive/ui/pages/settings/settings_page.dart';
import 'package:Prive/ui/widgets/home/card_post.dart';
import 'package:Prive/ui/widgets/status/status_widget.dart';
import '../../../widgets/home/custom_app_bar.dart';
import 'package:Prive/data/services/user/user_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final UserService _userService = UserService();
  Map<String, dynamic> _currentUser = {};
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).fetchData();
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print('Error loading user: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    await _loadCurrentUser();
    await ref.read(feedProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final feedState = ref.watch(feedProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
            child: _buildCustomAppBar(context),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.purpleColor,
              onRefresh: _refreshAll,
              child: _buildBody(feedState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CachedFeedData feedState) {
    if (feedState.isLoading && feedState.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.purpleColor),
      );
    }

    if (feedState.error != null && feedState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              feedState.error!,
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(feedProvider.notifier).fetchData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Group statuses by user
    final groupedStatuses = _groupStatusesByUser(feedState.stories);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 130),
      children: [
        _buildStatusBar(context, groupedStatuses),
        const SizedBox(height: 18),
        _buildPostsList(feedState),
      ],
    );
  }

  // Group statuses by user ID to show one container per user
  Map<int, List<Map<String, dynamic>>> _groupStatusesByUser(
      List<dynamic> stories) {
    final Map<int, List<Map<String, dynamic>>> grouped = {};

    for (final story in stories) {
      final userId = _getUserId(story);
      if (!grouped.containsKey(userId)) {
        grouped[userId] = [];
      }
      grouped[userId]!.add(story);
    }

    return grouped;
  }

  int _getUserId(Map<String, dynamic> story) {
    final user = _asMap(story['user']);
    return user['id'] ??
        user['userId'] ??
        user['user_id'] ??
        story['userId'] ??
        story['user_id'] ??
        0;
  }

  Widget _buildPostsList(CachedFeedData feedState) {
    final posts = feedState.posts;
    final isLoadingMore = feedState.isLoadingMore;
    final hasMore = feedState.hasMore;

    if (posts.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
      );
    }

    return Column(
      children: [
        for (final post in posts)
          SizedBox(
            width: double.infinity,
            child: CardPost(post: post),
          ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 120),
            child: Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator(
                      color: AppColors.purpleColor,
                    )
                  : TextButton(
                      onPressed: () =>
                          ref.read(feedProvider.notifier).loadMore(),
                      child: Text(
                        'Load More',
                        style: AppTheme.blackTextStyle.copyWith(
                          color: AppColors.purpleColor,
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBar(BuildContext context,
      Map<int, List<Map<String, dynamic>>> groupedStatuses) {
    final List<_UserStatusGroup> userGroups = [];

    groupedStatuses.forEach((userId, stories) {
      if (stories.isNotEmpty) {
        final firstStory = stories.first;
        final user = _asMap(firstStory['user']);
        userGroups.add(_UserStatusGroup(
          userId: userId,
          name: _displayName(user),
          avatar: _userAvatar(user),
          statuses: stories,
          latestTime: _getLatestStatusTime(stories),
          hasUnviewed: stories
              .any((s) => !(s['isSeen'] == true || s['is_seen'] == true)),
        ));
      }
    });

    userGroups.sort((a, b) {
      if (a.hasUnviewed && !b.hasUnviewed) return -1;
      if (!a.hasUnviewed && b.hasUnviewed) return 1;
      return b.latestTime.compareTo(a.latestTime);
    });

    return SizedBox(
      height: 104,
      width: double.infinity,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: userGroups.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return StatusWidget(
              status: StatusModel(
                name: 'My Status',
                imgProfile: _userAvatar(_currentUser),
                statusImage: '',
                time: '',
              ),
              isAddStatus: true,
              statusCount: 0,
              hasUnviewed: false,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, NamedRoutes.createStatusScreen);
              },
            );
          }

          final group = userGroups[index - 1];
          final firstStatus = group.statuses.first;
          final status = _storyToStatus(firstStatus, group.statuses.length);

          return StatusWidget(
            status: status,
            statusCount: group.statuses.length,
            hasUnviewed: group.hasUnviewed,
            onTap: () {
              HapticFeedback.lightImpact();
              final statuses = group.statuses
                  .map<StatusModel>((item) => _storyToStatus(item, 0))
                  .toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatusViewPage(
                    statuses: statuses,
                    initialIndex: 0,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  DateTime _getLatestStatusTime(List<Map<String, dynamic>> stories) {
    DateTime latest = DateTime(2000);
    for (final story in stories) {
      final timeStr =
          story['time'] ?? story['createdAt'] ?? story['created_at'];
      if (timeStr != null) {
        try {
          final time = DateTime.parse(timeStr.toString());
          if (time.isAfter(latest)) {
            latest = time;
          }
        } catch (e) {
          // Ignore parse errors
        }
      }
    }
    return latest;
  }

  String _getUserDisplayName() {
    if (_isLoadingUser) {
      return 'Loading...';
    }

    final name = _currentUser['name'];
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }

    final username = _currentUser['username'];
    if (username != null && username.toString().trim().isNotEmpty) {
      return username.toString().trim();
    }

    return 'User';
  }

  String _getUserAvatar() {
    if (_isLoadingUser) {
      return '';
    }
    return (_currentUser['avatar'] ??
            _currentUser['avatarUrl'] ??
            _currentUser['avatar_url'] ??
            _currentUser['image'] ??
            '')
        .toString();
  }

  CustomAppBar _buildCustomAppBar(BuildContext context) {
    final userName = _getUserDisplayName();
    final userAvatar = _getUserAvatar();

    return CustomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            Image.asset(
              'assets/images/prive.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 14),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, NamedRoutes.notificationScreen);
              },
              child: Image.asset(
                'assets/images/ic_notification.png',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 14),
            InkWell(
              onTap: () {},
              child: Image.asset(
                'assets/images/ic_search.png',
                width: 28,
                height: 28,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  color: AppColors.primary,
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAvatar(userAvatar, size: 32),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.whiteTextStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (_currentUser['verified'] == true) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  StatusModel _storyToStatus(Map<String, dynamic> story, int statusCount) {
    final user = _asMap(story['user']);

    return StatusModel(
      id: _toInt(story['id']),
      userId: _toInt(story['userId'] ?? user['id']),
      name: _displayName(user),
      imgProfile: _userAvatar(user),
      statusImage: '', // Stories from API are text-based
      statusText: story['content']?.toString() ?? '', // Use 'content' field
      time: story['time']?.toString() ?? '',
      isViewed: story['isSeen'] == true || story['is_seen'] == true,
      statusCount: statusCount,
      backgroundColor: '#1D1B20',
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Widget _buildAvatar(String avatar, {required double size}) {
    if (avatar.isNotEmpty && avatar.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(size),
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
          errorBuilder: (_, __, ___) => _avatarFallback(size),
        ),
      );
    }

    return _avatarFallback(size);
  }

  Widget _avatarFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.whiteColor.withOpacity(0.25),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.65,
        color: AppColors.whiteColor,
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  String _displayName(Map<String, dynamic> user) {
    final name = user['name'];
    final username = user['username'];
    final email = user['email'];

    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString();
    }
    if (username != null && username.toString().trim().isNotEmpty) {
      return username.toString();
    }
    if (email != null && email.toString().trim().isNotEmpty) {
      return email.toString().split('@').first;
    }
    return 'User';
  }

  String _userAvatar(Map<String, dynamic> user) {
    return (user['avatar'] ??
            user['avatarUrl'] ??
            user['avatar_url'] ??
            user['image'] ??
            '')
        .toString();
  }
}

// Helper class for user status groups
class _UserStatusGroup {
  final int userId;
  final String name;
  final String avatar;
  final List<Map<String, dynamic>> statuses;
  final DateTime latestTime;
  final bool hasUnviewed;

  _UserStatusGroup({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.statuses,
    required this.latestTime,
    required this.hasUnviewed,
  });
}
