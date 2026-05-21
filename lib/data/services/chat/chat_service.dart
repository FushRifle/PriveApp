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

  // Conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await _api.get('/api/chat/conversations');
      return response.data is List
          ? List<Map<String, dynamic>>.from(response.data)
          : [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getConversationInfo(int conversationId) async {
    try {
      final response =
          await _api.get('/api/chat/conversations/$conversationId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Messages
  Future<List<Map<String, dynamic>>> getMessages(int conversationId,
      {int page = 1}) async {
    try {
      final response = await _api.get(
        '/api/chat/messages/$conversationId',
        queryParameters: {'page': page},
      );
      return response.data is List
          ? List<Map<String, dynamic>>.from(response.data)
          : [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> sendMessage({
    required int receiverId,
    required String message,
    String messageType = 'text',
    String? mediaUrl,
    int? replyToId,
  }) async {
    try {
      final data = {
        'receiverId': receiverId,
        'message': message,
        'messageType': messageType,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (replyToId != null) 'replyToId': replyToId,
      };
      await _api.post('/api/chat/messages', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _api.delete('/api/chat/messages/$messageId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> reportMessage(int messageId, String reason) async {
    try {
      await _api.post('/api/chat/messages/report', data: {
        'messageId': messageId,
        'reason': reason,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAsRead(int conversationId) async {
    try {
      await _api.post('/api/chat/messages/$conversationId/read');
    } on DioException catch (e) {
      // Silently fail - non-critical
      print('Mark as read error: $e');
    }
  }

  // Typing indicator
  Future<void> setTyping(int conversationId, bool isTyping) async {
    try {
      await _api.post('/api/chat/typing', data: {
        'conversationId': conversationId,
        'isTyping': isTyping,
      });
    } on DioException catch (e) {
      // Silently fail - non-critical
      print('Typing error: $e');
    }
  }

  // Settings
  Future<Map<String, dynamic>> getChatSettings(int conversationId) async {
    try {
      final response = await _api.get('/api/chat/settings/$conversationId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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
      if (notificationSound != null)
        data['notificationSound'] = notificationSound;
      await _api.put('/api/chat/settings/$conversationId', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await _api.get('/api/chat/preferences');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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
      if (notificationSound != null)
        data['notificationSound'] = notificationSound;
      if (fontSize != null) data['fontSize'] = fontSize;
      if (enterToSend != null) data['enterToSend'] = enterToSend;
      if (readReceipts != null) data['readReceipts'] = readReceipts;
      if (typingIndicators != null) data['typingIndicators'] = typingIndicators;
      if (messagePreview != null) data['messagePreview'] = messagePreview;
      if (autoDownloadMedia != null)
        data['autoDownloadMedia'] = autoDownloadMedia;
      await _api.put('/api/chat/preferences', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // User actions
  Future<void> blockUser(int userId) async {
    try {
      await _api.post('/api/chat/block', data: {'userIdToBlock': userId});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unblockUser(int userId) async {
    try {
      await _api.delete('/api/chat/block/$userId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> clearChat(int conversationId) async {
    try {
      await _api.delete('/api/chat/clear/$conversationId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    final data = e.response?.data;

    // Remove these prints in production
    // print('ERROR DETAILS:');
    // print('  Status: ${e.response?.statusCode}');
    // print('  Data: $data');

    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }

    if (e.response?.statusCode == 401) {
      return 'Authentication failed. Please login again.';
    }
    if (e.response?.statusCode == 403) {
      return 'You are blocked from sending messages.';
    }
    if (e.response?.statusCode == 404) {
      return 'Conversation not found.';
    }
    if (e.response?.statusCode == 500) {
      return 'Server error. Please try again later.';
    }

    return 'Something went wrong';
  }
}
