import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatModel {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;

  const ChatModel({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isTyping = false,
  });

  types.User toUser() {
    return types.User(
      id: id,
      firstName: name,
      imageUrl: avatar,
    );
  }
}


