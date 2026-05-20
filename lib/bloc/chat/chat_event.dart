part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

// Conversation events
class LoadConversations extends ChatEvent {}

class RefreshConversations extends ChatEvent {}

class LoadConversationInfo extends ChatEvent {
  final int conversationId;
  const LoadConversationInfo({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

// Message events
class LoadMessages extends ChatEvent {
  final int conversationId;
  final int page;
  const LoadMessages({required this.conversationId, this.page = 1});

  @override
  List<Object?> get props => [conversationId, page];
}

class LoadMoreMessages extends ChatEvent {
  final int conversationId;
  const LoadMoreMessages({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class SendMessage extends ChatEvent {
  final int receiverId;
  final String message;
  final String messageType;
  final String? mediaUrl;
  const SendMessage({
    required this.receiverId,
    required this.message,
    this.messageType = 'text',
    this.mediaUrl,
  });

  @override
  List<Object?> get props => [receiverId, message, messageType, mediaUrl];
}

class MarkMessagesAsRead extends ChatEvent {
  final int conversationId;
  const MarkMessagesAsRead({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

// Typing events
class SetTyping extends ChatEvent {
  final int conversationId;
  final bool isTyping;
  const SetTyping({required this.conversationId, required this.isTyping});

  @override
  List<Object?> get props => [conversationId, isTyping];
}

// Chat settings events
class LoadChatSettings extends ChatEvent {
  final int conversationId;
  const LoadChatSettings({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class UpdateChatSettings extends ChatEvent {
  final int conversationId;
  final bool? isPinned;
  final bool? isMuted;
  final DateTime? muteUntil;
  final String? wallpaper;
  final String? chatColor;
  final String? notificationSound;
  const UpdateChatSettings({
    required this.conversationId,
    this.isPinned,
    this.isMuted,
    this.muteUntil,
    this.wallpaper,
    this.chatColor,
    this.notificationSound,
  });

  @override
  List<Object?> get props => [
        conversationId,
        isPinned,
        isMuted,
        muteUntil,
        wallpaper,
        chatColor,
        notificationSound
      ];
}

// User preferences events
class LoadUserPreferences extends ChatEvent {}

class UpdateUserPreferences extends ChatEvent {
  final String? wallpaper;
  final String? chatColor;
  final String? notificationSound;
  final int? fontSize;
  final bool? enterToSend;
  final bool? readReceipts;
  final bool? typingIndicators;
  final bool? messagePreview;
  final String? autoDownloadMedia;
  const UpdateUserPreferences({
    this.wallpaper,
    this.chatColor,
    this.notificationSound,
    this.fontSize,
    this.enterToSend,
    this.readReceipts,
    this.typingIndicators,
    this.messagePreview,
    this.autoDownloadMedia,
  });

  @override
  List<Object?> get props => [
        wallpaper,
        chatColor,
        notificationSound,
        fontSize,
        enterToSend,
        readReceipts,
        typingIndicators,
        messagePreview,
        autoDownloadMedia
      ];
}

// Block/Unblock events
class BlockUser extends ChatEvent {
  final int userId;
  const BlockUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UnblockUser extends ChatEvent {
  final int userId;
  const UnblockUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Clear chat
class ClearChat extends ChatEvent {
  final int conversationId;
  const ClearChat({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

// Error handling
class ClearChatError extends ChatEvent {}

class ResetChatState extends ChatEvent {}

// Real-time events (for SSE/WebSocket)
class NewMessageReceived extends ChatEvent {
  final Map<String, dynamic> message;
  const NewMessageReceived({required this.message});

  @override
  List<Object?> get props => [message];
}

class MessageReadReceived extends ChatEvent {
  final int conversationId;
  final int readByUserId;
  const MessageReadReceived(
      {required this.conversationId, required this.readByUserId});

  @override
  List<Object?> get props => [conversationId, readByUserId];
}

class TypingStatusReceived extends ChatEvent {
  final int conversationId;
  final int userId;
  final bool isTyping;
  const TypingStatusReceived({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [conversationId, userId, isTyping];
}
