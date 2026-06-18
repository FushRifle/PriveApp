import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';

class NotificationUtils {
  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static int readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String actorName(Map<String, dynamic> item) {
    final data = asMap(item['data']);
    final value = item['actorName'] ??
        data['actorName'] ??
        data['actorUsername'] ??
        data['username'];
    final name = value?.toString().trim() ?? '';
    return name.isEmpty ? 'User' : name;
  }

  static String getContent(Map<String, dynamic> notification) {
    final type = notification['type'];
    final message = (notification['content'] ?? notification['message'] ?? '')
        .toString()
        .trim();
    final groupCount = readInt(notification['groupCount']);

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

  static bool shouldGroup(String type) {
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

  static String formatTime(String? dateTimeStr) {
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

  static Color notificationColor(String type) {
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

  static String actionLabel(String type) {
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

  static IconData iconForType(String type) {
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
}