import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/notification/notification_service.dart';
import 'package:clique/ui/pages/main/notification/notification_details_page.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';
import 'package:clique/ui/widgets/common/effect_text.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCachedNotifications();
    _refreshNotifications(silent: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 500) {
      _loadMoreNotifications();
    }
  }

  void _loadCachedNotifications() {
    final cached = _notificationService.getCachedNotifications();
    if (cached == null) return;

    final notifications =
        (cached['notifications'] as List? ?? []).cast<Map<String, dynamic>>();
    final pagination = cached['pagination'] ?? {};
    final totalPages = pagination['totalPages'] ?? 1;
    final page = cached['page'] ?? 1;

    if (!mounted) return;

    setState(() {
      _notifications = notifications;
      _hasMore = page < totalPages;
      _currentPage = _hasMore ? page + 1 : page;
      _isLoading = false;
      _error = null;
    });
  }

  Future<void> _loadNotifications({
    bool refresh = false,
    bool silent = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      if (!silent || _notifications.isEmpty) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      } else {
        _error = null;
      }
    }

    try {
      final response = await _notificationService.getNotifications(
        page: _currentPage,
        pageSize: 20,
        forceRefresh: silent || refresh,
      );

      final newNotifications = response['notifications'] as List? ?? [];
      final pagination = response['pagination'] ?? {};
      final totalPages = pagination['totalPages'] ?? 1;
      final page = response['page'] ?? _currentPage;

      if (!mounted) return;

      setState(() {
        if (refresh || _currentPage == 1) {
          _notifications = newNotifications.cast<Map<String, dynamic>>();
        } else {
          _notifications.addAll(newNotifications.cast<Map<String, dynamic>>());
        }
        _hasMore = page < totalPages;
        _currentPage = _hasMore ? page + 1 : page;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        if (_notifications.isEmpty) {
          _error = e.toString();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshNotifications({bool silent = false}) async {
    await _loadNotifications(refresh: true, silent: silent);
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _notificationService.getNotifications(
        page: _currentPage,
        pageSize: 20,
      );

      final newNotifications = response['notifications'] as List? ?? [];
      final pagination = response['pagination'] ?? {};
      final totalPages = pagination['totalPages'] ?? 1;

      if (!mounted) return;

      setState(() {
        _notifications.addAll(newNotifications.cast<Map<String, dynamic>>());
        _hasMore = _currentPage < totalPages;
        _isLoadingMore = false;
      });

      if (newNotifications.isNotEmpty) {
        _currentPage++;
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _markAsRead(int notificationId, int index) async {
    try {
      await _notificationService.markAsRead(notificationId);
      if (!mounted) return;

      setState(() {
        final targetIndex = _notifications
            .indexWhere((notification) => notification['id'] == notificationId);
        if (targetIndex >= 0) {
          _notifications[targetIndex]['isUnread'] = false;
        }
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (!mounted) return;

      setState(() {
        for (var notification in _notifications) {
          notification['isUnread'] = false;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark all as read: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(int notificationId, int index) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      if (!mounted) return;

      setState(() {
        _notifications.removeWhere(
            (notification) => notification['id'] == notificationId);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete notification: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _groupNotifications(
    List<Map<String, dynamic>> notifications,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    final passthrough = <Map<String, dynamic>>[];

    for (final item in notifications) {
      final type = item['type']?.toString() ?? 'general';
      if (!_shouldGroup(type)) {
        passthrough.add(item);
        continue;
      }

      final data = _asMap(item['data']);
      final actorId = _readInt(
        item['actorId'] ??
            data['actorId'] ??
            data['actorUserId'] ??
            data['fromUserId'] ??
            data['likerUserId'] ??
            data['commenterUserId'] ??
            data['followerUserId'],
      );

      final key = '$type:$actorId';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    final result = <Map<String, dynamic>>[];

    for (final entry in grouped.entries) {
      final items = [...entry.value]..sort((a, b) {
          final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

      final representative = Map<String, dynamic>.from(items.first);
      representative['groupItems'] = items;
      representative['groupCount'] = items.length;
      representative['isUnread'] =
          items.any((item) => item['isUnread'] == true);
      result.add(representative);
    }

    result.addAll(passthrough);

    result.sort((a, b) {
      final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return result;
  }

  bool _shouldGroup(String type) {
    switch (type) {
      case 'like':
      case 'post_like':
      case 'comment':
      case 'post_comment':
      case 'follow':
      case 'friend_request':
      case 'friend_accepted':
      case 'mention':
        return true;
      default:
        return false;
    }
  }

  Future<void> _navigateByType(Map<String, dynamic> notification) async {
    final type = notification['type']?.toString();
    final data = _asMap(notification['data']);
    final targetId = _readInt(
      notification['targetId'] ??
          notification['target_id'] ??
          data['targetId'] ??
          data['target_id'] ??
          data['postId'] ??
          data['post_id'] ??
          data['profileId'] ??
          data['profile_id'] ??
          data['matchId'] ??
          data['match_id'] ??
          data['conversationId'] ??
          data['conversation_id'],
    );
    final actorId = _readInt(
      notification['actorId'] ??
          notification['actor_id'] ??
          notification['fromUserId'] ??
          notification['from_user_id'] ??
          notification['userId'] ??
          notification['user_id'] ??
          data['actorId'] ??
          data['actor_id'] ??
          data['actorUserId'] ??
          data['actor_user_id'] ??
          data['followerUserId'] ??
          data['follower_user_id'] ??
          data['fromUserId'] ??
          data['from_user_id'] ??
          data['friendUserId'] ??
          data['friend_user_id'] ??
          data['likerUserId'] ??
          data['liker_user_id'] ??
          data['matchedUserId'] ??
          data['matched_user_id'] ??
          data['userId'] ??
          data['user_id'],
    );
    final conversationId = _readInt(
      data['conversationId'] ??
          data['conversation_id'] ??
          notification['conversationId'] ??
          notification['conversation_id'],
    );

    switch (type) {
      case 'like':
      case 'post_like':
      case 'comment':
      case 'post_comment':
      case 'mention':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationDetailsPage(notification: notification),
          ),
        );
        return;
      case 'reel_like':
      case 'reel_comment':
      case 'reel_mention':
      case 'reel_share':
      case 'reel_repost':
        Navigator.pushNamed(context, NamedRoutes.reelsScreen);
        return;
      case 'story_like':
      case 'story_comment':
      case 'story_mention':
      case 'story_repost':
      case 'status_like':
      case 'status_comment':
      case 'status_mention':
      case 'status_repost':
        Navigator.pushNamed(context, NamedRoutes.statusScreen);
        return;
      case 'follow':
      case 'friend_request':
      case 'friend_accepted':
        if (actorId > 0) {
          Navigator.pushNamed(context, NamedRoutes.otherProfileScreen,
              arguments: actorId);
        } else {
          Navigator.pushNamed(context, NamedRoutes.friendListScreen);
        }
        return;
      case 'match':
        if (actorId > 0) {
          Navigator.pushNamed(context, NamedRoutes.otherProfileScreen,
              arguments: actorId);
        } else {
          Navigator.pushNamed(context, NamedRoutes.matchScreen);
        }
        return;
      case 'message':
      case 'chat':
        final id = conversationId > 0 ? conversationId : targetId;
        if (id > 0) {
          Navigator.pushNamed(
            context,
            NamedRoutes.chatScreen,
            arguments: {
              'conversationId': id,
              'userName': actorId > 0 ? _actorName(notification) : '',
              'userAvatar': notification['actorAvatar'] ?? data['actorAvatar'],
              'userId': actorId,
            },
          );
        } else {
          Navigator.pushNamed(context, NamedRoutes.inboxScreen);
        }
        return;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationDetailsPage(notification: notification),
          ),
        );
        return;
    }
  }

  String _getNotificationContent(Map<String, dynamic> notification) {
    final type = notification['type'];
    final message = (notification['content'] ?? notification['message'] ?? '')
        .toString()
        .trim();
    final groupCount = _readInt(notification['groupCount']);

    switch (type) {
      case 'like':
      case 'post_like':
        if (groupCount > 1) {
          return 'liked $groupCount of your posts.';
        }
        return message.toLowerCase().contains('profile')
            ? 'liked your profile.'
            : 'liked your post.';
      case 'comment':
      case 'post_comment':
        if (groupCount > 1) {
          return 'commented on $groupCount of your posts.';
        }
        final snippet = notification['snippet'] ?? '';
        return snippet.toString().isNotEmpty
            ? 'commented: "$snippet"'
            : 'commented on your post.';
      case 'follow':
        if (groupCount > 1) {
          return 'and $groupCount others started following you.';
        }
        return 'started following you.';
      case 'mention':
        return 'mentioned you in a comment.';
      case 'match':
        return 'matched with you.';
      case 'friend_request':
        return 'sent you a friend request.';
      case 'friend_accepted':
        return 'accepted your friend request.';
      default:
        return message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleNotifications = _groupNotifications(_notifications);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Notifications',
            subtitle: _notifications.isEmpty
                ? 'Recent activity'
                : '${visibleNotifications.where((n) => n['isUnread'] == true).length} unread',
            leadingIcon: Icons.arrow_back_ios_new,
            onLeadingTap: () => Navigator.pop(context),
            actionIcon: visibleNotifications.any((n) => n['isUnread'] == true)
                ? Icons.done_all_rounded
                : Icons.notifications_outlined,
            onActionTap: visibleNotifications.any((n) => n['isUnread'] == true)
                ? _markAllAsRead
                : null,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshNotifications,
              color: AppColors.primary,
              child: _isLoading && _notifications.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _error != null && _notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: AppTheme.greyTextStyle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshNotifications,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _notifications.isEmpty
                          ? _buildEmptyState()
                          : Stack(
                              children: [
                                ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.only(
                                      top: 8, bottom: 100),
                                  itemCount: visibleNotifications.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return _buildNewestHeader();
                                    }
                                    final notificationIndex = index - 1;
                                    return _buildNotificationItem(
                                      visibleNotifications[notificationIndex],
                                      notificationIndex,
                                    );
                                  },
                                ),
                                if (_isLoadingMore)
                                  const Positioned(
                                    bottom: 20,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                _buildBlurBottomGradient(),
                              ],
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.greyColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 50,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When someone interacts with your content,\nit will appear here.',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshNotifications,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 48),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Refresh',
              style: AppTheme.whiteTextStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewestHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'NEWEST',
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 11,
              fontWeight: AppTheme.bold,
              letterSpacing: 1.5,
            ),
          ),
          if (_notifications.isNotEmpty)
            Text(
              '${_notifications.length} items',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item, int index) {
    final bool isUnread = item['isUnread'] ?? false;
    final data = _asMap(item['data']);
    final type = item['type']?.toString() ?? 'general';
    final groupItems = (item['groupItems'] as List?)?.cast<Map>() ?? const [];
    final groupCount = _readInt(item['groupCount']);
    final String avatar =
        (item['actorAvatar'] ?? data['actorAvatar'] ?? '').toString();
    final String actorName = _actorName(item);
    final String content = _getNotificationContent(item);
    final String time = _formatTime(item['createdAt']);
    final String postImage =
        (item['postImage'] ?? data['postImage'] ?? data['imageUrl'] ?? '')
            .toString();
    final accent = _notificationColor(type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? accent.withOpacity(0.35) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(isUnread ? 0.07 : 0.03),
            blurRadius: isUnread ? 18 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          HapticFeedback.lightImpact();
          if (isUnread) {
            final ids = groupItems.isNotEmpty
                ? groupItems
                    .map((entry) => _readInt(entry['id']))
                    .where((value) => value > 0)
                    .toList()
                : [_readInt(item['id'])];
            for (final id in ids) {
              await _markAsRead(id, index);
            }
          }
          await _navigateByType(item);
        },
        onLongPress: () {
          final ids = groupItems.isNotEmpty
              ? groupItems
                  .map((entry) => _readInt(entry['id']))
                  .where((value) => value > 0)
                  .toList()
              : [_readInt(item['id'])];
          _showDeleteDialog(ids, index);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUnread
                            ? accent.withOpacity(0.45)
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: avatar.isNotEmpty && avatar.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: avatar,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _avatarFallback(actorName),
                            )
                          : _avatarFallback(actorName),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Icon(
                        _notificationIcon(type),
                        size: 12,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  if (isUnread)
                    Positioned(
                      left: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EffectText(
                      text:
                          '$actorName ${groupCount > 1 && _shouldGroup(type) ? (type == 'like' || type == 'post_like' ? 'liked $groupCount of your posts.' : content) : content}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 14,
                        height: 1.3,
                        color: isUnread
                            ? AppColors.blackColor
                            : AppColors.greyColor,
                        fontWeight:
                            isUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                      hashtagColor: AppColors.primary,
                      mentionColor: AppColors.secondary,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          time,
                          style: AppTheme.greyTextStyle.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.greyColor.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            groupCount > 1 && _shouldGroup(type)
                                ? '$groupCount updates'
                                : _notificationActionLabel(type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.greyTextStyle.copyWith(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (postImage.isNotEmpty)
                _postPreview(postImage, accent)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.greyColor.withOpacity(0.7),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _postPreview(String imageUrl, Color accent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorWidget: (context, error, stackTrace) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.article_outlined,
              color: accent,
              size: 20,
            ),
          );
        },
      ),
    );
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'like':
      case 'post_like':
        return Icons.favorite_rounded;
      case 'comment':
      case 'post_comment':
      case 'mention':
        return Icons.chat_bubble_rounded;
      case 'follow':
      case 'friend_request':
      case 'friend_accepted':
        return Icons.person_add_alt_1_rounded;
      case 'match':
        return Icons.local_fire_department_rounded;
      case 'message':
      case 'chat':
        return Icons.mail_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _notificationColor(String type) {
    switch (type) {
      case 'like':
      case 'post_like':
        return AppColors.primary;
      case 'comment':
      case 'post_comment':
      case 'mention':
        return AppColors.info;
      case 'follow':
      case 'friend_request':
      case 'friend_accepted':
        return AppColors.success;
      case 'match':
        return AppColors.purple;
      case 'message':
      case 'chat':
        return AppColors.secondary;
      default:
        return AppColors.greyColor;
    }
  }

  String _notificationActionLabel(String type) {
    switch (type) {
      case 'like':
      case 'post_like':
      case 'comment':
      case 'post_comment':
      case 'mention':
        return 'View post';
      case 'follow':
      case 'friend_request':
      case 'friend_accepted':
      case 'match':
        return 'View profile';
      case 'message':
      case 'chat':
        return 'Open chat';
      default:
        return 'Open';
    }
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  String _actorName(Map<String, dynamic> item) {
    final data = _asMap(item['data']);
    final value = item['actorName'] ??
        data['actorName'] ??
        data['actorUsername'] ??
        data['username'];
    final name = value?.toString().trim() ?? '';
    return name.isEmpty ? 'User' : name;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _showDeleteDialog(List<int> notificationIds, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Notification',
          style: AppTheme.blackTextStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this notification?',
          style: AppTheme.greyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTheme.greyTextStyle),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              for (final id in notificationIds) {
                _deleteNotification(id, index);
              }
            },
            child: Text(
              'Delete',
              style:
                  AppTheme.blackTextStyle.copyWith(color: AppColors.redColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Just now';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 7) {
        return '${difference.inDays ~/ 7}w ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  Widget _buildBlurBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundColor.withOpacity(0),
                AppColors.backgroundColor.withOpacity(0.8),
                AppColors.backgroundColor,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
