import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/core/services/chat/chat_service.dart';
import 'package:clique/core/services/user/user_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  int? _currentUserId;
  final Map<int, List<MessageModel>> _messageCache = {};
  final Set<int> _loadingConversations = {};
  final Set<String> _inFlightMessageKeys = {};
  int _messageRequestId = 0;

  ChatBloc() : super(const ChatState()) {
    on<LoadConversations>(_onLoadConversations);
    on<RefreshConversations>(_onRefreshConversations);
    on<LoadConversationInfo>(_onLoadConversationInfo);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<LoadCliqueBotMessages>(_onLoadCliqueBotMessages);
    on<SendCliqueBotMessage>(_onSendCliqueBotMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<ReportMessage>(_onReportMessage);
    on<MarkMessagesAsRead>(_onMarkMessagesAsRead);
    on<SetTyping>(_onSetTyping);
    on<LoadChatSettings>(_onLoadChatSettings);
    on<UpdateChatSettings>(_onUpdateChatSettings);
    on<LoadUserPreferences>(_onLoadUserPreferences);
    on<UpdateUserPreferences>(_onUpdateUserPreferences);
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
    on<ClearChat>(_onClearChat);
    on<ClearChatError>(_onClearChatError);
    on<ResetChatState>(_onResetChatState);
    on<RetryPendingMessages>(_onRetryPendingMessages);

    // Real-time events
    on<NewMessageReceived>(_onNewMessageReceived);
    on<MessageReadReceived>(_onMessageReadReceived);
    on<TypingStatusReceived>(_onTypingStatusReceived);
  }

  void setAuthToken(String token) {
    _chatService.setAuthToken(token);
    _userService.setAuthToken(token);
  }

  void clearAuthToken() {
    _chatService.clearAuthToken();
    _userService.clearAuthToken();
  }

  Future<void> _loadCurrentUserId() async {
    if (_currentUserId == null) {
      try {
        final user = await _userService.getCurrentUser();
        _currentUserId = user['id'];
      } catch (_) {}
    }
  }

  String _messageKey({
    required int conversationId,
    required int receiverId,
    required String message,
    required String messageType,
    String? mediaUrl,
    int? replyToId,
  }) {
    return [
      conversationId,
      receiverId,
      message.trim(),
      messageType,
      mediaUrl ?? '',
      replyToId ?? '',
    ].join('|');
  }

  MessageModel _ownMessage(MessageModel message) {
    return message.copyWith(isOwn: message.senderId == _currentUserId);
  }

  Future<List<MessageModel>> _loadPersistedMessages(int conversationId) async {
    final persisted = _chatService.readCachedMessages(
      conversationId,
      cacheOwnerId: _currentUserId,
    );
    if (persisted.isEmpty) {
      return const <MessageModel>[];
    }

    return persisted
        .map((json) => _ownMessage(MessageModel.fromJson(json)))
        .toList();
  }

  Future<void> _persistMessages(
    int conversationId,
    List<MessageModel> messages,
  ) async {
    await _chatService.cacheMessages(
      conversationId,
      messages.map((message) => message.toJson()).toList(),
      cacheOwnerId: _currentUserId,
    );
  }

  Future<List<ConversationModel>> _loadPersistedConversations() async {
    final persisted = _chatService.readCachedConversations(
      cacheOwnerId: _currentUserId,
    );
    if (persisted.isEmpty) {
      return const <ConversationModel>[];
    }

    return persisted.map((json) => ConversationModel.fromJson(json)).toList();
  }

  Future<void> _persistConversations(
    List<ConversationModel> conversations,
  ) async {
    await _chatService.cacheConversations(
      conversations.map((conversation) => conversation.toJson()).toList(),
      cacheOwnerId: _currentUserId,
    );
  }

  List<ConversationModel> _updateConversationPreview(
    List<ConversationModel> conversations, {
    required int conversationId,
    required String lastMessage,
    required String lastMessageType,
    bool incoming = false,
  }) {
    final now = DateTime.now().toIso8601String();
    final updated = conversations.map((conversation) {
      if (conversation.id != conversationId) {
        return conversation;
      }

      return conversation.copyWith(
        lastMessage: lastMessage,
        lastMessageType: lastMessageType,
        timestamp: now,
        unreadCount:
            incoming ? conversation.unreadCount + 1 : conversation.unreadCount,
      );
    }).toList();

    updated.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.timestamp.compareTo(a.timestamp);
    });

    return updated;
  }

  bool _looksLikeSameDelivery(MessageModel pending, MessageModel delivered) {
    if (!pending.isPending || delivered.isPending) return false;
    if (pending.conversationId != delivered.conversationId) return false;
    if (pending.senderId != delivered.senderId) return false;
    if (pending.receiverId != delivered.receiverId) return false;
    if (pending.message != delivered.message) return false;
    if (pending.messageType != delivered.messageType) return false;
    if (pending.mediaUrl != delivered.mediaUrl) return false;
    if (pending.replyToId != delivered.replyToId) return false;

    final ageDelta =
        pending.createdAt.difference(delivered.createdAt).abs().inMinutes;
    return ageDelta <= 5;
  }

  List<MessageModel> _mergeMessages(List<MessageModel> messages) {
    final deliveredById = <int, MessageModel>{};
    final pending = <MessageModel>[];

    for (final message in messages) {
      final processed = _ownMessage(message);
      if (processed.isPending) {
        pending.add(processed);
      } else {
        deliveredById[processed.id] = processed;
      }
    }

    final delivered = deliveredById.values.toList();
    final remainingPending = pending.where((pendingMessage) {
      return !delivered.any(
        (deliveredMessage) =>
            _looksLikeSameDelivery(pendingMessage, deliveredMessage),
      );
    });

    return [
      ...delivered,
      ...remainingPending,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _onLoadConversations(
      LoadConversations event, Emitter<ChatState> emit) async {
    await _loadCurrentUserId();

    try {
      final cachedConversations = state.conversations.isNotEmpty
          ? state.conversations
          : await _loadPersistedConversations();

      if (cachedConversations.isNotEmpty) {
        emit(state.copyWith(
          conversations: cachedConversations,
          conversationsStatus: ChatStatus.success,
          clearError: true,
        ));
      } else if (state.conversations.isEmpty) {
        emit(state.copyWith(conversationsStatus: ChatStatus.loading));
      }

      final data = await _chatService.getConversations(
        cacheOwnerId: _currentUserId,
      );
      final conversations =
          data.map((json) => ConversationModel.fromJson(json)).toList();
      emit(state.copyWith(
        conversations: conversations,
        conversationsStatus: ChatStatus.success,
        clearError: true,
      ));
      await _persistConversations(conversations);
    } catch (e) {
      emit(state.copyWith(
        conversationsStatus: ChatStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshConversations(
      RefreshConversations event, Emitter<ChatState> emit) async {
    await _loadCurrentUserId();
    emit(state.copyWith(conversationsStatus: ChatStatus.refreshing));
    try {
      final data = await _chatService.getConversations(
        forceRefresh: true,
        cacheOwnerId: _currentUserId,
      );
      final conversations =
          data.map((json) => ConversationModel.fromJson(json)).toList();
      emit(state.copyWith(
        conversations: conversations,
        conversationsStatus: ChatStatus.success,
        clearError: true,
      ));
      await _persistConversations(conversations);
    } catch (e) {
      emit(state.copyWith(
        conversationsStatus: ChatStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadConversationInfo(
      LoadConversationInfo event, Emitter<ChatState> emit) async {
    try {
      final data = await _chatService.getConversationInfo(event.conversationId);
      final info = ConversationInfoModel.fromJson(data);
      emit(state.copyWith(conversationInfo: info, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    await _loadCurrentUserId();

    final requestId = ++_messageRequestId;
    final cacheKey = event.conversationId;

    if (_loadingConversations.contains(cacheKey)) {
      return;
    }

    _loadingConversations.add(cacheKey);

    try {
      final inMemoryMessages = _messageCache[cacheKey];
      final cachedMessages =
          inMemoryMessages != null && inMemoryMessages.isNotEmpty
              ? inMemoryMessages
              : await _loadPersistedMessages(cacheKey);

      if (cachedMessages.isNotEmpty) {
        _messageCache[cacheKey] = cachedMessages;
      }

      if (event.page == 1) {
        if (cachedMessages.isNotEmpty) {
          emit(state.copyWith(
            messages: cachedMessages,
            messagesStatus: ChatStatus.success,
            currentPage: 1,
            activeConversationId: event.conversationId,
          ));
        } else if (!event.silent) {
          emit(state.copyWith(
            messages: const [],
            messagesStatus: ChatStatus.loading,
            currentPage: 1,
            activeConversationId: event.conversationId,
          ));
        }
      }

      final shouldForceRefresh =
          event.forceRefresh || event.page > 1 || cachedMessages.isNotEmpty;

      final data = await _chatService.getMessages(
        event.conversationId,
        page: event.page,
        forceRefresh: shouldForceRefresh,
        silent: event.silent,
        cacheOwnerId: _currentUserId,
      );

      final fetchedMessages =
          data.map((json) => MessageModel.fromJson(json)).toList();

      List<MessageModel> updatedMessages = [];

      if (event.page == 1) {
        final optimisticMessages = cachedMessages.where((m) => m.isPending);

        updatedMessages = [
          ...fetchedMessages,
          ...optimisticMessages,
        ];
      } else {
        updatedMessages = [
          ...state.messages,
          ...fetchedMessages,
        ];
      }

      final finalMessages = _mergeMessages(updatedMessages);

      _messageCache[cacheKey] = finalMessages;
      await _persistMessages(cacheKey, finalMessages);

      if (requestId != _messageRequestId ||
          state.activeConversationId != event.conversationId) {
        return;
      }

      emit(state.copyWith(
        messages: finalMessages,
        currentPage: event.page,
        hasMoreMessages: fetchedMessages.length >= 50,
        messagesStatus: ChatStatus.success,
        activeConversationId: event.conversationId,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        messagesStatus: ChatStatus.error,
        error: e.toString(),
      ));
    } finally {
      _loadingConversations.remove(cacheKey);
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    await _loadCurrentUserId();

    if (_currentUserId == null) {
      emit(state.copyWith(error: 'You must be signed in to send messages'));
      return;
    }

    final sendKey = _messageKey(
      conversationId: event.conversationId,
      receiverId: event.receiverId,
      message: event.message,
      messageType: event.messageType,
      mediaUrl: event.mediaUrl,
      replyToId: event.replyToId,
    );

    if (_inFlightMessageKeys.contains(sendKey)) {
      return;
    }

    _inFlightMessageKeys.add(sendKey);

    final tempId = -DateTime.now().microsecondsSinceEpoch;

    final tempMessage = MessageModel(
      id: tempId,
      conversationId: event.conversationId,
      senderId: _currentUserId!,
      receiverId: event.receiverId,
      message: event.message,
      messageType: event.messageType,
      mediaUrl: event.mediaUrl,
      replyToId: event.replyToId,
      replyToMessage: event.replyToMessage,
      replyToSender: event.replyToSender,
      isRead: false,
      isOwn: true,
      createdAt: DateTime.now(),
    );

    final currentMessages = state.activeConversationId == event.conversationId
        ? state.messages
        : _messageCache[event.conversationId] ?? const <MessageModel>[];

    final updatedMessages = _mergeMessages([
      tempMessage,
      ...currentMessages,
    ]);

    _messageCache[event.conversationId] = updatedMessages;
    await _persistMessages(event.conversationId, updatedMessages);

    final updatedConversations = _updateConversationPreview(
      state.conversations,
      conversationId: event.conversationId,
      lastMessage: event.message,
      lastMessageType: event.messageType,
    );
    unawaited(_persistConversations(updatedConversations));

    emit(state.copyWith(
      messages: updatedMessages,
      messagesStatus: ChatStatus.success,
      activeConversationId: event.conversationId,
      conversations: updatedConversations,
    ));

    try {
      final response = await _chatService.sendMessage(
        receiverId: event.receiverId,
        message: event.message,
        messageType: event.messageType,
        mediaUrl: event.mediaUrl,
        replyToId: event.replyToId,
      );

      MessageModel? realMessage;

      if (response != null) {
        final parsed = MessageModel.fromJson(response);
        realMessage = MessageModel(
          id: parsed.id,
          conversationId: parsed.conversationId,
          senderId: parsed.senderId,
          receiverId: parsed.receiverId,
          message: parsed.message,
          messageType: parsed.messageType,
          mediaUrl: parsed.mediaUrl,
          replyToId: parsed.replyToId,
          replyToMessage: parsed.replyToMessage,
          replyToSender: parsed.replyToSender,
          isRead: parsed.isRead,
          isOwn: true,
          createdAt: parsed.createdAt,
        );
      }

      final visibleMessages = state.activeConversationId == event.conversationId
          ? state.messages
          : _messageCache[event.conversationId] ?? updatedMessages;

      final replacedMessages = _mergeMessages(visibleMessages.map((m) {
        if (m.id == tempId) {
          return realMessage ?? tempMessage;
        }
        return m;
      }).toList());

      _messageCache[event.conversationId] = replacedMessages;
      await _persistMessages(event.conversationId, replacedMessages);

      final updatedConversations = _updateConversationPreview(
        state.conversations,
        conversationId: event.conversationId,
        lastMessage: event.message,
        lastMessageType: event.messageType,
      );
      unawaited(_persistConversations(updatedConversations));

      emit(state.copyWith(
        messages: replacedMessages,
        messagesStatus: ChatStatus.success,
        activeConversationId: event.conversationId,
        clearError: true,
        conversations: updatedConversations,
      ));

      _chatService.clearMessagesCache(event.conversationId);
      add(RefreshConversations());

      add(LoadMessages(
        conversationId: event.conversationId,
        page: 1,
        forceRefresh: true,
        silent: true,
      ));
    } catch (_) {
      _messageCache[event.conversationId] = state.messages;
      await _persistMessages(event.conversationId, state.messages);
      emit(state.copyWith(
        messagesStatus: ChatStatus.success,
        clearError: true,
      ));
    } finally {
      _inFlightMessageKeys.remove(sendKey);
    }
  }

  Future<void> _onLoadCliqueBotMessages(
    LoadCliqueBotMessages event,
    Emitter<ChatState> emit,
  ) async {
    await _loadCurrentUserId();
    if (_currentUserId == null) return;

    if (state.activeConversationId != event.conversationId) {
      emit(state.copyWith(
        messages: const [],
        messagesStatus: ChatStatus.loading,
        currentPage: 1,
        hasMoreMessages: false,
        activeConversationId: event.conversationId,
      ));
    }

    final data = await _chatService.ensureCliqueBotWelcome(
      conversationId: event.conversationId,
      currentUserId: _currentUserId!,
    );
    final messages =
        data.map((json) => _ownMessage(MessageModel.fromJson(json))).toList();
    final merged = _mergeMessages(messages);

    _messageCache[event.conversationId] = merged;
    emit(state.copyWith(
      messages: merged,
      currentPage: 1,
      hasMoreMessages: false,
      messagesStatus: ChatStatus.success,
      activeConversationId: event.conversationId,
      clearError: true,
    ));
  }

  Future<void> _onSendCliqueBotMessage(
    SendCliqueBotMessage event,
    Emitter<ChatState> emit,
  ) async {
    await _loadCurrentUserId();
    if (_currentUserId == null) {
      emit(state.copyWith(error: 'You must be signed in to send messages'));
      return;
    }

    final data = await _chatService.saveCliqueBotExchange(
      conversationId: event.conversationId,
      currentUserId: _currentUserId!,
      message: event.message.trim(),
      replyToId: event.replyToId,
      replyToMessage: event.replyToMessage,
      replyToSender: event.replyToSender,
    );
    final messages =
        data.map((json) => _ownMessage(MessageModel.fromJson(json))).toList();
    final merged = _mergeMessages(messages);

    _messageCache[event.conversationId] = merged;
    final updatedConversations = _updateConversationPreview(
      state.conversations,
      conversationId: event.conversationId,
      lastMessage: merged.isNotEmpty ? merged.first.message : '',
      lastMessageType: merged.isNotEmpty ? merged.first.messageType : 'text',
    );
    unawaited(_persistConversations(updatedConversations));
    emit(state.copyWith(
      messages: merged,
      messagesStatus: ChatStatus.success,
      activeConversationId: event.conversationId,
      clearError: true,
      conversations: updatedConversations,
    ));
  }

  Future<void> _onRetryPendingMessages(
    RetryPendingMessages event,
    Emitter<ChatState> emit,
  ) async {
    final pendingMessages = (_messageCache[event.conversationId] ??
            state.messages
                .where((m) => m.conversationId == event.conversationId))
        .where((m) => m.isPending)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (pendingMessages.isEmpty) {
      return;
    }

    for (final pending in pendingMessages) {
      final sendKey = _messageKey(
        conversationId: pending.conversationId,
        receiverId: pending.receiverId,
        message: pending.message,
        messageType: pending.messageType,
        mediaUrl: pending.mediaUrl,
        replyToId: pending.replyToId,
      );

      if (_inFlightMessageKeys.contains(sendKey)) continue;

      _inFlightMessageKeys.add(sendKey);
      try {
        final latest = await _chatService.getMessages(
          event.conversationId,
          forceRefresh: true,
          silent: true,
        );
        final latestMessages =
            latest.map((json) => MessageModel.fromJson(json)).toList();
        if (latestMessages.any(
          (message) => _looksLikeSameDelivery(pending, message),
        )) {
          final merged = _mergeMessages([
            ...latestMessages,
            ...(_messageCache[event.conversationId] ?? state.messages),
          ]);
          _messageCache[event.conversationId] = merged;
          await _persistMessages(event.conversationId, merged);
          emit(state.copyWith(
            messages: merged,
            messagesStatus: ChatStatus.success,
            activeConversationId: event.conversationId,
            clearError: true,
          ));
          continue;
        }

        final response = await _chatService.sendMessage(
          receiverId: pending.receiverId,
          message: pending.message,
          messageType: pending.messageType,
          mediaUrl: pending.mediaUrl,
          replyToId: pending.replyToId,
        );

        if (response == null) continue;

        final parsed = MessageModel.fromJson(response);
        final deliveredMessage = _ownMessage(parsed);

        final cachedMessages =
            _messageCache[event.conversationId] ?? state.messages;
        final replacedCachedMessages = _mergeMessages(cachedMessages.map((m) {
          return m.id == pending.id ? deliveredMessage : m;
        }).toList());

        _messageCache[event.conversationId] = replacedCachedMessages;
        await _persistMessages(event.conversationId, replacedCachedMessages);

        if (state.messages.any((m) => m.id == pending.id)) {
          final replacedVisibleMessages =
              _mergeMessages(state.messages.map((m) {
            return m.id == pending.id ? deliveredMessage : m;
          }).toList());

          emit(state.copyWith(
            messages: replacedVisibleMessages,
            messagesStatus: ChatStatus.success,
            clearError: true,
          ));
        } else {
          emit(state.copyWith(
            messagesStatus: ChatStatus.success,
            clearError: true,
          ));
        }

        _chatService.clearMessagesCache(event.conversationId);
        add(RefreshConversations());
        } catch (_) {
          emit(state.copyWith(
            messagesStatus: ChatStatus.success,
            activeConversationId: event.conversationId,
            clearError: true,
          ));
        } finally {
          _inFlightMessageKeys.remove(sendKey);
        }
    }

    final stillPending = (_messageCache[event.conversationId] ?? state.messages)
        .any((m) => m.isPending);

    if (!stillPending) {
      add(LoadMessages(
        conversationId: event.conversationId,
        page: 1,
        forceRefresh: true,
        silent: true,
      ));
    }
  }

  Future<void> _onDeleteMessage(
      DeleteMessage event, Emitter<ChatState> emit) async {
    try {
      await _chatService.deleteMessage(event.messageId);
      for (final entry in _messageCache.entries) {
        if (entry.value.any((m) => m.id == event.messageId)) {
          final updated =
              entry.value.where((m) => m.id != event.messageId).toList();
          _messageCache[entry.key] = updated;
          if (updated.isEmpty) {
            await _chatService.clearCachedMessages(
              entry.key,
              cacheOwnerId: _currentUserId,
            );
          } else {
            await _persistMessages(entry.key, updated);
          }
        }
      }
      emit(state.copyWith(
        messages: state.messages.where((m) => m.id != event.messageId).toList(),
      ));
      add(RefreshConversations());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onReportMessage(
      ReportMessage event, Emitter<ChatState> emit) async {
    try {
      await _chatService.reportMessage(event.messageId, event.reason);
      emit(state.copyWith(clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onMarkMessagesAsRead(
      MarkMessagesAsRead event, Emitter<ChatState> emit) async {
    try {
      await _chatService.markAsRead(event.conversationId);
      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == event.conversationId) {
          return ConversationModel(
            id: conv.id,
            userId: conv.userId,
            name: conv.name,
            username: conv.username,
            avatar: conv.avatar,
            age: conv.age,
            verified: conv.verified,
            lastMessage: conv.lastMessage,
            lastMessageType: conv.lastMessageType,
            timestamp: conv.timestamp,
            unreadCount: 0,
            isOnline: conv.isOnline,
            isTyping: conv.isTyping,
            isPinned: conv.isPinned,
            isMuted: conv.isMuted,
            muteUntil: conv.muteUntil,
          );
        }
        return conv;
      }).toList();
      emit(state.copyWith(conversations: updatedConversations));
    } catch (_) {}
  }

  Future<void> _onSetTyping(SetTyping event, Emitter<ChatState> emit) async {
    await _chatService.setTyping(event.conversationId, event.isTyping);
  }

  Future<void> _onLoadChatSettings(
      LoadChatSettings event, Emitter<ChatState> emit) async {
    emit(state.copyWith(settingsStatus: ChatStatus.loading));
    try {
      final data = await _chatService.getChatSettings(event.conversationId);
      final settings = ChatSettingsModel.fromJson(data);
      emit(state.copyWith(
        chatSettings: settings,
        settingsStatus: ChatStatus.success,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        settingsStatus: ChatStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateChatSettings(
      UpdateChatSettings event, Emitter<ChatState> emit) async {
    final current = state.chatSettings;
    final baseSettings = current ??
        ChatSettingsModel(
          id: event.conversationId,
          isPinned: false,
          isMuted: false,
          wallpaper: 'default',
          chatColor: 'default',
          notificationSound: 'default',
        );

    final optimisticSettings = baseSettings.copyWith(
      id: event.conversationId,
      isPinned: event.isPinned,
      isMuted: event.isMuted,
      muteUntil: event.muteUntil,
      clearMuteUntil: event.isMuted == false,
      wallpaper: event.wallpaper,
      chatColor: event.chatColor,
      notificationSound: event.notificationSound,
    );

    final updatedConversations = state.conversations.map((conv) {
      if (conv.id != event.conversationId) return conv;
      return conv.copyWith(
        isPinned: event.isPinned,
        isMuted: event.isMuted,
        muteUntil: event.muteUntil,
        clearMuteUntil: event.isMuted == false,
      );
    }).toList();

    emit(state.copyWith(
      chatSettings: optimisticSettings,
      conversations: updatedConversations,
      settingsStatus: ChatStatus.success,
      clearError: true,
    ));

    try {
      await _chatService.updateChatSettings(
        event.conversationId,
        isPinned: event.isPinned,
        isMuted: event.isMuted,
        muteUntil: event.muteUntil,
        wallpaper: event.wallpaper,
        chatColor: event.chatColor,
        notificationSound: event.notificationSound,
      );
      add(RefreshConversations());
      add(LoadChatSettings(conversationId: event.conversationId));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onLoadUserPreferences(
      LoadUserPreferences event, Emitter<ChatState> emit) async {
    emit(state.copyWith(preferencesStatus: ChatStatus.loading));
    try {
      final data = await _chatService.getUserPreferences();
      final preferences = UserPreferencesModel.fromJson(data);
      emit(state.copyWith(
        userPreferences: preferences,
        preferencesStatus: ChatStatus.success,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        preferencesStatus: ChatStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateUserPreferences(
      UpdateUserPreferences event, Emitter<ChatState> emit) async {
    try {
      await _chatService.updateUserPreferences(
        wallpaper: event.wallpaper,
        chatColor: event.chatColor,
        notificationSound: event.notificationSound,
        fontSize: event.fontSize,
        enterToSend: event.enterToSend,
        readReceipts: event.readReceipts,
        typingIndicators: event.typingIndicators,
        messagePreview: event.messagePreview,
        autoDownloadMedia: event.autoDownloadMedia,
      );
      add(LoadUserPreferences());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onBlockUser(BlockUser event, Emitter<ChatState> emit) async {
    try {
      await _chatService.blockUser(event.userId);
      emit(state.copyWith(clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUnblockUser(
      UnblockUser event, Emitter<ChatState> emit) async {
    try {
      await _chatService.unblockUser(event.userId);
      emit(state.copyWith(clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onClearChat(ClearChat event, Emitter<ChatState> emit) async {
    try {
      await _chatService.clearChat(event.conversationId);
      _messageCache.remove(event.conversationId);
      await _chatService.clearCachedMessages(
        event.conversationId,
        cacheOwnerId: _currentUserId,
      );
      await _chatService.clearDraft(
        event.conversationId,
        cacheOwnerId: _currentUserId,
      );
      emit(state.copyWith(
        messages: const [],
        currentPage: 1,
        hasMoreMessages: false,
        messagesStatus: ChatStatus.success,
        activeConversationId: event.conversationId,
        clearError: true,
      ));
      add(RefreshConversations());
      add(LoadMessages(
        conversationId: event.conversationId,
        page: 1,
        forceRefresh: true,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onClearChatError(ClearChatError event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearError: true));
  }

  void _onResetChatState(ResetChatState event, Emitter<ChatState> emit) {
    _currentUserId = null;
    _inFlightMessageKeys.clear();
    emit(const ChatState());
  }

  void _onNewMessageReceived(
    NewMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    await _loadCurrentUserId();

    final processedMessage = _ownMessage(MessageModel.fromJson(event.message));

    final cachedMessages = _messageCache[processedMessage.conversationId] ??
        const <MessageModel>[];
    final updatedMessages = _mergeMessages([
      processedMessage,
      ...cachedMessages,
    ]);

    _messageCache[processedMessage.conversationId] = updatedMessages;
    unawaited(
        _persistMessages(processedMessage.conversationId, updatedMessages));

    if (state.activeConversationId != processedMessage.conversationId) {
      return;
    }

    emit(state.copyWith(
      messages: updatedMessages,
      messagesStatus: ChatStatus.success,
      activeConversationId: processedMessage.conversationId,
    ));
  }

  void _onMessageReadReceived(
      MessageReadReceived event, Emitter<ChatState> emit) {
    if (state.activeConversationId != event.conversationId) {
      return;
    }

    final updatedMessages = state.messages.map((msg) {
      if (msg.isOwn && !msg.isRead) {
        return msg.copyWith(isRead: true);
      }
      return msg;
    }).toList();
    _messageCache[event.conversationId] = updatedMessages;
    unawaited(_persistMessages(event.conversationId, updatedMessages));
    final updatedConversations = state.conversations.map((conversation) {
      if (conversation.id != event.conversationId) return conversation;
      return conversation.copyWith(unreadCount: 0);
    }).toList();

    unawaited(_persistConversations(updatedConversations));
    emit(state.copyWith(
      messages: updatedMessages,
      conversations: updatedConversations,
    ));
  }

  void _onTypingStatusReceived(
    TypingStatusReceived event,
    Emitter<ChatState> emit,
  ) {
    final updatedConversations = state.conversations.map((conv) {
      if (conv.userId == event.userId) {
        return conv.copyWith(isTyping: event.isTyping);
      }

      return conv;
    }).toList();

    emit(state.copyWith(
      conversations: updatedConversations,
    ));
  }
}
