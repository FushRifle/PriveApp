import 'package:dio/dio.dart';
import '../../../core/api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  void setAuthToken(String token) {
    _api.setAuthToken(token);
  }

  void clearAuthToken() {
    _api.clearAuthToken();
  }

  // Get all conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await _api.get('/api/chat/conversations');
      return response.data is List
          ? List<Map<String, dynamic>>.from(response.data)
          : [];
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load conversations');
    }
  }

  // Get conversation info
  Future<Map<String, dynamic>> getConversationInfo(int conversationId) async {
    try {
      final response =
          await _api.get('/api/chat/conversations/$conversationId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load conversation info');
    }
  }

  // Get messages for a conversation
  Future<List<Map<String, dynamic>>> getMessages(int conversationId,
      {int page = 1}) async {
    try {
      final response = await _api
          .get('/api/chat/messages/$conversationId', queryParameters: {
        'page': page,
      });
      return response.data is List
          ? List<Map<String, dynamic>>.from(response.data)
          : [];
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load messages');
    }
  }

  // Send a message
  Future<void> sendMessage({
    required int receiverId,
    required String message,
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    try {
      final data = {
        'receiverId': receiverId,
        'message': message,
        'messageType': messageType,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
      };
      await _api.post('/api/chat/messages', data: data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to send message');
    }
  }

  // Mark messages as read
  Future<void> markAsRead(int conversationId) async {
    try {
      await _api.post('/api/chat/messages/$conversationId/read');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to mark as read');
    }
  }

  // Get chat settings for a conversation
  Future<Map<String, dynamic>> getChatSettings(int conversationId) async {
    try {
      final response = await _api.get('/api/chat/settings/$conversationId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load chat settings');
    }
  }

  // Update chat settings
  Future<void> updateChatSettings(
    int conversationId, {
    bool? isPinned,
    bool? isMuted,
    DateTime? muteUntil,
    String? wallpaper,
    String? chatColor,
    String? notificationSound,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (isPinned != null) data['isPinned'] = isPinned;
      if (isMuted != null) data['isMuted'] = isMuted;
      if (muteUntil != null) data['muteUntil'] = muteUntil.toIso8601String();
      if (wallpaper != null) data['wallpaper'] = wallpaper;
      if (chatColor != null) data['chatColor'] = chatColor;
      if (notificationSound != null) {
        data['notificationSound'] = notificationSound;
      }

      await _api.put('/api/chat/settings/$conversationId', data: data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to update chat settings');
    }
  }

  // Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await _api.get('/api/chat/preferences');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load preferences');
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences({
    String? wallpaper,
    String? chatColor,
    String? notificationSound,
    int? fontSize,
    bool? enterToSend,
    bool? readReceipts,
    bool? typingIndicators,
    bool? messagePreview,
    String? autoDownloadMedia,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (wallpaper != null) data['wallpaper'] = wallpaper;
      if (chatColor != null) data['chatColor'] = chatColor;
      if (notificationSound != null) {
        data['notificationSound'] = notificationSound;
      }
      if (fontSize != null) data['fontSize'] = fontSize;
      if (enterToSend != null) data['enterToSend'] = enterToSend;
      if (readReceipts != null) data['readReceipts'] = readReceipts;
      if (typingIndicators != null) data['typingIndicators'] = typingIndicators;
      if (messagePreview != null) data['messagePreview'] = messagePreview;
      if (autoDownloadMedia != null) {
        data['autoDownloadMedia'] = autoDownloadMedia;
      }

      await _api.put('/api/chat/preferences', data: data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to update preferences');
    }
  }

  // Set typing status
  Future<void> setTyping(int conversationId, bool isTyping) async {
    try {
      await _api.post('/api/chat/typing', data: {
        'conversationId': conversationId,
        'isTyping': isTyping,
      });
    } on DioException catch (e) {
      // Silently fail - typing status is non-critical
      print('Failed to set typing status: $e');
    }
  }

  // Block user
  Future<void> blockUser(int userId) async {
    try {
      await _api.post('/api/chat/block', data: {'userIdToBlock': userId});
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to block user');
    }
  }

  // Unblock user
  Future<void> unblockUser(int userId) async {
    try {
      await _api.delete('/api/chat/block/$userId');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to unblock user');
    }
  }

  // Clear chat
  Future<void> clearChat(int conversationId) async {
    try {
      await _api.delete('/api/chat/clear/$conversationId');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to clear chat');
    }
  }

  String _handleError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    return fallback;
  }
}
