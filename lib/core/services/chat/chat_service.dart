import 'dart:async';

import 'package:dio/dio.dart';
import 'package:clique/core/local_cache/hive_cache_keys.dart';
import 'package:clique/core/local_cache/local_cache_service.dart';
import 'package:clique/core/services/chat/stream_chat_service.dart';
import 'package:stream_chat/stream_chat.dart' as stream;
import '../../clients/api_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  ChatService._internal();

  final ApiService _api = ApiService();
  final StreamChatService _streamChatService = StreamChatService.instance;
  final Map<String, List<Map<String, dynamic>>> _messagesCache = {};
  final Map<String, CancelToken> _cancelTokens = {};
  final Set<String> _sendingMessageKeys = {};
  Timer? _pendingRetryTimer;
  bool _isRetryingPendingMessages = false;

  void setAuthToken(String token) {
    _api.setAuthToken(token);
    _startPendingRetryLoop();
    unawaited(_streamChatService.connect().catchError((_) {}));
  }

  Future<void> ensureStreamConnected() {
    return _streamChatService.ensureConnected();
  }

  Stream<stream.Event> get streamEvents => _streamChatService.events;

  void clearAuthToken() {
    _api.clearAuthToken();
    _messagesCache.clear();
    _cancelTokens.clear();
    _sendingMessageKeys.clear();
    _stopPendingRetryLoop();
    unawaited(_streamChatService.disconnect());
  }

  List<Map<String, dynamic>> readCachedConversations({
    int? cacheOwnerId,
  }) {
    final keysToCheck = <String>[
      _conversationsKey(cacheOwnerId: cacheOwnerId),
      if (cacheOwnerId != null) _conversationsKey(cacheOwnerId: null),
    ];

    for (final key in keysToCheck) {
      final cachedInMemory = _messagesCache[key];
      if (cachedInMemory != null && cachedInMemory.isNotEmpty) {
        return List<Map<String, dynamic>>.from(cachedInMemory);
      }
    }

    final box = LocalCacheService.box(HiveCacheKeys.chatBox);
    for (final key in keysToCheck) {
      final raw = box?.get(key);
      if (raw is! List) continue;

      final conversations = raw
          .whereType<Map>()
          .map((conversation) => Map<String, dynamic>.from(conversation))
          .toList();

      if (conversations.isNotEmpty) {
        _messagesCache[key] = List<Map<String, dynamic>>.from(conversations);
        return conversations;
      }
    }

    return <Map<String, dynamic>>[];
  }

  Future<void> cacheConversations(
    List<Map<String, dynamic>> conversations, {
    int? cacheOwnerId,
  }) async {
    final key = _conversationsKey(cacheOwnerId: cacheOwnerId);
    final normalized = conversations
        .map((conversation) => Map<String, dynamic>.from(conversation))
        .toList();
    _messagesCache[key] = normalized;

    final box = LocalCacheService.box(HiveCacheKeys.chatBox);
    await box?.put(key, normalized);
  }

  Future<void> clearCachedConversations({int? cacheOwnerId}) async {
    final keysToRemove = <String>[
      _conversationsKey(cacheOwnerId: cacheOwnerId),
      if (cacheOwnerId != null) _conversationsKey(cacheOwnerId: null),
    ];

    for (final key in keysToRemove) {
      _messagesCache.remove(key);
    }

    final box = LocalCacheService.box(HiveCacheKeys.chatBox);
    for (final key in keysToRemove) {
      await box?.delete(key);
    }
  }

  List<Map<String, dynamic>> readCachedMessages(
    int conversationId, {
    int? cacheOwnerId,
  }) {
    final keysToCheck = <String>[
      _messagesKey(
        conversationId,
        cacheOwnerId: cacheOwnerId,
      ),
      if (cacheOwnerId != null)
        _messagesKey(
          conversationId,
          cacheOwnerId: null,
        ),
    ];

    for (final memoryKey in keysToCheck) {
      final cachedInMemory = _messagesCache[memoryKey];
      if (cachedInMemory != null && cachedInMemory.isNotEmpty) {
        return List<Map<String, dynamic>>.from(cachedInMemory);
      }
    }

    final box = LocalCacheService.box(HiveCacheKeys.chatBox);
    for (final key in keysToCheck) {
      final raw = box?.get(key);

      if (raw is! List) {
        continue;
      }

      final messages = raw
          .whereType<Map>()
          .map((message) => Map<String, dynamic>.from(message))
          .toList();

      if (messages.isNotEmpty) {
        _messagesCache[key] = List<Map<String, dynamic>>.from(messages);
        return messages;
      }
    }

    return <Map<String, dynamic>>[];
  }

  Future<void> cacheMessages(
    int conversationId,
    List<Map<String, dynamic>> messages, {
    int? cacheOwnerId,
  }) async {
    final key = _messagesKey(
      conversationId,
      cacheOwnerId: cacheOwnerId,
    );
    final normalized =
        messages.map((message) => Map<String, dynamic>.from(message)).toList();
    _messagesCache[key] = normalized;

    final box = LocalCacheService.box(HiveCacheKeys.chatBox);
    await box?.put(key, normalized);
  }

  Future<void> clearCachedMessages(
    int conversationId, {
    int? cacheOwnerId,
  }) async {
    final keysToRemove = <String>[
      _messagesKey(
        conversationId,
        cacheOwnerId: cacheOwnerId,
      ),
      if (cacheOwnerId != null)
        _messagesKey(
          conversationId,
          cacheOwnerId: null,
        ),
    ];

    for (final key in keysToRemove) {
      _messagesCache.remove(key);
    }

    final box = LocalCacheService.box(HiveCacheKeys.chatBox);
    for (final key in keysToRemove) {
      await box?.delete(key);
    }
  }

  String? readCachedDraft(
    int conversationId, {
    int? cacheOwnerId,
  }) {
    final box = LocalCacheService.box(HiveCacheKeys.chatBox);
    final keysToCheck = <String>[
      _draftKey(
        conversationId,
        cacheOwnerId: cacheOwnerId,
      ),
      if (cacheOwnerId != null)
        _draftKey(
          conversationId,
          cacheOwnerId: null,
        ),
    ];

    for (final key in keysToCheck) {
      final value = box?.get(key);
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  Future<void> saveDraft(
    int conversationId,
    String draft, {
    int? cacheOwnerId,
  }) async {
    final box = LocalCacheService.box(HiveCacheKeys.chatBox);
    final key = _draftKey(
      conversationId,
      cacheOwnerId: cacheOwnerId,
    );

    if (draft.trim().isEmpty) {
      await box?.delete(key);
      return;
    }

    await box?.put(key, draft);
  }

  Future<void> clearDraft(
    int conversationId, {
    int? cacheOwnerId,
  }) async {
    final box = LocalCacheService.box(HiveCacheKeys.chatBox);
    final keysToRemove = <String>[
      _draftKey(
        conversationId,
        cacheOwnerId: cacheOwnerId,
      ),
      if (cacheOwnerId != null)
        _draftKey(
          conversationId,
          cacheOwnerId: null,
        ),
    ];
    for (final key in keysToRemove) {
      await box?.delete(key);
    }
  }

  CancelToken _createCancelToken(String key) {
    _cancelTokens[key]?.cancel();

    final token = CancelToken();

    _cancelTokens[key] = token;

    return token;
  }

  void clearMessagesCache(int conversationId) {
    _messagesCache.removeWhere(
      (key, _) =>
          key.startsWith('${HiveCacheKeys.chatMessagesPrefix}_') &&
          key.endsWith('_$conversationId'),
    );
  }

  void clearAllCache() {
    _messagesCache.clear();
  }

  void _startPendingRetryLoop() {
    if (_pendingRetryTimer != null) {
      return;
    }

    _pendingRetryTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => unawaited(_retryPendingMessages()),
    );
  }

  void _stopPendingRetryLoop() {
    _pendingRetryTimer?.cancel();
    _pendingRetryTimer = null;
  }

  Future<void> _retryPendingMessages() async {
    if (_isRetryingPendingMessages) {
      return;
    }

    _isRetryingPendingMessages = true;

    try {
      final box = LocalCacheService.box(HiveCacheKeys.chatBox);
      if (box == null) {
        return;
      }

      final keys = box.keys.whereType<String>().where(
            (key) => key.startsWith('${HiveCacheKeys.chatMessagesPrefix}_'),
          );

      for (final key in keys) {
        final raw = box.get(key);
        if (raw is! List) continue;

        final messages = raw
            .whereType<Map>()
            .map((message) => Map<String, dynamic>.from(message))
            .toList();
        if (messages.isEmpty) continue;

        final pendingMessages = messages.where(_isPendingMessage).toList()
          ..sort((a, b) {
            final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return aTime.compareTo(bTime);
          });

        if (pendingMessages.isEmpty) continue;

        var updatedMessages = List<Map<String, dynamic>>.from(messages);
        var didUpdate = false;

        for (final pending in pendingMessages) {
          final pendingKey = _messageKey(
            receiverId:
                _readInt(pending['receiverId'] ?? pending['receiver_id']),
            message: (pending['message'] ?? '').toString(),
            messageType:
                (pending['messageType'] ?? pending['message_type'] ?? 'text')
                    .toString(),
            mediaUrl: pending['mediaUrl'] ?? pending['media_url'],
            replyToId: pending['replyToId'] ?? pending['reply_to_id'],
          );

          if (_sendingMessageKeys.contains(pendingKey)) {
            continue;
          }

          final delivered = await _sendPendingMessage(pending);
          if (delivered == null) {
            continue;
          }

          updatedMessages = _replacePendingMessage(
            updatedMessages,
            pending,
            delivered,
          );
          didUpdate = true;
        }

        if (didUpdate) {
          _messagesCache[key] =
              List<Map<String, dynamic>>.from(updatedMessages);
          await box.put(key, updatedMessages);
        }
      }
    } catch (_) {
      // Keep retrying in the background.
    } finally {
      _isRetryingPendingMessages = false;
    }
  }

  Future<Map<String, dynamic>?> _sendPendingMessage(
    Map<String, dynamic> pending,
  ) async {
    final receiverId =
        _readInt(pending['receiverId'] ?? pending['receiver_id']);
    final message = (pending['message'] ?? '').toString().trim();
    final messageType =
        (pending['messageType'] ?? pending['message_type'] ?? 'text')
            .toString();
    final mediaUrl = pending['mediaUrl'] ?? pending['media_url'];
    final replyToId = pending['replyToId'] ?? pending['reply_to_id'];

    if (receiverId <= 0 || message.isEmpty) {
      return null;
    }

    final key = _messageKey(
      receiverId: receiverId,
      message: message,
      messageType: messageType,
      mediaUrl: mediaUrl,
      replyToId: replyToId,
    );

    if (_sendingMessageKeys.contains(key)) {
      return null;
    }

    _sendingMessageKeys.add(key);

    try {
      final payload = <String, dynamic>{
        'receiverId': receiverId,
        'message': message,
        'messageType': messageType,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (replyToId != null) 'replyToId': replyToId,
      };

      final response = await _api.post(
        '/api/chat/messages',
        data: payload,
      );

      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } on DioException {
      return null;
    } finally {
      _sendingMessageKeys.remove(key);
    }
  }

  List<Map<String, dynamic>> _replacePendingMessage(
    List<Map<String, dynamic>> messages,
    Map<String, dynamic> pending,
    Map<String, dynamic> delivered,
  ) {
    final pendingId = pending['id'];
    return messages.map((message) {
      if (message['id'] == pendingId) {
        final merged = Map<String, dynamic>.from(delivered);
        merged['conversationId'] =
            merged['conversationId'] ?? merged['conversation_id'];
        merged['isOwn'] = true;
        return merged;
      }
      return message;
    }).toList();
  }

  bool _isPendingMessage(Map<String, dynamic> message) {
    final id = _readInt(message['id']);
    return id < 0 || id.toString().startsWith('999');
  }

  String _messageKey({
    required int receiverId,
    required String message,
    required String messageType,
    String? mediaUrl,
    int? replyToId,
  }) {
    return [
      receiverId,
      message.trim(),
      messageType.trim().toLowerCase(),
      mediaUrl?.trim() ?? '',
      replyToId?.toString() ?? '',
    ].join('|');
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<List<Map<String, dynamic>>> _loadStreamMessages(
    int conversationId,
  ) async {
    final state = await _streamChatService.watchChannel(conversationId);
    return _mapStreamMessages(
      state.messages ?? const <stream.Message>[],
      conversationId,
      receiverId: _peerUserIdFromState(state),
    );
  }

  Future<List<Map<String, dynamic>>> _loadStreamMessagesPage(
    int conversationId, {
    required int page,
  }) async {
    final state = await _streamChatService.queryChannelMessages(
      conversationId,
      page: page,
    );
    return _mapStreamMessages(
      state.messages ?? const <stream.Message>[],
      conversationId,
      receiverId: _peerUserIdFromState(state),
    );
  }

  Future<Map<String, dynamic>?> _sendStreamMessage({
    required int conversationId,
    required int receiverId,
    required String message,
    required String messageType,
    String? mediaUrl,
    String? replyToStreamMessageId,
  }) async {
    try {
      final channel = _streamChatService.channelForConversation(
        conversationId,
        receiverId: receiverId,
      );
      await channel.watch(presence: true);

      final attachments = <stream.Attachment>[];
      if (mediaUrl != null && mediaUrl.trim().isNotEmpty) {
        attachments.add(
          stream.Attachment(
            type: messageType,
            assetUrl: mediaUrl,
            imageUrl: messageType == 'image' ? mediaUrl : null,
            thumbUrl: messageType == 'video' ? mediaUrl : null,
          ),
        );
      }

      final response = await channel.sendMessage(
        stream.Message(
          text: message,
          parentId: replyToStreamMessageId,
          attachments: attachments,
        ),
      );

      return _streamMessageToJson(
        response.message,
        conversationId: conversationId,
        receiverId: receiverId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _deleteStreamMessage(int messageId) async {
    final resolved = await _findStreamMessageByLocalId(messageId);
    final channel = resolved.$1;
    final message = resolved.$2;
    if (channel == null || message == null) return false;

    try {
      await channel.deleteMessage(message, hard: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _flagStreamMessage(int messageId) async {
    final message = await _findStreamMessageByLocalId(messageId);
    if (message.$2 == null) return false;

    try {
      await _streamChatService.client.flagMessage(message.$2!.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<(stream.Channel?, stream.Message?)> _findStreamMessageByLocalId(
    int messageId,
  ) async {
    for (final channel in _streamChatService.client.state.channels.values) {
      final messages = channel.state?.messages ?? const <stream.Message>[];
      for (final message in messages) {
        if (message.id.hashCode == messageId ||
            message.id == messageId.toString()) {
          return (channel, message);
        }
      }
    }
    return (null, null);
  }

  List<Map<String, dynamic>> _mapStreamMessages(
      List<stream.Message> messages, int conversationId,
      {int? receiverId}) {
    final currentUserId = _streamChatService.currentUserId;
    final currentUserIdInt = _streamChatService.currentUserIdAsInt();
    final peerId = receiverId ?? 0;

    final mapped = messages.map((message) {
      final senderId = _readInt(message.user?.id);
      final replyParentId = _readInt(message.parentId) != 0
          ? _readInt(message.parentId)
          : (message.parentId != null
              ? _stableMessageId(message.parentId!)
              : 0);
      final mediaUrl = _readStreamMediaUrl(message);
      final messageType = _readStreamMessageType(message, mediaUrl);
      final isOwn = currentUserId != null && message.user?.id == currentUserId;

      return <String, dynamic>{
        'id': _stableMessageId(message.id),
        'streamMessageId': message.id,
        'conversationId': conversationId,
        'senderId': senderId,
        'receiverId': senderId == currentUserIdInt ? peerId : currentUserIdInt,
        'message': message.text ?? '',
        'messageType': messageType,
        'mediaUrl': mediaUrl,
        'replyToId': replyParentId > 0 ? replyParentId : null,
        'replyToMessage': message.quotedMessage?.text,
        'replyToSender': message.quotedMessage?.user?.name,
        'isRead': true,
        'isOwn': isOwn,
        'createdAt': message.createdAt.toIso8601String(),
      };
    }).toList();

    mapped.sort((a, b) {
      final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return mapped;
  }

  int _peerUserIdFromState(stream.ChannelState state) {
    final currentUserId = _streamChatService.currentUserId;
    final currentUserIdInt = _streamChatService.currentUserIdAsInt();

    for (final member in state.members ?? const <stream.Member>[]) {
      final memberUser = member.user;
      if (memberUser == null) {
        continue;
      }
      final userId = _readInt(memberUser.id);
      if (currentUserId != null && memberUser.id == currentUserId) {
        continue;
      }
      if (userId != 0 && userId != currentUserIdInt) {
        return userId;
      }
    }

    return 0;
  }

  Map<String, dynamic> _streamMessageToJson(
    stream.Message message, {
    required int conversationId,
    required int receiverId,
  }) {
    final senderId = _readInt(message.user?.id);
    final mediaUrl = _readStreamMediaUrl(message);
    final messageType = _readStreamMessageType(message, mediaUrl);
    final isOwn = message.user?.id == _streamChatService.currentUserId;

    return <String, dynamic>{
      'id': _stableMessageId(message.id),
      'streamMessageId': message.id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message.text ?? '',
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'replyToId': _readInt(message.parentId) != 0
          ? _readInt(message.parentId)
          : (message.parentId != null
              ? _stableMessageId(message.parentId!)
              : 0),
      'replyToMessage': message.quotedMessage?.text,
      'replyToSender': message.quotedMessage?.user?.name,
      'isRead': true,
      'isOwn': isOwn,
      'createdAt': message.createdAt.toIso8601String(),
    };
  }

  int _stableMessageId(String id) {
    if (id.isEmpty) return 0;
    return id.hashCode;
  }

  String _readStreamMessageType(stream.Message message, String? mediaUrl) {
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      final attachmentType = message.attachments.isNotEmpty
          ? message.attachments.first.type
          : null;
      return attachmentType ?? 'image';
    }
    return 'text';
  }

  String? _readStreamMediaUrl(stream.Message message) {
    if (message.attachments.isEmpty) return null;

    final attachment = message.attachments.first;
    return attachment.assetUrl ??
        attachment.imageUrl ??
        attachment.thumbUrl ??
        attachment.titleLink;
  }

  // =========================
  // Conversations
  // =========================

  Future<List<Map<String, dynamic>>> getConversations({
    bool forceRefresh = false,
    int? cacheOwnerId,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = readCachedConversations(
          cacheOwnerId: cacheOwnerId,
        );
        if (cached.isNotEmpty) {
          return cached;
        }
      }

      try {
        await _streamChatService.connect();
        final streamConversations = await _loadStreamConversations(
          cacheOwnerId: cacheOwnerId,
        );
        if (streamConversations.isNotEmpty) {
          await cacheConversations(
            streamConversations,
            cacheOwnerId: cacheOwnerId,
          );
          return streamConversations;
        }
      } catch (_) {
        // Fall through to the existing REST path.
      }

      final response = await _api.get(
        '/api/chat/conversations',
        forceRefresh: true,
        useCache: false,
      );

      final conversations = response.data is List
          ? (response.data as List)
              .whereType<Map>()
              .map((conversation) => Map<String, dynamic>.from(conversation))
              .toList()
          : <Map<String, dynamic>>[];

      if (conversations.isNotEmpty) {
        await cacheConversations(
          conversations,
          cacheOwnerId: cacheOwnerId,
        );
      }

      return conversations;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> _loadStreamConversations({
    int? cacheOwnerId,
  }) async {
    final currentUserId = _streamChatService.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final channels = await _streamChatService.client.queryChannelsOnline(
      filter: stream.Filter.and([
        stream.Filter.equal('type', 'messaging'),
        stream.Filter.contains('members', currentUserId),
      ]),
      sort: [
        stream.SortOption<stream.ChannelState>.desc('last_message_at'),
      ],
      state: true,
      watch: true,
      presence: true,
      messageLimit: 1,
    );

    final conversations = channels.map((channel) {
      final state = channel.state;
      final members = state?.members ?? const <stream.Member>[];
      final peer = _findPeerMember(members, currentUserId);
      final messages = state?.messages;
      final latestMessage =
          messages != null && messages.isNotEmpty ? messages.last : null;
      final unreadCount = (state?.read ?? const <stream.Read>[])
              .userReadOf(
                userId: currentUserId,
              )
              ?.unreadMessages ??
          0;
      final lastMessage = latestMessage?.text ?? '';
      final lastMessageAt = channel.lastMessageAt ??
          latestMessage?.createdAt ??
          channel.createdAt ??
          DateTime.now();

      return <String, dynamic>{
        'id': _readInt(channel.id),
        'userId': _readInt(peer?.user?.id),
        'name': _readStreamConversationName(peer),
        'username': _readStreamConversationUsername(peer),
        'avatar': peer?.user?.image ?? '',
        'age': 0,
        'verified': peer?.user?.extraData['verified'] == true,
        'lastMessage': lastMessage,
        'lastMessageType': latestMessage != null
            ? _readStreamMessageType(
                latestMessage, _readStreamMediaUrl(latestMessage))
            : 'text',
        'timestamp': lastMessageAt.toIso8601String(),
        'unreadCount': unreadCount,
        'isOnline': peer?.user?.online ?? false,
        'isTyping': false,
        'isPinned': channel.isPinned,
        'isMuted': channel.isMuted,
        'muteUntil': null,
        'conversationId': _readInt(channel.id),
        'channelId': channel.id,
        'lastMessageId': latestMessage?.id,
        'lastMessageCreatedAt': latestMessage?.createdAt.toIso8601String(),
        'cacheOwnerId': cacheOwnerId,
      };
    }).toList();

    conversations.sort((a, b) {
      if ((a['isPinned'] == true) && (b['isPinned'] != true)) return -1;
      if ((a['isPinned'] != true) && (b['isPinned'] == true)) return 1;
      final aTime = DateTime.tryParse(a['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return conversations;
  }

  stream.Member? _findPeerMember(
    List<stream.Member> members,
    String currentUserId,
  ) {
    for (final member in members) {
      final memberUser = member.user;
      if (memberUser == null || memberUser.id == currentUserId) {
        continue;
      }
      return member;
    }
    return members.isNotEmpty ? members.first : null;
  }

  String _readStreamConversationName(stream.Member? peer) {
    final user = peer?.user;
    if (user == null) return 'User';
    final name = user.name.trim();
    if (name.isNotEmpty) return name;
    final username = _readStreamConversationUsername(peer).trim();
    if (username.isNotEmpty) return username;
    return user.id;
  }

  String _readStreamConversationUsername(stream.Member? peer) {
    final user = peer?.user;
    if (user == null) return '';

    final extraUsername = user.extraData['username'];
    if (extraUsername is String && extraUsername.trim().isNotEmpty) {
      return extraUsername.trim();
    }

    final extraHandle = user.extraData['handle'];
    if (extraHandle is String && extraHandle.trim().isNotEmpty) {
      return extraHandle.trim();
    }

    return '';
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

  Future<Map<String, dynamic>> startConversation({
    required int receiverId,
  }) async {
    try {
      final response = await _api.post(
        '/api/chat/conversations',
        data: {
          'receiverId': receiverId,
          'forceNew': true,
          'conversationMode': 'direct',
        },
      );

      _api.removeCacheByPath('/api/chat');

      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }

      return {};
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
    bool silent = false,
    int? cacheOwnerId,
  }) async {
    try {
      final memoryKey = _messagesKey(
        conversationId,
        cacheOwnerId: cacheOwnerId,
      );

      if (!forceRefresh && page == 1 && _messagesCache.containsKey(memoryKey)) {
        return _messagesCache[memoryKey]!;
      }

      try {
        await _streamChatService.connect();
        final streamMessages = page == 1
            ? await _loadStreamMessages(conversationId)
            : await _loadStreamMessagesPage(
                conversationId,
                page: page,
              );

        if (streamMessages.isNotEmpty) {
          if (page == 1) {
            _messagesCache[memoryKey] = streamMessages;
          }
          return streamMessages;
        }
      } catch (_) {
        // Fall through to the existing REST path.
      }

      if (!forceRefresh && page == 1) {
        final cachedMessages = readCachedMessages(
          conversationId,
          cacheOwnerId: cacheOwnerId,
        );
        if (cachedMessages.isNotEmpty) {
          return cachedMessages;
        }
      }

      final response = await _api.get(
        '/api/chat/messages/$conversationId',
        queryParameters: {
          'page': page,
        },
        forceRefresh: forceRefresh,
        useCache: false,
        cancelToken: silent
            ? null
            : _createCancelToken(
                'messages_$conversationId',
              ),
      );

      final messages = response.data is List
          ? List<Map<String, dynamic>>.from(response.data)
          : <Map<String, dynamic>>[];

      if (page == 1) {
        _messagesCache[memoryKey] = messages;
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
    int? conversationId,
    required int receiverId,
    required String message,
    String messageType = 'text',
    String? mediaUrl,
    int? replyToId,
    String? replyToStreamMessageId,
  }) async {
    final key = _messageKey(
      receiverId: receiverId,
      message: message,
      messageType: messageType,
      mediaUrl: mediaUrl,
      replyToId: replyToId,
    );

    if (_sendingMessageKeys.contains(key)) {
      return null;
    }

    _sendingMessageKeys.add(key);

    try {
      try {
        await _streamChatService.connect();
        final streamResponse = await _sendStreamMessage(
          conversationId: conversationId ?? receiverId,
          receiverId: receiverId,
          message: message,
          messageType: messageType,
          mediaUrl: mediaUrl,
          replyToStreamMessageId: replyToStreamMessageId,
        );

        if (streamResponse != null) {
          clearAllCache();
          _api.removeCacheByPath('/api/chat');
          return streamResponse;
        }
      } catch (_) {
        // Fall through to the existing REST path.
      }

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
    } finally {
      _sendingMessageKeys.remove(key);
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

  String _conversationsKey({int? cacheOwnerId}) {
    return cacheOwnerId == null
        ? HiveCacheKeys.chatConversationsPrefix
        : '${HiveCacheKeys.chatConversationsPrefix}_$cacheOwnerId';
  }

  String _messagesKey(
    int conversationId, {
    int? cacheOwnerId,
  }) {
    return cacheOwnerId == null
        ? '${HiveCacheKeys.chatMessagesPrefix}_$conversationId'
        : '${HiveCacheKeys.chatMessagesPrefix}_${cacheOwnerId}_$conversationId';
  }

  String _draftKey(
    int conversationId, {
    int? cacheOwnerId,
  }) {
    return cacheOwnerId == null
        ? '${HiveCacheKeys.chatDraftPrefix}_$conversationId'
        : '${HiveCacheKeys.chatDraftPrefix}_${cacheOwnerId}_$conversationId';
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
      try {
        await _streamChatService.connect();
        final deleted = await _deleteStreamMessage(messageId);
        if (deleted) {
          clearAllCache();
          _api.removeCacheByPath('/api/chat');
          return;
        }
      } catch (_) {
        // Fall through to REST.
      }

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
      try {
        await _streamChatService.connect();
        final flagged = await _flagStreamMessage(messageId);
        if (flagged) {
          return;
        }
      } catch (_) {
        // Fall through to REST.
      }

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
      await _streamChatService.connect();
      await _streamChatService
          .channelForConversation(conversationId)
          .markRead();
      return;
    } catch (_) {}

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
      await _streamChatService.connect();
      final channel = _streamChatService.channelForConversation(conversationId);
      if (isTyping) {
        await channel.startTyping();
      } else {
        await channel.stopTyping();
      }
      return;
    } catch (_) {}

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
