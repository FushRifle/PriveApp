part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

// Load conversations
class LoadConversations extends ChatEvent {}

// Refresh conversations
class RefreshConversations extends ChatEvent {}

// Load messages for a specific user
class LoadMessages extends ChatEvent {
  final int userId;
  final int page;
  final bool isInitialLoad;

  const LoadMessages({
    required this.userId,
    this.page = 1,
    this.isInitialLoad = true,
  });

  @override
  List<Object?> get props => [userId, page, isInitialLoad];
}

// Load more messages (pagination)
class LoadMoreMessages extends ChatEvent {
  final int userId;

  const LoadMoreMessages({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Send a new message
class SendMessage extends ChatEvent {
  final int userId;
  final String content;
  final String? attachmentUrl;
  final String? attachmentType;

  const SendMessage({
    required this.userId,
    required this.content,
    this.attachmentUrl,
    this.attachmentType,
  });

  @override
  List<Object?> get props => [userId, content, attachmentUrl, attachmentType];
}

// Mark messages as read
class MarkMessagesAsRead extends ChatEvent {
  final int userId;

  const MarkMessagesAsRead({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Update online status
class UpdateOnlineStatus extends ChatEvent {
  final bool isOnline;

  const UpdateOnlineStatus({required this.isOnline});

  @override
  List<Object?> get props => [isOnline];
}

// Update typing status
class UpdateTypingStatus extends ChatEvent {
  final int userId;
  final bool isTyping;

  const UpdateTypingStatus({
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [userId, isTyping];
}

// Load chat preferences
class LoadChatPreferences extends ChatEvent {}

// Update chat preferences
class UpdateChatPreferences extends ChatEvent {
  final Map<String, dynamic> preferences;

  const UpdateChatPreferences({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

// Clear current messages (when leaving chat)
class ClearCurrentMessages extends ChatEvent {}

// Clear unread count for a conversation
class ClearUnreadCount extends ChatEvent {
  final int userId;

  const ClearUnreadCount({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Clear chat error
class ClearChatError extends ChatEvent {}

// Reset chat state
class ResetChatState extends ChatEvent {}

// New message received (from WebSocket/push)
class NewMessageReceived extends ChatEvent {
  final Map<String, dynamic> message;

  const NewMessageReceived({required this.message});

  @override
  List<Object?> get props => [message];
}

// New message status update
class MessageStatusUpdated extends ChatEvent {
  final int messageId;
  final String status; // 'sent', 'delivered', 'read'

  const MessageStatusUpdated({
    required this.messageId,
    required this.status,
  });

  @override
  List<Object?> get props => [messageId, status];
}
