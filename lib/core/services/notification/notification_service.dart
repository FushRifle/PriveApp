import 'package:dio/dio.dart';
import '../../clients/api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  // Get notifications
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _api.get('/api/notifications', queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'unread': unreadOnly,
      });
      return _normalizeNotificationsResponse(response.data, pageSize);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get notifications');
    }
  }

  // Mark as read
  Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    try {
      final response =
          await _api.put('/api/notifications/$notificationId/read');
      _api.removeCacheByPath('/api/notifications');
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to mark as read');
    }
  }

  // Mark all as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final response = await _api.put('/api/notifications/read-all');
      _api.removeCacheByPath('/api/notifications');
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to mark all as read');
    }
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      final response = await _api.delete('/api/notifications/$notificationId');
      _api.removeCacheByPath('/api/notifications');
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to delete notification');
    }
  }

  // Delete all notifications
  Future<Map<String, dynamic>> deleteAllNotifications() async {
    try {
      final response = await _api.delete('/api/notifications');
      _api.removeCacheByPath('/api/notifications');
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to delete all notifications');
    }
  }

  // Get preferences
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await _api.get('/api/notifications/preferences');
      return _normalizePreferences(_asMap(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get preferences');
    }
  }

  // Update preferences
  Future<Map<String, dynamic>> updatePreferences(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/api/notifications/preferences',
          data: _toApiPreferences(data));
      _api.removeCacheByPath('/api/notifications/preferences');
      return _normalizePreferences(_asMap(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to update preferences');
    }
  }

  Future<Map<String, dynamic>> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    try {
      final response = await _api.post(
        '/api/notifications/device-tokens',
        data: {
          'token': token,
          'platform': platform,
          if (deviceId != null && deviceId.trim().isNotEmpty)
            'deviceId': deviceId,
        },
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to register device token');
    }
  }

  Future<Map<String, dynamic>> deleteDeviceToken(String token) async {
    try {
      final response = await _api.delete(
        '/api/notifications/device-tokens',
        data: {
          'token': token,
        },
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to delete device token');
    }
  }

  Map<String, dynamic> _normalizeNotificationsResponse(
    dynamic data,
    int pageSize,
  ) {
    final map = _asMap(data);
    final items = _readList(map, const ['notifications', 'data', 'items'])
        .map(_normalizeNotificationItem)
        .toList();
    final total = _readInt(map['total'] ?? map['count'], items.length);
    final page = _readInt(map['page'], 1);
    final totalPages = pageSize > 0 ? (total / pageSize).ceil() : 1;

    return {
      ...map,
      'notifications': items,
      'data': items,
      'total': total,
      'page': page,
      'unreadCount': _readInt(
        map['unreadCount'] ?? map['unread_count'],
        items.where((item) {
          final n = _asMap(item);
          return n['isRead'] != true && n['read'] != true;
        }).length,
      ),
      'pagination': {
        ..._asMap(map['pagination']),
        'totalPages': totalPages < 1 ? 1 : totalPages,
      },
    };
  }

  Map<String, dynamic> _normalizeNotificationItem(dynamic item) {
    final json = _asMap(item);
    final data = _asMap(json['data']);
    final isRead = json['isRead'] == true || json['read'] == true;
    final type = json['type']?.toString() ?? 'general';

    return {
      ...json,
      'type': _normalizeNotificationType(type),
      'isUnread': !isRead,
      'isRead': isRead,
      'actorId': json['actorId'] ??
          data['actorId'] ??
          data['actorUserId'] ??
          data['followerUserId'] ??
          data['fromUserId'] ??
          data['friendUserId'] ??
          data['likerUserId'] ??
          data['commenterUserId'] ??
          data['swiperId'] ??
          data['matchedUserId'] ??
          data['userId'],
      'actorName': json['actorName'] ??
          data['actorName'] ??
          data['actorUsername'] ??
          data['username'] ??
          '',
      'actorAvatar': json['actorAvatar'] ?? data['actorAvatar'] ?? '',
      'targetId': json['targetId'] ??
          data['targetId'] ??
          data['postId'] ??
          data['profileId'] ??
          data['matchId'] ??
          data['conversationId'] ??
          data['groupId'] ??
          data['communityId'],
      'postImage': json['postImage'] ?? data['postImage'] ?? data['imageUrl'],
      'content': json['message'] ?? json['content'] ?? '',
      'data': data,
    };
  }

  String _normalizeNotificationType(String type) {
    switch (type) {
      case 'new_like':
      case 'post_like':
        return 'like';
      case 'new_comment':
      case 'post_comment':
        return 'comment';
      case 'new_follower':
        return 'follow';
      case 'achievement':
        return 'match';
      default:
        return type;
    }
  }

  Map<String, dynamic> _normalizePreferences(Map<String, dynamic> json) {
    return {
      ...json,
      'pushEnabled': json['pushEnabled'] ?? json['pushNotifications'] ?? true,
      'emailEnabled':
          json['emailEnabled'] ?? json['emailNotifications'] ?? true,
      'likeNotifications':
          json['likeNotifications'] ?? json['notifyNewLike'] ?? true,
      'commentNotifications':
          json['commentNotifications'] ?? json['notifyNewComment'] ?? true,
      'followNotifications':
          json['followNotifications'] ?? json['notifyNewFollower'] ?? true,
      'messageNotifications':
          json['messageNotifications'] ?? json['notifyFriendRequest'] ?? true,
      'matchNotifications':
          json['matchNotifications'] ?? json['notifySystemUpdates'] ?? true,
    };
  }

  Map<String, dynamic> _toApiPreferences(Map<String, dynamic> json) {
    return {
      if (json.containsKey('emailEnabled'))
        'emailNotifications': json['emailEnabled'],
      if (json.containsKey('pushEnabled'))
        'pushNotifications': json['pushEnabled'],
      if (json.containsKey('likeNotifications'))
        'notifyNewLike': json['likeNotifications'],
      if (json.containsKey('commentNotifications'))
        'notifyNewComment': json['commentNotifications'],
      if (json.containsKey('followNotifications'))
        'notifyNewFollower': json['followNotifications'],
      if (json.containsKey('messageNotifications'))
        'notifyFriendRequest': json['messageNotifications'],
      if (json.containsKey('matchNotifications'))
        'notifySystemUpdates': json['matchNotifications'],
    };
  }

  List<dynamic> _readList(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) return value;
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String _handleError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return fallback;
  }
}
