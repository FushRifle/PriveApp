import 'package:clique/ui/widgets/notification/notification_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/named_routes.dart';
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
  
  bool _isUnread = false;
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
        const SnackBar(
          content: Text('Notification deleted'),
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: AppColors.red,
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
        const SnackBar(
          content: Text('Group notifications deleted'),
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete group: $e'),
          backgroundColor: AppColors.red,
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
            builder: (_) => NotificationDetailsPage(notification: _notification),
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
            builder: (_) => NotificationDetailsPage(notification: _notification),
          ),
        );
    }
  }

  List<int> _getNotificationIds() {
    final groupItems = (_notification['groupItems'] as List?)?.cast<Map>() ?? [];
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
              style: AppTheme.blackTextStyle.copyWith(color: AppColors.redColor),
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

    return NotificationGroupWidget(
      notification: _notification,
      isUnread: _isUnread,
      accent: accent,
      onTap: _handleTap,
      onLongPress: _handleLongPress,
    );
  }
}