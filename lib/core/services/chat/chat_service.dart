import 'package:dio/dio.dart';
import 'package:clique/core/local_cache/hive_cache_keys.dart';
import 'package:clique/core/local_cache/local_cache_service.dart';
import '../../clients/api_service.dart';

class ChatService {
  final ApiService _api = ApiService();
  final Map<int, List<Map<String, dynamic>>> _messagesCache = {};
  final Map<String, CancelToken> _cancelTokens = {};

  void setAuthToken(String token) {
    _api.setAuthToken(token);
  }

  void clearAuthToken() {
    _api.clearAuthToken();
    _messagesCache.clear();
    _cancelTokens.clear();
  }

  CancelToken _createCancelToken(String key) {
    _cancelTokens[key]?.cancel();

    final token = CancelToken();

    _cancelTokens[key] = token;

    return token;
  }

  void clearMessagesCache(int conversationId) {
    _messagesCache.remove(conversationId);
  }

  void clearAllCache() {
    _messagesCache.clear();
  }

  // =========================
  // Conversations
  // =========================

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await _api.get(
        '/api/chat/conversations',
        forceRefresh: true,
        useCache: false,
      );

      return response.data is List
          ? List<Map<String, dynamic>>.from(response.data)
          : [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getConversationInfo(
    int conversationId,
  ) async {
    try {
      final response = await _api.get(
        '/api/chat/conversations/$conversationId',
        forceRefresh: true,
        useCache: false,
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // =========================
  // Messages
  // =========================

  Future<List<Map<String, dynamic>>> getMessages(
    int conversationId, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh &&
          page == 1 &&
          _messagesCache.containsKey(conversationId)) {
        return _messagesCache[conversationId]!;
      }

      final response = await _api.get(
        '/api/chat/messages/$conversationId',
        queryParameters: {
          'page': page,
        },
        forceRefresh: forceRefresh,
        useCache: false,
        cancelToken: _createCancelToken(
          'messages_$conversationId',
        ),
      );

      final messages = response.data is List
          ? List<Map<String, dynamic>>.from(response.data)
          : <Map<String, dynamic>>[];

      if (page == 1) {
        _messagesCache[conversationId] = messages;
      }

      return messages;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return [];
      }

      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>?> sendMessage({
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

      final response = await _api.post(
        '/api/chat/messages',
        data: data,
      );

      clearAllCache();
      _api.removeCacheByPath('/api/chat');

      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }

      return null;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCliqueBotMessages(
    int conversationId,
  ) async {
    final box = LocalCacheService.box(HiveCacheKeys.chatBox);
    final raw = box?.get(_cliqueBotKey(conversationId));
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((message) => Map<String, dynamic>.from(message))
        .toList();
  }

  Future<List<Map<String, dynamic>>> ensureCliqueBotWelcome({
    required int conversationId,
    required int currentUserId,
  }) async {
    final saved = await getCliqueBotMessages(conversationId);
    if (saved.isNotEmpty) return saved;

    final box = LocalCacheService.box(HiveCacheKeys.chatBox);
    final now = DateTime.now();
    final welcome = {
      'id': now.microsecondsSinceEpoch,
      'conversationId': conversationId,
      'senderId': 0,
      'receiverId': currentUserId,
      'message':
          'Welcome to Clique. I am always here when you need a quick chat.',
      'messageType': 'text',
      'isRead': true,
      'isOwn': false,
      'createdAt': now.toIso8601String(),
    };
    final updated = [welcome];
    await box?.put(_cliqueBotKey(conversationId), updated);
    return updated;
  }

  Future<List<Map<String, dynamic>>> saveCliqueBotExchange({
    required int conversationId,
    required int currentUserId,
    required String message,
    int? replyToId,
    String? replyToMessage,
    String? replyToSender,
  }) async {
    final box = LocalCacheService.box(HiveCacheKeys.chatBox);
    final saved = await getCliqueBotMessages(conversationId);
    final now = DateTime.now();
    final userMessage = {
      'id': now.microsecondsSinceEpoch,
      'conversationId': conversationId,
      'senderId': currentUserId,
      'receiverId': 0,
      'message': message,
      'messageType': 'text',
      'replyToId': replyToId,
      'replyToMessage': replyToMessage,
      'replyToSender': replyToSender,
      'isRead': true,
      'isOwn': true,
      'createdAt': now.toIso8601String(),
    };
    final botMessage = {
      'id': now.microsecondsSinceEpoch + 1,
      'conversationId': conversationId,
      'senderId': 0,
      'receiverId': currentUserId,
      'message': _buildCliqueReply(message),
      'messageType': 'text',
      'isRead': true,
      'isOwn': false,
      'createdAt': now.add(const Duration(milliseconds: 450)).toIso8601String(),
    };
    final updated = [
      userMessage,
      botMessage,
      ...saved,
    ];

    await box?.put(_cliqueBotKey(conversationId), updated);
    return updated;
  }

  String _cliqueBotKey(int conversationId) {
    return '${HiveCacheKeys.cliqueBotMessagesPrefix}_$conversationId';
  }

  String _buildCliqueReply(String input) {
    final text = input.trim().toLowerCase();
    if (text.contains('hello') || text.contains('hi') || text.contains('hey')) {
      return 'Hey, I am Clique. I can keep you company here and help you get started.';
    }
    if (text.contains('match') || text.contains('profile')) {
      return 'I can help you tune your profile. Try adding a clear photo and a short prompt that makes replies easy.';
    }
    if (text.contains('help') || text.contains('support')) {
      return 'I am here. Tell me what is stuck and I will point you in the right direction.';
    }
    if (text.contains('thanks') || text.contains('thank you')) {
      return 'Anytime. I will keep this chat saved so you can come back to it.';
    }
    return 'Got it. I saved this here and I am listening.';
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _api.delete(
        '/api/chat/messages/$messageId',
      );
      clearAllCache();
      _api.removeCacheByPath('/api/chat');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> reportMessage(
    int messageId,
    String reason,
  ) async {
    try {
      await _api.post(
        '/api/chat/messages/report',
        data: {
          'messageId': messageId,
          'reason': reason,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAsRead(int conversationId) async {
    try {
      await _api.post(
        '/api/chat/messages/$conversationId/read',
      );
    } catch (_) {}
  }

  // =========================
  // Typing
  // =========================

  Future<void> setTyping(
    int conversationId,
    bool isTyping,
  ) async {
    try {
      await _api.post(
        '/api/chat/typing',
        data: {
          'conversationId': conversationId,
          'isTyping': isTyping,
        },
        cancelToken: _createCancelToken(
          'typing_$conversationId',
        ),
      );
    } catch (_) {}
  }

  // =========================
  // Settings
  // =========================

  Future<Map<String, dynamic>> getChatSettings(
    int conversationId,
  ) async {
    try {
      final response = await _api.get(
        '/api/chat/settings/$conversationId',
        forceRefresh: true,
        useCache: false,
      );

      return Map<String, dynamic>.from(response.data);
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

      if (muteUntil != null) {
        data['muteUntil'] = muteUntil.toIso8601String();
      }

      if (wallpaper != null) data['wallpaper'] = wallpaper;
      if (chatColor != null) data['chatColor'] = chatColor;

      if (notificationSound != null) {
        data['notificationSound'] = notificationSound;
      }

      await _api.put(
        '/api/chat/settings/$conversationId',
        data: data,
      );
      _api.removeCacheByPath('/api/chat/settings/$conversationId');
      _api.removeCacheByPath('/api/chat/conversations');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // =========================
  // Preferences
  // =========================

  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await _api.get(
        '/api/chat/preferences',
        forceRefresh: true,
        useCache: false,
      );

      return Map<String, dynamic>.from(response.data);
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

      if (notificationSound != null) {
        data['notificationSound'] = notificationSound;
      }

      if (fontSize != null) data['fontSize'] = fontSize;

      if (enterToSend != null) {
        data['enterToSend'] = enterToSend;
      }

      if (readReceipts != null) {
        data['readReceipts'] = readReceipts;
      }

      if (typingIndicators != null) {
        data['typingIndicators'] = typingIndicators;
      }

      if (messagePreview != null) {
        data['messagePreview'] = messagePreview;
      }

      if (autoDownloadMedia != null) {
        data['autoDownloadMedia'] = autoDownloadMedia;
      }

      await _api.put(
        '/api/chat/preferences',
        data: data,
      );
      _api.removeCacheByPath('/api/chat/preferences');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // =========================
  // User Actions
  // =========================

  Future<void> blockUser(int userId) async {
    try {
      await _api.post(
        '/api/chat/block',
        data: {
          'userIdToBlock': userId,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unblockUser(int userId) async {
    try {
      await _api.delete(
        '/api/chat/block/$userId',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> clearChat(int conversationId) async {
    try {
      await _api.delete(
        '/api/chat/clear/$conversationId',
      );

      clearMessagesCache(conversationId);
      _api.removeCacheByPath('/api/chat');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // =========================
  // Errors
  // =========================

  String _handleError(DioException e) {
    final data = e.response?.data;

    if (data is Map) {
      final message = data['message'] ?? data['error'];

      if (message != null) {
        return message.toString();
      }
    }

    switch (e.response?.statusCode) {
      case 400:
        return 'Invalid request';

      case 401:
        return 'Authentication failed';

      case 403:
        return 'Access denied';

      case 404:
        return 'Not found';

      case 422:
        return 'Validation failed';

      case 500:
        return 'Server error';

      case 502:
        return 'Server unavailable';

      default:
        break;
    }

    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    }

    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Receive timeout';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection';
    }

    return 'Something went wrong';
  }
}
