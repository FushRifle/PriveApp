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
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get notifications';
    }
  }

  // Mark as read
  Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    try {
      final response =
          await _api.put('/api/notifications/$notificationId/read');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to mark as read';
    }
  }

  // Mark all as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final response = await _api.put('/api/notifications/read-all');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to mark all as read';
    }
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      final response = await _api.delete('/api/notifications/$notificationId');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete notification';
    }
  }

  // Delete all notifications
  Future<Map<String, dynamic>> deleteAllNotifications() async {
    try {
      final response = await _api.delete('/api/notifications');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete all notifications';
    }
  }

  // Get preferences
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await _api.get('/api/notifications/preferences');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get preferences';
    }
  }

  // Update preferences
  Future<Map<String, dynamic>> updatePreferences(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('/api/notifications/preferences', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update preferences';
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
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to register device token';
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
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete device token';
    }
  }
}
