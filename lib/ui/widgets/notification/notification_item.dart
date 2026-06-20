import 'package:clique/ui/widgets/notification/notification_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/friends/friends_service.dart';
import 'package:clique/core/services/notification/notification_service.dart';
import 'package:clique/ui/widgets/notification/notification_utils.dart';
import 'package:clique/ui/pages/main/notification/notification_details_page.dart';

class NotificationItem extends StatefulWidget {
  final Map<String, dynamic> notification;

  const NotificationItem({
    super.key,
    required this.notification,
  });

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  final NotificationService _notificationService = NotificationService();
  final FriendsService _friendsService = FriendsService();

  bool _isUnread = false;
  bool _isHandlingFollow = false;
  bool _followHandled = false;
  late Map<String, dynamic> _notification;

  @override
  void initState() {
    super.initState();
    _notification = widget.notification;
    _isUnread = _notification['isUnread'] ?? false;
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      if (!mounted) return;

      setState(() {
        _isUnread = false;
        _notification['isUnread'] = false;
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _markGroupAsRead(List<int> notificationIds) async {
    try {
      for (final id in notificationIds) {
        await _notificationService.markAsRead(id);
      }
      if (!mounted) return;

      setState(() {
        _isUnread = false;
        _notification['isUnread'] = false;
        final groupItems = _notification['groupItems'] as List? ?? [];
        for (var item in groupItems) {
          item['isUnread'] = false;
        }
      });
    } catch (e) {
      debugPrint('Error marking group as read: $e');
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification deleted',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.card,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete: $e',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.card,
        ),
      );
    }
  }

  Future<void> _deleteGroup(List<int> notificationIds) async {
    try {
      for (final id in notificationIds) {
        await _notificationService.deleteNotification(id);
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Group notifications deleted',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.card,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete group: $e',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.card,
        ),
      );
    }
  }

  void _navigateByType() async {
    final type = _notification['type']?.toString() ?? 'general';
    final data = NotificationUtils.asMap(_notification['data']);
    final actorId = NotificationUtils.readInt(
      _notification['actorId'] ??
          data['actorId'] ??
          data['actorUserId'] ??
          data['fromUserId'] ??
          data['likerUserId'] ??
          data['commenterUserId'] ??
          data['followerUserId'],
    );
    final conversationId = NotificationUtils.readInt(
      data['conversationId'] ??
          data['conversation_id'] ??
          _notification['conversationId'] ??
          _notification['conversation_id'],
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
            builder: (_) =>
                NotificationDetailsPage(notification: _notification),
          ),
        );
        break;

      case 'reel_like':
      case 'reel_comment':
      case 'reel_mention':
      case 'reel_share':
      case 'reel_repost':
        Navigator.pushNamed(context, NamedRoutes.reelsScreen);
        break;

      case 'story_like':
      case 'story_comment':
      case 'story_mention':
      case 'story_repost':
      case 'status_like':
      case 'status_comment':
      case 'status_mention':
      case 'status_repost':
        Navigator.pushNamed(context, NamedRoutes.statusScreen);
        break;

      case 'follow':
      case 'friend_request':
      case 'friend_accepted':
        if (actorId > 0) {
          Navigator.pushNamed(context, NamedRoutes.otherProfileScreen,
              arguments: actorId);
        } else {
          Navigator.pushNamed(context, NamedRoutes.friendListScreen);
        }
        break;

      case 'match':
        if (actorId > 0) {
          Navigator.pushNamed(context, NamedRoutes.otherProfileScreen,
              arguments: actorId);
        } else {
          Navigator.pushNamed(context, NamedRoutes.matchScreen);
        }
        break;

      case 'message':
      case 'chat':
        if (conversationId > 0) {
          Navigator.pushNamed(
            context,
            NamedRoutes.chatScreen,
            arguments: {
              'conversationId': conversationId,
              'userName': NotificationUtils.actorName(_notification),
              'userAvatar': _notification['actorAvatar'] ?? data['actorAvatar'],
              'userId': actorId,
            },
          );
        } else {
          Navigator.pushNamed(context, NamedRoutes.inboxScreen);
        }
        break;

      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                NotificationDetailsPage(notification: _notification),
          ),
        );
    }
  }

  List<int> _getNotificationIds() {
    final groupItems =
        (_notification['groupItems'] as List?)?.cast<Map>() ?? [];
    if (groupItems.isNotEmpty) {
      return groupItems
          .map((entry) => NotificationUtils.readInt(entry['id']))
          .where((value) => value > 0)
          .toList();
    }
    return [NotificationUtils.readInt(_notification['id'])];
  }

  void _handleTap() {
    HapticFeedback.lightImpact();

    final ids = _getNotificationIds();

    if (_isUnread) {
      if (ids.length > 1) {
        unawaited(_markGroupAsRead(ids));
      } else {
        unawaited(_markAsRead(ids.first));
      }
    }
    _navigateByType();
  }

  void _handleLongPress() {
    final ids = _getNotificationIds();
    final isGroup = ids.length > 1;
    _showDeleteDialog(ids, isGroup);
  }

  Future<void> _acceptFollower() async {
    final actorId = _actorId();
    if (actorId <= 0 || _isHandlingFollow) return;
    setState(() => _isHandlingFollow = true);
    try {
      await _friendsService.followUser(actorId);
      await _markFollowHandled('Follower accepted');
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('already')) {
        await _markFollowHandled('Already following');
        return;
      }
      _showActionSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isHandlingFollow = false);
    }
  }

  Future<void> _rejectFollower() async {
    final actorId = _actorId();
    if (actorId <= 0 || _isHandlingFollow) return;
    setState(() => _isHandlingFollow = true);
    try {
      await _friendsService.removeFollower(actorId);
      await _markFollowHandled('Follower rejected');
    } catch (e) {
      _showActionSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isHandlingFollow = false);
    }
  }

  Future<void> _markFollowHandled(String message) async {
    final ids = _getNotificationIds();
    if (ids.isNotEmpty) {
      if (ids.length > 1) {
        await _markGroupAsRead(ids);
      } else {
        await _markAsRead(ids.first);
      }
    }
    if (!mounted) return;
    setState(() => _followHandled = true);
    _showActionSnack(message);
  }

  void _showActionSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: AppColors.text),
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int _actorId() {
    final data = NotificationUtils.asMap(_notification['data']);
    return NotificationUtils.readInt(
      _notification['actorId'] ??
          data['actorId'] ??
          data['actorUserId'] ??
          data['fromUserId'] ??
          data['followerUserId'],
    );
  }

  bool _shouldShowFollowActions() {
    if (_followHandled) return false;
    final type = _notification['type']?.toString() ?? '';
    return type == 'follow' && _actorId() > 0;
  }

  void _showDeleteDialog(List<int> notificationIds, bool isGroup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isGroup ? 'Delete Group' : 'Delete Notification',
          style: AppTheme.blackTextStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isGroup
              ? 'Are you sure you want to delete all ${notificationIds.length} notifications in this group?'
              : 'Are you sure you want to delete this notification?',
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
              if (isGroup) {
                _deleteGroup(notificationIds);
              } else {
                for (final id in notificationIds) {
                  _deleteNotification(id);
                }
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

  @override
  Widget build(BuildContext context) {
    final type = _notification['type']?.toString() ?? 'general';
    final accent = NotificationUtils.notificationColor(type);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NotificationGroupWidget(
          notification: _notification,
          isUnread: _isUnread,
          accent: accent,
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          trailing: _shouldShowFollowActions()
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      _FollowActionButton(
                        onPressed: _isHandlingFollow ? null : _rejectFollower,
                        icon: Icons.close_rounded,
                        color: AppColors.grey,
                        label: 'Decline',
                      ),
                      const Spacer(),
                      _FollowActionButton(
                        onPressed: _isHandlingFollow ? null : _acceptFollower,
                        icon: _isHandlingFollow
                            ? null
                            : Icons.check_rounded,
                        color: AppColors.primary,
                        label: 'Accept',
                        isLoading: _isHandlingFollow,
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _FollowActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final String label;
  final bool isLoading;

  const _FollowActionButton({
    required this.onPressed,
    this.icon,
    required this.color,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: onPressed != null
                ? color.withOpacity(0.12)
                : color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: onPressed != null
                  ? color.withOpacity(0.3)
                  : color.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 16,
                  color: onPressed != null
                      ? color
                      : color.withOpacity(0.5),
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onPressed != null
                      ? color
                      : color.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}