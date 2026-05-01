import 'package:dio/dio.dart';
import '../api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  // Get conversations
  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _api.get('/chat/conversations');
      return response.data is List ? response.data : [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get conversations';
    }
  }

  // Get messages with a specific user
  Future<List<dynamic>> getMessages(int userId, {int page = 1}) async {
    try {
      final response =
          await _api.get('/chat/messages/$userId', queryParameters: {
        'page': page,
      });
      return response.data is List ? response.data : [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get messages';
    }
  }

  // Send message
  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/chat/messages', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to send message';
    }
  }

  // Mark messages as read
  Future<Map<String, dynamic>> markMessagesAsRead(int userId) async {
    try {
      final response = await _api.post('/chat/messages/$userId/read');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to mark as read';
    }
  }

  // Get chat preferences
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await _api.get('/chat/preferences');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get preferences';
    }
  }

  // Update chat preferences
  Future<Map<String, dynamic>> updatePreferences(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/chat/preferences', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update preferences';
    }
  }

  // Set online status
  Future<Map<String, dynamic>> setOnlineStatus(bool isOnline) async {
    try {
      final response = await _api.post('/chat/status/online', data: {
        'isOnline': isOnline,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update online status';
    }
  }

  // Set typing status
  Future<Map<String, dynamic>> setTypingStatus(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/chat/status/typing', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update typing status';
    }
  }
}
