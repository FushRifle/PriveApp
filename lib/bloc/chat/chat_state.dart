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
  final bool isVerified;
  final String wallpaper;
  final String chatColor;
  final String notificationSound;

  ConversationModel({
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
    required this.muteUntil,
    this.isVerified = false,
    this.wallpaper = 'default',
    this.chatColor = 'default',
    this.notificationSound = 'default',
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      name: json['name'] ?? 'User',
      username: json['username'] ?? 'User',
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
      isVerified: json['verified'] == true || json['isVerified'] == true,
    );
  }

  bool get isMutedForever => isMuted && muteUntil == null;
  bool get isMutedTemporarily =>
      isMuted && muteUntil != null && muteUntil!.isAfter(DateTime.now());
}

class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final String messageType;
  final String? mediaUrl;
  final bool isRead;
  final bool isOwn;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.messageType,
    this.mediaUrl,
    required this.isRead,
    required this.isOwn,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      senderId: json['senderId'] ?? 0,
      receiverId: json['receiverId'] ?? 0,
      message: json['message'] ?? '',
      messageType: json['messageType'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      isRead: json['isRead'] ?? false,
      isOwn: json['isOwn'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
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

  ConversationInfoModel({
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

  ChatSettingsModel({
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

  UserPreferencesModel({
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
  final bool isTyping;
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
    this.isTyping = false,
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
    bool? isTyping,
    String? error,
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
      isTyping: isTyping ?? this.isTyping,
      error: error ?? this.error,
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
        isTyping,
        error
      ];
}
