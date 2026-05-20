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

  ChatBloc() : super(const ChatState()) {
    on<LoadConversations>(_onLoadConversations);
    on<RefreshConversations>(_onRefreshConversations);
    on<LoadConversationInfo>(_onLoadConversationInfo);
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
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
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
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
    RefreshConversations event,
    Emitter<ChatState> emit,
  ) async {
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
    LoadConversationInfo event,
    Emitter<ChatState> emit,
  ) async {
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

    if (event.page == 1) {
      emit(state.copyWith(
        messagesStatus: ChatStatus.loading,
        messages: [],
        currentPage: 1,
        hasMoreMessages: true,
      ));
    }

    try {
      final data = await _chatService.getMessages(event.conversationId,
          page: event.page);
      final messages = data.map((json) {
        final message = MessageModel.fromJson(json);
        // Set isOwn based on current user ID
        return MessageModel(
          id: message.id,
          senderId: message.senderId,
          receiverId: message.receiverId,
          message: message.message,
          messageType: message.messageType,
          mediaUrl: message.mediaUrl,
          isRead: message.isRead,
          isOwn: message.senderId == _currentUserId,
          createdAt: message.createdAt,
        );
      }).toList();

      final newMessages =
          event.page == 1 ? messages : [...state.messages, ...messages];

      emit(state.copyWith(
        messages: newMessages,
        currentPage: event.page,
        hasMoreMessages: messages.length >= 50,
        messagesStatus: ChatStatus.success,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        messagesStatus: ChatStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (!state.hasMoreMessages || state.messagesStatus == ChatStatus.loading) {
      return;
    }

    final nextPage = state.currentPage + 1;
    add(LoadMessages(conversationId: event.conversationId, page: nextPage));
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    await _loadCurrentUserId();

    try {
      await _chatService.sendMessage(
        receiverId: event.receiverId,
        message: event.message,
        messageType: event.messageType,
        mediaUrl: event.mediaUrl,
      );
      add(RefreshConversations());
      add(LoadMessages(conversationId: event.receiverId, page: 1));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onMarkMessagesAsRead(
    MarkMessagesAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatService.markAsRead(event.conversationId);

      // Update unread count locally
      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == event.conversationId) {
          return ConversationModel(
            id: conv.id,
            userId: conv.userId,
            name: conv.name,
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
            username: '',
          );
        }
        return conv;
      }).toList();

      emit(state.copyWith(conversations: updatedConversations));
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  Future<void> _onSetTyping(
    SetTyping event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isTyping: event.isTyping));
    await _chatService.setTyping(event.conversationId, event.isTyping);
  }

  Future<void> _onLoadChatSettings(
    LoadChatSettings event,
    Emitter<ChatState> emit,
  ) async {
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
    UpdateChatSettings event,
    Emitter<ChatState> emit,
  ) async {
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

      if (state.chatSettings != null) {
        final updatedSettings = ChatSettingsModel(
          id: state.chatSettings!.id,
          isPinned: event.isPinned ?? state.chatSettings!.isPinned,
          isMuted: event.isMuted ?? state.chatSettings!.isMuted,
          muteUntil: event.muteUntil ?? state.chatSettings!.muteUntil,
          wallpaper: event.wallpaper ?? state.chatSettings!.wallpaper,
          chatColor: event.chatColor ?? state.chatSettings!.chatColor,
          notificationSound:
              event.notificationSound ?? state.chatSettings!.notificationSound,
        );
        emit(state.copyWith(chatSettings: updatedSettings));
      }

      add(RefreshConversations());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onLoadUserPreferences(
    LoadUserPreferences event,
    Emitter<ChatState> emit,
  ) async {
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
    UpdateUserPreferences event,
    Emitter<ChatState> emit,
  ) async {
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

      if (state.userPreferences != null) {
        final updatedPreferences = UserPreferencesModel(
          wallpaper: event.wallpaper ?? state.userPreferences!.wallpaper,
          chatColor: event.chatColor ?? state.userPreferences!.chatColor,
          notificationSound: event.notificationSound ??
              state.userPreferences!.notificationSound,
          fontSize: event.fontSize ?? state.userPreferences!.fontSize,
          enterToSend: event.enterToSend ?? state.userPreferences!.enterToSend,
          readReceipts:
              event.readReceipts ?? state.userPreferences!.readReceipts,
          typingIndicators:
              event.typingIndicators ?? state.userPreferences!.typingIndicators,
          messagePreview:
              event.messagePreview ?? state.userPreferences!.messagePreview,
          autoDownloadMedia: event.autoDownloadMedia ??
              state.userPreferences!.autoDownloadMedia,
        );
        emit(state.copyWith(userPreferences: updatedPreferences));
      } else {
        add(LoadUserPreferences());
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatService.blockUser(event.userId);
      emit(state.copyWith(error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatService.unblockUser(event.userId);

      if (state.conversationInfo != null &&
          state.conversationInfo!.participantId == event.userId) {
        add(LoadConversationInfo(
            conversationId: state.conversationInfo!.participantId));
      }
      emit(state.copyWith(error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onClearChat(
    ClearChat event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatService.clearChat(event.conversationId);
      add(LoadMessages(conversationId: event.conversationId, page: 1));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onClearChatError(
    ClearChatError event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  void _onResetChatState(
    ResetChatState event,
    Emitter<ChatState> emit,
  ) {
    _currentUserId = null;
    emit(const ChatState());
  }

  void _onNewMessageReceived(
    NewMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    await _loadCurrentUserId();

    final newMessage = MessageModel.fromJson(event.message);

    // Set isOwn based on current user ID
    final processedMessage = MessageModel(
      id: newMessage.id,
      senderId: newMessage.senderId,
      receiverId: newMessage.receiverId,
      message: newMessage.message,
      messageType: newMessage.messageType,
      mediaUrl: newMessage.mediaUrl,
      isRead: newMessage.isRead,
      isOwn: newMessage.senderId == _currentUserId,
      createdAt: newMessage.createdAt,
    );

    final updatedMessages = state.messagesStatus == ChatStatus.success &&
            state.conversationInfo != null &&
            processedMessage.senderId == state.conversationInfo!.participantId
        ? [processedMessage, ...state.messages]
        : state.messages;

    final updatedConversations = state.conversations.map((conv) {
      if (conv.userId == processedMessage.senderId ||
          conv.userId == processedMessage.receiverId) {
        return ConversationModel(
          id: conv.id,
          userId: conv.userId,
          name: conv.name,
          avatar: conv.avatar,
          age: conv.age,
          verified: conv.verified,
          lastMessage: processedMessage.message,
          lastMessageType: processedMessage.messageType,
          timestamp: 'just now',
          unreadCount:
              processedMessage.isOwn ? conv.unreadCount : conv.unreadCount + 1,
          isOnline: conv.isOnline,
          isTyping: false,
          isPinned: conv.isPinned,
          isMuted: conv.isMuted,
          muteUntil: conv.muteUntil,
          username: '',
        );
      }
      return conv;
    }).toList();

    emit(state.copyWith(
      messages: updatedMessages,
      conversations: updatedConversations,
    ));
  }

  void _onMessageReadReceived(
    MessageReadReceived event,
    Emitter<ChatState> emit,
  ) {
    if (state.conversationInfo != null &&
        state.conversationInfo!.participantId == event.readByUserId) {
      final updatedMessages = state.messages.map((msg) {
        if (!msg.isOwn && !msg.isRead) {
          return MessageModel(
            id: msg.id,
            senderId: msg.senderId,
            receiverId: msg.receiverId,
            message: msg.message,
            messageType: msg.messageType,
            mediaUrl: msg.mediaUrl,
            isRead: true,
            isOwn: msg.isOwn,
            createdAt: msg.createdAt,
          );
        }
        return msg;
      }).toList();
      emit(state.copyWith(messages: updatedMessages));
    }
  }

  void _onTypingStatusReceived(
    TypingStatusReceived event,
    Emitter<ChatState> emit,
  ) {
    final updatedConversations = state.conversations.map((conv) {
      if (conv.id == event.conversationId) {
        return ConversationModel(
          id: conv.id,
          userId: conv.userId,
          name: conv.name,
          avatar: conv.avatar,
          age: conv.age,
          verified: conv.verified,
          lastMessage: conv.lastMessage,
          lastMessageType: conv.lastMessageType,
          timestamp: conv.timestamp,
          unreadCount: conv.unreadCount,
          isOnline: conv.isOnline,
          isTyping: event.isTyping && event.userId != _currentUserId,
          isPinned: conv.isPinned,
          isMuted: conv.isMuted,
          muteUntil: conv.muteUntil,
          username: '',
        );
      }
      return conv;
    }).toList();
    emit(state.copyWith(conversations: updatedConversations));
  }
}
