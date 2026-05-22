import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/data/services/chat/chat_service.dart';
import 'package:clique/data/services/user/user_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  int? _currentUserId;
  final Map<int, List<MessageModel>> _messageCache = {};
  final Set<int> _loadingConversations = {};

  ChatBloc() : super(const ChatState()) {
    on<LoadConversations>(_onLoadConversations);
    on<RefreshConversations>(_onRefreshConversations);
    on<LoadConversationInfo>(_onLoadConversationInfo);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
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
      } catch (e) {
        print('Failed to load current user ID: $e');
      }
    }
  }

  Future<void> _onLoadConversations(
      LoadConversations event, Emitter<ChatState> emit) async {
    if (state.conversations.isEmpty) {
      emit(state.copyWith(conversationsStatus: ChatStatus.loading));
    }

    try {
      final data = await _chatService.getConversations();
      final conversations =
          data.map((json) => ConversationModel.fromJson(json)).toList();
      emit(state.copyWith(
        conversations: conversations,
        conversationsStatus: ChatStatus.success,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        conversationsStatus: ChatStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshConversations(
      RefreshConversations event, Emitter<ChatState> emit) async {
    emit(state.copyWith(conversationsStatus: ChatStatus.refreshing));
    try {
      final data = await _chatService.getConversations();
      final conversations =
          data.map((json) => ConversationModel.fromJson(json)).toList();
      emit(state.copyWith(
        conversations: conversations,
        conversationsStatus: ChatStatus.success,
        error: null,
      ));
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
      emit(state.copyWith(conversationInfo: info, error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    await _loadCurrentUserId();

    final cacheKey = event.conversationId;

    if (_loadingConversations.contains(cacheKey)) {
      return;
    }

    _loadingConversations.add(cacheKey);

    try {
      final cachedMessages = _messageCache[cacheKey] ?? [];

      if (event.page == 1) {
        if (cachedMessages.isNotEmpty) {
          emit(state.copyWith(
            messages: cachedMessages,
            messagesStatus: ChatStatus.success,
            currentPage: 1,
          ));
        } else {
          emit(state.copyWith(
            messagesStatus: ChatStatus.loading,
          ));
        }
      }

      final data = await _chatService.getMessages(
        event.conversationId,
        page: event.page,
      );

      final fetchedMessages = data.map((json) {
        final message = MessageModel.fromJson(json);

        return MessageModel(
          id: message.id,
          conversationId: message.conversationId,
          senderId: message.senderId,
          receiverId: message.receiverId,
          message: message.message,
          messageType: message.messageType,
          mediaUrl: message.mediaUrl,
          replyToId: message.replyToId,
          replyToMessage: message.replyToMessage,
          replyToSender: message.replyToSender,
          isRead: message.isRead,
          isOwn: message.senderId == _currentUserId,
          createdAt: message.createdAt,
        );
      }).toList();

      List<MessageModel> updatedMessages = [];

      if (event.page == 1) {
        final optimisticMessages = cachedMessages.where(
          (m) => m.id.toString().startsWith('999'),
        );

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

      final uniqueMessages = <int, MessageModel>{};

      for (final msg in updatedMessages) {
        uniqueMessages[msg.id] = msg;
      }

      final finalMessages = uniqueMessages.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _messageCache[cacheKey] = finalMessages;

      emit(state.copyWith(
        messages: finalMessages,
        currentPage: event.page,
        hasMoreMessages: fetchedMessages.length >= 50,
        messagesStatus: ChatStatus.success,
        error: null,
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

    final tempId = int.parse("999${DateTime.now().millisecondsSinceEpoch}");

    final tempMessage = MessageModel(
      id: tempId,
      conversationId: event.receiverId,
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

    final updatedMessages = [
      tempMessage,
      ...state.messages,
    ];

    _messageCache[event.receiverId] = updatedMessages;

    emit(state.copyWith(
      messages: updatedMessages,
      messagesStatus: ChatStatus.success,
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

      if (response != null && response is Map<String, dynamic>) {
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

      final replacedMessages = state.messages.map((m) {
        if (m.id == tempId) {
          return realMessage ?? tempMessage;
        }
        return m;
      }).toList();

      _messageCache[event.receiverId] = replacedMessages;

      emit(state.copyWith(
        messages: replacedMessages,
        messagesStatus: ChatStatus.success,
      ));

      add(RefreshConversations());

      add(LoadMessages(
        conversationId: event.receiverId,
        page: 1,
      ));
    } catch (e) {
      final rollbackMessages =
          state.messages.where((m) => m.id != tempId).toList();

      _messageCache[event.receiverId] = rollbackMessages;

      emit(state.copyWith(
        messages: rollbackMessages,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteMessage(
      DeleteMessage event, Emitter<ChatState> emit) async {
    try {
      await _chatService.deleteMessage(event.messageId);
      emit(state.copyWith(
        messages: state.messages.where((m) => m.id != event.messageId).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onReportMessage(
      ReportMessage event, Emitter<ChatState> emit) async {
    try {
      await _chatService.reportMessage(event.messageId, event.reason);
      emit(state.copyWith(error: null));
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
    } catch (e) {
      print('Failed to mark as read: $e');
    }
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
        error: null,
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
        error: null,
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
      emit(state.copyWith(error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUnblockUser(
      UnblockUser event, Emitter<ChatState> emit) async {
    try {
      await _chatService.unblockUser(event.userId);
      emit(state.copyWith(error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onClearChat(ClearChat event, Emitter<ChatState> emit) async {
    try {
      await _chatService.clearChat(event.conversationId);
      add(LoadMessages(conversationId: event.conversationId, page: 1));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onClearChatError(ClearChatError event, Emitter<ChatState> emit) {
    emit(state.copyWith(error: null));
  }

  void _onResetChatState(ResetChatState event, Emitter<ChatState> emit) {
    _currentUserId = null;
    emit(const ChatState());
  }

  void _onNewMessageReceived(
    NewMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    await _loadCurrentUserId();

    final newMessage = MessageModel.fromJson(event.message);

    final processedMessage = MessageModel(
      id: newMessage.id,
      senderId: newMessage.senderId,
      receiverId: newMessage.receiverId,
      message: newMessage.message,
      messageType: newMessage.messageType,
      mediaUrl: newMessage.mediaUrl,
      replyToId: newMessage.replyToId,
      replyToMessage: newMessage.replyToMessage,
      replyToSender: newMessage.replyToSender,
      isRead: newMessage.isRead,
      isOwn: newMessage.senderId == _currentUserId,
      createdAt: newMessage.createdAt,
      conversationId: newMessage.conversationId,
    );

    final exists = state.messages.any(
      (m) => m.id == processedMessage.id,
    );

    if (exists) return;

    final updatedMessages = [
      processedMessage,
      ...state.messages,
    ];

    _messageCache[processedMessage.conversationId] = updatedMessages;

    emit(state.copyWith(
      messages: updatedMessages,
      messagesStatus: ChatStatus.success,
    ));
  }

  void _onMessageReadReceived(
      MessageReadReceived event, Emitter<ChatState> emit) {
    final updatedMessages = state.messages.map((msg) {
      if (!msg.isOwn && !msg.isRead) {
        return MessageModel(
          id: msg.id,
          conversationId: msg.conversationId,
          senderId: msg.senderId,
          receiverId: msg.receiverId,
          message: msg.message,
          messageType: msg.messageType,
          mediaUrl: msg.mediaUrl,
          replyToId: msg.replyToId,
          replyToMessage: msg.replyToMessage,
          replyToSender: msg.replyToSender,
          isRead: true,
          isOwn: msg.isOwn,
          createdAt: msg.createdAt,
        );
      }
      return msg;
    }).toList();
    emit(state.copyWith(messages: updatedMessages));
  }

  void _onTypingStatusReceived(
    TypingStatusReceived event,
    Emitter<ChatState> emit,
  ) {
    final updatedConversations = state.conversations.map((conv) {
      if (conv.userId == event.userId) {
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
          unreadCount: conv.unreadCount,
          isOnline: conv.isOnline,
          isTyping: event.isTyping,
          isPinned: conv.isPinned,
          isMuted: conv.isMuted,
          muteUntil: conv.muteUntil,
        );
      }

      return conv;
    }).toList();

    emit(state.copyWith(
      conversations: updatedConversations,
    ));
  }
}
