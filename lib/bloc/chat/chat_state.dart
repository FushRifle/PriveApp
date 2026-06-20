part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, refreshing, success, error }

class ConversationModel {
  final int id;
  final int userId;
  final String name;
  final String username;
  final String avatar;
  final int age;
  final bool verified;
  final String lastMessage;
  final String lastMessageType;
  final String timestamp;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;
  final bool isPinned;
  final bool isMuted;
  final DateTime? muteUntil;

  const ConversationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    required this.avatar,
    required this.age,
    required this.verified,
    required this.lastMessage,
    required this.lastMessageType,
    required this.timestamp,
    required this.unreadCount,
    required this.isOnline,
    required this.isTyping,
    required this.isPinned,
    required this.isMuted,
    this.muteUntil,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? json['user_id'] ?? 0,
      name: json['name'] ?? 'User',
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      age: json['age'] ?? 0,
      verified: json['verified'] ?? false,
      lastMessage: json['lastMessage'] ?? json['last_message'] ?? '',
      lastMessageType:
          json['lastMessageType'] ?? json['last_message_type'] ?? 'text',
      timestamp: json['timestamp'] ?? '',
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
      isOnline: json['isOnline'] ?? json['is_online'] ?? false,
      isTyping: json['isTyping'] ?? json['is_typing'] ?? false,
      isPinned: json['isPinned'] ?? json['is_pinned'] ?? false,
      isMuted: json['isMuted'] ?? json['is_muted'] ?? false,
      muteUntil: (json['muteUntil'] ?? json['mute_until']) != null
          ? DateTime.tryParse(json['muteUntil'] ?? json['mute_until'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'username': username,
      'avatar': avatar,
      'age': age,
      'verified': verified,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'timestamp': timestamp,
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'isTyping': isTyping,
      'isPinned': isPinned,
      'isMuted': isMuted,
      'muteUntil': muteUntil?.toIso8601String(),
    };
  }

  ConversationModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? username,
    String? avatar,
    int? age,
    bool? verified,
    String? lastMessage,
    String? lastMessageType,
    String? timestamp,
    int? unreadCount,
    bool? isOnline,
    bool? isTyping,
    bool? isPinned,
    bool? isMuted,
    DateTime? muteUntil,
    bool clearMuteUntil = false,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      age: age ?? this.age,
      verified: verified ?? this.verified,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      timestamp: timestamp ?? this.timestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      isTyping: isTyping ?? this.isTyping,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      muteUntil: clearMuteUntil ? null : muteUntil ?? this.muteUntil,
    );
  }
}

class MessageModel {
  final int id;
  final int conversationId; // ADD THIS
  final String? streamMessageId;
  final int senderId;
  final int receiverId;
  final String message;
  final String messageType;
  final String? mediaUrl;
  final int? replyToId;
  final String? replyToMessage;
  final String? replyToSender;
  final String? sourceType;
  final String? sourceId;
  final String? sourcePreview;
  final bool isRead;
  final bool isOwn;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId, // ADD THIS
    this.streamMessageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.messageType,
    this.mediaUrl,
    this.replyToId,
    this.replyToMessage,
    this.replyToSender,
    this.sourceType,
    this.sourceId,
    this.sourcePreview,
    required this.isRead,
    required this.isOwn,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? 0,
      streamMessageId: json['streamMessageId'] ??
          json['stream_message_id'] ??
          json['streamId'],
      senderId: json['senderId'] ?? json['sender_id'] ?? 0,
      receiverId: json['receiverId'] ?? json['receiver_id'] ?? 0,
      message: json['message'] ?? '',
      messageType: json['messageType'] ?? json['message_type'] ?? 'text',
      mediaUrl: json['mediaUrl'] ?? json['media_url'],
      replyToId: json['replyToId'] ?? json['reply_to_id'],
      replyToMessage: json['replyToMessage'] ?? json['reply_to_message'],
      replyToSender: json['replyToSender'] ?? json['reply_to_sender'],
      sourceType: json['sourceType'] ?? json['source_type'],
      sourceId: (json['sourceId'] ?? json['source_id'])?.toString(),
      sourcePreview: json['sourcePreview'] ?? json['source_preview'],
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      isOwn: json['isOwn'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId, // ADD THIS
      'streamMessageId': streamMessageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'replyToId': replyToId,
      'replyToMessage': replyToMessage,
      'replyToSender': replyToSender,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'sourcePreview': sourcePreview,
      'isRead': isRead,
      'isOwn': isOwn,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    int? id,
    int? conversationId,
    String? streamMessageId,
    int? senderId,
    int? receiverId,
    String? message,
    String? messageType,
    String? mediaUrl,
    int? replyToId,
    String? replyToMessage,
    String? replyToSender,
    String? sourceType,
    String? sourceId,
    String? sourcePreview,
    bool? isRead,
    bool? isOwn,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      streamMessageId: streamMessageId ?? this.streamMessageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      replyToSender: replyToSender ?? this.replyToSender,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourcePreview: sourcePreview ?? this.sourcePreview,
      isRead: isRead ?? this.isRead,
      isOwn: isOwn ?? this.isOwn,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPending => id < 0 || id.toString().startsWith('999');
}

class ConversationInfoModel {
  final int participantId;
  final String participantName;
  final int participantAge;
  final String participantAvatar;
  final bool participantVerified;
  final DateTime memberSince;
  final bool isBlocked;

  const ConversationInfoModel({
    required this.participantId,
    required this.participantName,
    required this.participantAge,
    required this.participantAvatar,
    required this.participantVerified,
    required this.memberSince,
    required this.isBlocked,
  });

  factory ConversationInfoModel.fromJson(Map<String, dynamic> json) {
    return ConversationInfoModel(
      participantId: json['participantId'] ?? 0,
      participantName: json['participantName'] ?? 'User',
      participantAge: json['participantAge'] ?? 0,
      participantAvatar: json['participantAvatar'] ?? '',
      participantVerified: json['participantVerified'] ?? false,
      memberSince: DateTime.parse(json['memberSince']),
      isBlocked: json['isBlocked'] ?? false,
    );
  }
}

class ChatSettingsModel {
  final int id;
  final bool isPinned;
  final bool isMuted;
  final DateTime? muteUntil;
  final String wallpaper;
  final String chatColor;
  final String notificationSound;

  const ChatSettingsModel({
    required this.id,
    required this.isPinned,
    required this.isMuted,
    this.muteUntil,
    required this.wallpaper,
    required this.chatColor,
    required this.notificationSound,
  });

  factory ChatSettingsModel.fromJson(Map<String, dynamic> json) {
    return ChatSettingsModel(
      id: json['id'] ?? 0,
      isPinned: json['isPinned'] ?? json['is_pinned'] ?? false,
      isMuted: json['isMuted'] ?? json['is_muted'] ?? false,
      muteUntil: (json['muteUntil'] ?? json['mute_until']) != null
          ? DateTime.tryParse(json['muteUntil'] ?? json['mute_until'])
          : null,
      wallpaper: json['wallpaper'] ?? 'default',
      chatColor: json['chatColor'] ?? json['chat_color'] ?? 'default',
      notificationSound:
          json['notificationSound'] ?? json['notification_sound'] ?? 'default',
    );
  }

  ChatSettingsModel copyWith({
    int? id,
    bool? isPinned,
    bool? isMuted,
    DateTime? muteUntil,
    String? wallpaper,
    String? chatColor,
    String? notificationSound,
    bool clearMuteUntil = false,
  }) {
    return ChatSettingsModel(
      id: id ?? this.id,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      muteUntil: clearMuteUntil ? null : muteUntil ?? this.muteUntil,
      wallpaper: wallpaper ?? this.wallpaper,
      chatColor: chatColor ?? this.chatColor,
      notificationSound: notificationSound ?? this.notificationSound,
    );
  }
}

class UserPreferencesModel {
  final String wallpaper;
  final String chatColor;
  final String notificationSound;
  final int fontSize;
  final bool enterToSend;
  final bool readReceipts;
  final bool typingIndicators;
  final bool messagePreview;
  final String autoDownloadMedia;

  const UserPreferencesModel({
    required this.wallpaper,
    required this.chatColor,
    required this.notificationSound,
    required this.fontSize,
    required this.enterToSend,
    required this.readReceipts,
    required this.typingIndicators,
    required this.messagePreview,
    required this.autoDownloadMedia,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      wallpaper: json['wallpaper'] ?? 'default',
      chatColor: json['chatColor'] ?? 'default',
      notificationSound: json['notificationSound'] ?? 'default',
      fontSize: json['fontSize'] ?? 16,
      enterToSend: json['enterToSend'] ?? true,
      readReceipts: json['readReceipts'] ?? true,
      typingIndicators: json['typingIndicators'] ?? true,
      messagePreview: json['messagePreview'] ?? true,
      autoDownloadMedia: json['autoDownloadMedia'] ?? 'wifi',
    );
  }
}

class ChatState extends Equatable {
  final ChatStatus conversationsStatus;
  final ChatStatus messagesStatus;
  final ChatStatus settingsStatus;
  final ChatStatus preferencesStatus;

  final List<ConversationModel> conversations;
  final List<MessageModel> messages;
  final ConversationInfoModel? conversationInfo;
  final ChatSettingsModel? chatSettings;
  final UserPreferencesModel? userPreferences;

  final int currentPage;
  final bool hasMoreMessages;
  final int? activeConversationId;
  final String? error;

  const ChatState({
    this.conversationsStatus = ChatStatus.initial,
    this.messagesStatus = ChatStatus.initial,
    this.settingsStatus = ChatStatus.initial,
    this.preferencesStatus = ChatStatus.initial,
    this.conversations = const [],
    this.messages = const [],
    this.conversationInfo,
    this.chatSettings,
    this.userPreferences,
    this.currentPage = 1,
    this.hasMoreMessages = true,
    this.activeConversationId,
    this.error,
  });

  ChatState copyWith({
    ChatStatus? conversationsStatus,
    ChatStatus? messagesStatus,
    ChatStatus? settingsStatus,
    ChatStatus? preferencesStatus,
    List<ConversationModel>? conversations,
    List<MessageModel>? messages,
    ConversationInfoModel? conversationInfo,
    ChatSettingsModel? chatSettings,
    UserPreferencesModel? userPreferences,
    int? currentPage,
    bool? hasMoreMessages,
    int? activeConversationId,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      conversationsStatus: conversationsStatus ?? this.conversationsStatus,
      messagesStatus: messagesStatus ?? this.messagesStatus,
      settingsStatus: settingsStatus ?? this.settingsStatus,
      preferencesStatus: preferencesStatus ?? this.preferencesStatus,
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      conversationInfo: conversationInfo ?? this.conversationInfo,
      chatSettings: chatSettings ?? this.chatSettings,
      userPreferences: userPreferences ?? this.userPreferences,
      currentPage: currentPage ?? this.currentPage,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        conversationsStatus,
        messagesStatus,
        settingsStatus,
        preferencesStatus,
        conversations,
        messages,
        conversationInfo,
        chatSettings,
        userPreferences,
        currentPage,
        hasMoreMessages,
        activeConversationId,
        error,
      ];
}
