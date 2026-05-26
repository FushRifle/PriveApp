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
      userId: json['userId'] ?? 0,
      name: json['name'] ?? 'User',
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      age: json['age'] ?? 0,
      verified: json['verified'] ?? false,
      lastMessage: json['lastMessage'] ?? '',
      lastMessageType: json['lastMessageType'] ?? 'text',
      timestamp: json['timestamp'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      isTyping: json['isTyping'] ?? false,
      isPinned: json['isPinned'] ?? false,
      isMuted: json['isMuted'] ?? false,
      muteUntil: json['muteUntil'] != null
          ? DateTime.tryParse(json['muteUntil'])
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
  final int senderId;
  final int receiverId;
  final String message;
  final String messageType;
  final String? mediaUrl;
  final int? replyToId;
  final String? replyToMessage;
  final String? replyToSender;
  final bool isRead;
  final bool isOwn;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId, // ADD THIS
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.messageType,
    this.mediaUrl,
    this.replyToId,
    this.replyToMessage,
    this.replyToSender,
    required this.isRead,
    required this.isOwn,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? 0,
      senderId: json['senderId'] ?? 0,
      receiverId: json['receiverId'] ?? 0,
      message: json['message'] ?? '',
      messageType: json['messageType'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      replyToId: json['replyToId'],
      replyToMessage: json['replyToMessage'],
      replyToSender: json['replyToSender'],
      isRead: json['isRead'] ?? false,
      isOwn: json['isOwn'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId, // ADD THIS
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'replyToId': replyToId,
      'replyToMessage': replyToMessage,
      'replyToSender': replyToSender,
      'isRead': isRead,
      'isOwn': isOwn,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    int? receiverId,
    String? message,
    String? messageType,
    String? mediaUrl,
    int? replyToId,
    String? replyToMessage,
    String? replyToSender,
    bool? isRead,
    bool? isOwn,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      replyToSender: replyToSender ?? this.replyToSender,
      isRead: isRead ?? this.isRead,
      isOwn: isOwn ?? this.isOwn,
      createdAt: createdAt ?? this.createdAt,
    );
  }
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
      isPinned: json['isPinned'] ?? false,
      isMuted: json['isMuted'] ?? false,
      muteUntil: json['muteUntil'] != null
          ? DateTime.tryParse(json['muteUntil'])
          : null,
      wallpaper: json['wallpaper'] ?? 'default',
      chatColor: json['chatColor'] ?? 'default',
      notificationSound: json['notificationSound'] ?? 'default',
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
        error,
      ];
}
