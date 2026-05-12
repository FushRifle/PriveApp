part of 'chat_bloc.dart';

class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final String? attachmentUrl;
  final String? attachmentType;
  final DateTime createdAt;
  final String status; // 'sending', 'sent', 'delivered', 'read', 'failed'

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.attachmentUrl,
    this.attachmentType,
    required this.createdAt,
    this.status = 'sent',
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
      senderId: json['senderId'] ?? json['sender_id'] ?? 0,
      receiverId: json['receiverId'] ?? json['receiver_id'] ?? 0,
      content: json['content']?.toString() ?? '',
      attachmentUrl: json['attachmentUrl']?.toString(),
      attachmentType: json['attachmentType']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      status: json['status']?.toString() ?? 'sent',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        if (attachmentType != null) 'attachmentType': attachmentType,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };

  Message copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? content,
    String? attachmentUrl,
    String? attachmentType,
    DateTime? createdAt,
    String? status,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

class Conversation {
  final int userId;
  final String name;
  final String? avatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;

  const Conversation({
    required this.userId,
    required this.name,
    this.avatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isTyping = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      userId: json['userId'] ?? json['user_id'] ?? 0,
      name: json['name']?.toString() ?? 'User',
      avatar: json['avatar']?.toString(),
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'].toString())
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
      isOnline: json['isOnline'] == true,
      isTyping: json['isTyping'] == true,
    );
  }

  Conversation copyWith({
    int? userId,
    String? name,
    String? avatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    bool? isTyping,
  }) {
    return Conversation(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatPreferences {
  final bool allowNotifications;
  final bool showReadReceipts;
  final bool showTypingIndicators;
  final String? theme;
  final String? fontSize;

  const ChatPreferences({
    this.allowNotifications = true,
    this.showReadReceipts = true,
    this.showTypingIndicators = true,
    this.theme,
    this.fontSize,
  });

  factory ChatPreferences.fromJson(Map<String, dynamic> json) {
    return ChatPreferences(
      allowNotifications: json['allowNotifications'] ?? true,
      showReadReceipts: json['showReadReceipts'] ?? true,
      showTypingIndicators: json['showTypingIndicators'] ?? true,
      theme: json['theme']?.toString(),
      fontSize: json['fontSize']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'allowNotifications': allowNotifications,
        'showReadReceipts': showReadReceipts,
        'showTypingIndicators': showTypingIndicators,
        if (theme != null) 'theme': theme,
        if (fontSize != null) 'fontSize': fontSize,
      };

  ChatPreferences copyWith({
    bool? allowNotifications,
    bool? showReadReceipts,
    bool? showTypingIndicators,
    String? theme,
    String? fontSize,
  }) {
    return ChatPreferences(
      allowNotifications: allowNotifications ?? this.allowNotifications,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      showTypingIndicators: showTypingIndicators ?? this.showTypingIndicators,
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class ChatState extends Equatable {
  // Conversations
  final List<Conversation> conversations;
  final ChatStatus conversationsStatus;

  // Current chat
  final List<Message> currentMessages;
  final int currentUserId;
  final bool hasMoreMessages;
  final int currentPage;
  final ChatStatus messagesStatus;

  // Typing
  final Map<int, bool> typingUsers;

  // Preferences
  final ChatPreferences? preferences;
  final ChatStatus preferencesStatus;

  // Status
  final bool isOnline;
  final String? error;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSending;

  const ChatState({
    this.conversations = const [],
    this.conversationsStatus = ChatStatus.initial,
    this.currentMessages = const [],
    this.currentUserId = 0,
    this.hasMoreMessages = true,
    this.currentPage = 1,
    this.messagesStatus = ChatStatus.initial,
    this.typingUsers = const {},
    this.preferences,
    this.preferencesStatus = ChatStatus.initial,
    this.isOnline = false,
    this.error,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
  });

  ChatState copyWith({
    List<Conversation>? conversations,
    ChatStatus? conversationsStatus,
    List<Message>? currentMessages,
    int? currentUserId,
    bool? hasMoreMessages,
    int? currentPage,
    ChatStatus? messagesStatus,
    Map<int, bool>? typingUsers,
    ChatPreferences? preferences,
    ChatStatus? preferencesStatus,
    bool? isOnline,
    String? error,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      conversationsStatus: conversationsStatus ?? this.conversationsStatus,
      currentMessages: currentMessages ?? this.currentMessages,
      currentUserId: currentUserId ?? this.currentUserId,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      currentPage: currentPage ?? this.currentPage,
      messagesStatus: messagesStatus ?? this.messagesStatus,
      typingUsers: typingUsers ?? this.typingUsers,
      preferences: preferences ?? this.preferences,
      preferencesStatus: preferencesStatus ?? this.preferencesStatus,
      isOnline: isOnline ?? this.isOnline,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        conversationsStatus,
        currentMessages,
        currentUserId,
        hasMoreMessages,
        currentPage,
        messagesStatus,
        typingUsers,
        preferences,
        preferencesStatus,
        isOnline,
        error,
        isLoading,
        isLoadingMore,
        isSending,
      ];
}

enum ChatStatus {
  initial,
  loading,
  loadingMore,
  refreshing,
  success,
  error,
}
