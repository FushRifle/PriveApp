import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/data/services/chat/chat_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService = ChatService();

  // Cache for pagination
  final Map<int, int> _messagePages = {};

  ChatBloc() : super(const ChatState()) {
    on<LoadConversations>(_onLoadConversations);
    on<RefreshConversations>(_onRefreshConversations);
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<MarkMessagesAsRead>(_onMarkMessagesAsRead);
    on<UpdateOnlineStatus>(_onUpdateOnlineStatus);
    on<UpdateTypingStatus>(_onUpdateTypingStatus);
    on<LoadChatPreferences>(_onLoadChatPreferences);
    on<UpdateChatPreferences>(_onUpdateChatPreferences);
    on<ClearCurrentMessages>(_onClearCurrentMessages);
    on<ClearUnreadCount>(_onClearUnreadCount);
    on<ClearChatError>(_onClearChatError);
    on<ResetChatState>(_onResetChatState);
    on<NewMessageReceived>(_onNewMessageReceived);
    on<MessageStatusUpdated>(_onMessageStatusUpdated);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    if (state.conversations.isEmpty) {
      emit(
        state.copyWith(
          conversationsStatus: ChatStatus.loading,
          isLoading: true,
        ),
      );
    }

    try {
      final conversations = await _chatService.getConversations();
      final conversationList = conversations
          .map((c) => Conversation.fromJson(c))
          .toList();

      emit(
        state.copyWith(
          conversations: conversationList,
          conversationsStatus: ChatStatus.success,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          conversationsStatus: ChatStatus.error,
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshConversations(
    RefreshConversations event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(conversationsStatus: ChatStatus.refreshing));

    try {
      final conversations = await _chatService.getConversations();
      final conversationList = conversations
          .map((c) => Conversation.fromJson(c))
          .toList();

      emit(
        state.copyWith(
          conversations: conversationList,
          conversationsStatus: ChatStatus.success,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          conversationsStatus: ChatStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (event.isInitialLoad) {
      // Reset state for new user
      _messagePages[event.userId] = 1;

      emit(
        state.copyWith(
          currentUserId: event.userId,
          currentMessages: [],
          currentPage: 1,
          hasMoreMessages: true,
          messagesStatus: ChatStatus.loading,
          isLoading: true,
        ),
      );
    }

    try {
      final messages = await _chatService.getMessages(
        event.userId,
        page: event.page,
      );
      final messageList = messages
          .map((m) => Message.fromJson(m))
          .toList()
          .reversed
          .toList(); // Reverse for chronological order

      emit(
        state.copyWith(
          currentMessages: messageList,
          hasMoreMessages: messageList.length >= 20, // Assuming 20 per page
          currentPage: event.page,
          messagesStatus: ChatStatus.success,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          messagesStatus: ChatStatus.error,
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (!state.hasMoreMessages || state.isLoadingMore) return;

    emit(
      state.copyWith(
        messagesStatus: ChatStatus.loadingMore,
        isLoadingMore: true,
      ),
    );

    try {
      final nextPage = state.currentPage + 1;
      final messages = await _chatService.getMessages(
        event.userId,
        page: nextPage,
      );
      final messageList = messages
          .map((m) => Message.fromJson(m))
          .toList()
          .reversed
          .toList();

      final updatedMessages = [...messageList, ...state.currentMessages];

      emit(
        state.copyWith(
          currentMessages: updatedMessages,
          hasMoreMessages: messageList.length >= 20,
          currentPage: nextPage,
          messagesStatus: ChatStatus.success,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          messagesStatus: ChatStatus.error,
          isLoadingMore: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempMessage = Message(
      id: tempId,
      senderId: 0, // Will be replaced by server
      receiverId: event.userId,
      content: event.content,
      attachmentUrl: event.attachmentUrl,
      attachmentType: event.attachmentType,
      createdAt: DateTime.now(),
      status: 'sending',
    );

    // Optimistic update
    List<Message> updatedMessages = List.from(state.currentMessages)
      ..add(tempMessage);

    emit(state.copyWith(currentMessages: updatedMessages, isSending: true));

    try {
      final result = await _chatService.sendMessage({
        'receiverId': event.userId,
        'content': event.content,
        if (event.attachmentUrl != null) 'attachmentUrl': event.attachmentUrl,
        if (event.attachmentType != null)
          'attachmentType': event.attachmentType,
      });

      // Replace temp message with real one
      final realMessage = Message.fromJson(result);
      final finalMessages = updatedMessages
          .map((m) => m.id == tempId ? realMessage : m)
          .toList();

      emit(state.copyWith(currentMessages: finalMessages, isSending: false));

      // Refresh conversations to update last message
      add(RefreshConversations());
    } catch (e) {
      // Update failed message status
      final failedMessages = updatedMessages
          .map((m) => m.id == tempId ? m.copyWith(status: 'failed') : m)
          .toList();

      emit(
        state.copyWith(
          currentMessages: failedMessages,
          isSending: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onMarkMessagesAsRead(
    MarkMessagesAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatService.markMessagesAsRead(event.userId);

      // Update unread count in conversations
      final updatedConversations = state.conversations.map((c) {
        if (c.userId == event.userId) {
          return c.copyWith(unreadCount: 0);
        }
        return c;
      }).toList();

      emit(state.copyWith(conversations: updatedConversations));
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _onUpdateOnlineStatus(
    UpdateOnlineStatus event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatService.setOnlineStatus(event.isOnline);
      emit(state.copyWith(isOnline: event.isOnline));
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  Future<void> _onUpdateTypingStatus(
    UpdateTypingStatus event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatService.setTypingStatus({
        'receiverId': event.userId,
        'isTyping': event.isTyping,
      });
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  Future<void> _onLoadChatPreferences(
    LoadChatPreferences event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(preferencesStatus: ChatStatus.loading));

    try {
      final prefs = await _chatService.getPreferences();
      emit(
        state.copyWith(
          preferences: ChatPreferences.fromJson(prefs),
          preferencesStatus: ChatStatus.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          preferencesStatus: ChatStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateChatPreferences(
    UpdateChatPreferences event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final result = await _chatService.updatePreferences(event.preferences);
      emit(state.copyWith(preferences: ChatPreferences.fromJson(result)));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onClearCurrentMessages(
    ClearCurrentMessages event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        currentUserId: 0,
        currentMessages: [],
        hasMoreMessages: true,
        currentPage: 1,
        messagesStatus: ChatStatus.initial,
      ),
    );
  }

  void _onClearUnreadCount(ClearUnreadCount event, Emitter<ChatState> emit) {
    final updatedConversations = state.conversations.map((c) {
      if (c.userId == event.userId) {
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();

    emit(state.copyWith(conversations: updatedConversations));
  }

  void _onClearChatError(ClearChatError event, Emitter<ChatState> emit) {
    emit(state.copyWith(error: null));
  }

  void _onResetChatState(ResetChatState event, Emitter<ChatState> emit) {
    _messagePages.clear();
    emit(const ChatState());
  }

  void _onNewMessageReceived(
    NewMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final message = Message.fromJson(event.message);

    // Update current messages if this is the active chat
    List<Message> updatedMessages = List.from(state.currentMessages);
    if (state.currentUserId == message.senderId) {
      updatedMessages.add(message);
      emit(state.copyWith(currentMessages: updatedMessages));
    }

    // Update conversation list
    final updatedConversations = state.conversations.map((c) {
      if (c.userId == message.senderId) {
        // Increment unread count if not active chat
        final unreadCount = state.currentUserId == message.senderId
            ? 0
            : c.unreadCount + 1;
        return c.copyWith(
          lastMessage: message.content,
          lastMessageTime: message.createdAt,
          unreadCount: unreadCount,
        );
      }
      return c;
    }).toList();

    emit(state.copyWith(conversations: updatedConversations));
  }

  void _onMessageStatusUpdated(
    MessageStatusUpdated event,
    Emitter<ChatState> emit,
  ) {
    final updatedMessages = state.currentMessages.map((m) {
      if (m.id == event.messageId) {
        return m.copyWith(status: event.status);
      }
      return m;
    }).toList();

    emit(state.copyWith(currentMessages: updatedMessages));
  }
}
