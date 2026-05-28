import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/data/services/notification/notification_service.dart';

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
    _loadNotifications();
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

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

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
        if (refresh || _currentPage == 1) {
          _notifications = newNotifications.cast<Map<String, dynamic>>();
        } else {
          _notifications.addAll(newNotifications.cast<Map<String, dynamic>>());
        }
        _hasMore = _currentPage < totalPages;
        _isLoading = false;
      });

      if (newNotifications.isNotEmpty) {
        _currentPage++;
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications(refresh: true);
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
      if (!mounted || index >= _notifications.length) return;

      setState(() {
        _notifications[index]['isUnread'] = false;
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
      if (!mounted || index >= _notifications.length) return;

      setState(() {
        _notifications.removeAt(index);
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

  void _navigateByType(Map<String, dynamic> notification) {
    final type = notification['type'];
    final targetId = notification['targetId'];

    switch (type) {
      case 'like':
      case 'comment':
        debugPrint('Navigate to post: $targetId');
        break;
      case 'follow':
        debugPrint('Navigate to profile: ${notification['actorId']}');
        break;
      case 'mention':
        debugPrint('Navigate to mention: $targetId');
        break;
      default:
        break;
    }
  }

  String _getNotificationContent(Map<String, dynamic> notification) {
    final type = notification['type'];

    switch (type) {
      case 'like':
        return 'liked your post.';
      case 'comment':
        final snippet = notification['snippet'] ?? '';
        return 'commented: "$snippet"';
      case 'follow':
        return 'started following you.';
      case 'mention':
        return 'mentioned you in a comment.';
      default:
        return notification['content'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 1,
        title: Text(
          'Notifications',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_notifications.any((n) => n['isUnread'] == true))
            IconButton(
              icon:
                  const Icon(Icons.done_all_rounded, color: AppColors.black87),
              onPressed: _markAllAsRead,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        color: AppColors.primary,
        child: _isLoading && _notifications.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
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
                            padding: const EdgeInsets.only(top: 8, bottom: 100),
                            itemCount: _notifications.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildNewestHeader();
                              }
                              final notificationIndex = index - 1;
                              return _buildNotificationItem(
                                _notifications[notificationIndex],
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
    final String avatar = item['actorAvatar'] ?? '';
    final String actorName = item['actorName'] ?? 'Someone';
    final String content = _getNotificationContent(item);
    final String time = _formatTime(item['createdAt']);
    final String? postImage = item['postImage'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.white : AppColors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ]
            : [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          HapticFeedback.lightImpact();
          if (isUnread) {
            await _markAsRead(item['id'], index);
          }
          _navigateByType(item);
        },
        onLongPress: () {
          _showDeleteDialog(item['id'], index);
        },
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnread
                          ? AppColors.primary.withOpacity(0.3)
                          : AppColors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: avatar.isNotEmpty && avatar.startsWith('http')
                        ? Image.network(
                            avatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _avatarFallback(actorName),
                          )
                        : _avatarFallback(actorName),
                  ),
                ),
                if (isUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 14,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(
                          text: '$actorName ',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: content,
                          style: TextStyle(
                            color: isUnread
                                ? AppColors.blackColor
                                : AppColors.greyColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: AppTheme.greyTextStyle.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Action Preview
            if (postImage != null && postImage.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  postImage,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.image,
                        color: AppColors.primary.withOpacity(0.5),
                        size: 20,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
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

  void _showDeleteDialog(int notificationId, int index) {
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
              _deleteNotification(notificationId, index);
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
