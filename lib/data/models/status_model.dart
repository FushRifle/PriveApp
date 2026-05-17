import 'package:equatable/equatable.dart';

class Story extends Equatable {
  final String id;
  final int userId;
  final StoryUser user;
  final String? content;
  final List<Attachment> attachments;
  final String time;
  final bool isMe;
  final bool isSeen;
  final int viewCount;
  final String? backgroundColor;
  final String? textAlign;
  final double? fontSize;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Story({
    required this.id,
    required this.userId,
    required this.user,
    this.content,
    this.attachments = const [],
    required this.time,
    this.isMe = false,
    this.isSeen = false,
    this.viewCount = 0,
    this.backgroundColor,
    this.textAlign,
    this.fontSize,
    required this.createdAt,
    required this.expiresAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? 0,
      user: StoryUser.fromJson(json['user'] ?? {}),
      content: json['content'],
      attachments: (json['attachments'] as List?)
              ?.map((a) => Attachment.fromJson(a))
              .toList() ??
          [],
      time: json['time'] ?? '',
      isMe: json['isMe'] ?? false,
      isSeen: json['isSeen'] ?? false,
      viewCount: json['viewCount'] ?? 0,
      backgroundColor: json['backgroundColor'],
      textAlign: json['textAlign'],
      fontSize: json['fontSize']?.toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expiresAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'user': user.toJson(),
      'content': content,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'time': time,
      'isMe': isMe,
      'isSeen': isSeen,
      'viewCount': viewCount,
      'backgroundColor': backgroundColor,
      'textAlign': textAlign,
      'fontSize': fontSize,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  Story copyWith({
    String? id,
    int? userId,
    StoryUser? user,
    String? content,
    List<Attachment>? attachments,
    String? time,
    bool? isMe,
    bool? isSeen,
    int? viewCount,
    String? backgroundColor,
    String? textAlign,
    double? fontSize,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Story(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      time: time ?? this.time,
      isMe: isMe ?? this.isMe,
      isSeen: isSeen ?? this.isSeen,
      viewCount: viewCount ?? this.viewCount,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textAlign: textAlign ?? this.textAlign,
      fontSize: fontSize ?? this.fontSize,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
        id,
        userId,
        user,
        content,
        attachments,
        time,
        isMe,
        isSeen,
        viewCount,
        backgroundColor,
        textAlign,
        fontSize,
        createdAt,
        expiresAt,
      ];
}

class StoryUser extends Equatable {
  final int id;
  final String name;
  final String username;
  final String handle;
  final String avatar;
  final bool verified;

  const StoryUser({
    required this.id,
    required this.name,
    required this.username,
    required this.handle,
    required this.avatar,
    this.verified = false,
  });

  factory StoryUser.fromJson(Map<String, dynamic> json) {
    return StoryUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      handle: json['handle'] ?? json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'handle': handle,
      'avatar': avatar,
      'verified': verified,
    };
  }

  StoryUser copyWith({
    int? id,
    String? name,
    String? username,
    String? handle,
    String? avatar,
    bool? verified,
  }) {
    return StoryUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      handle: handle ?? this.handle,
      avatar: avatar ?? this.avatar,
      verified: verified ?? this.verified,
    );
  }

  @override
  List<Object?> get props => [id, name, username, handle, avatar, verified];
}

class Attachment extends Equatable {
  final String? id;
  final String type;
  final String url;
  final String? uri;
  final String? thumbnail;
  final int? width;
  final int? height;
  final DateTime? createdAt;

  const Attachment({
    this.id,
    required this.type,
    required this.url,
    this.uri,
    this.thumbnail,
    this.width,
    this.height,
    this.createdAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id']?.toString(),
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      uri: json['uri'],
      thumbnail: json['thumbnail'],
      width: json['width'],
      height: json['height'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'url': url,
      if (uri != null) 'uri': uri,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
    };
  }

  Attachment copyWith({
    String? id,
    String? type,
    String? url,
    String? uri,
    String? thumbnail,
    int? width,
    int? height,
    DateTime? createdAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      type: type ?? this.type,
      url: url ?? this.url,
      uri: uri ?? this.uri,
      thumbnail: thumbnail ?? this.thumbnail,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        url,
        uri,
        thumbnail,
        width,
        height,
        createdAt,
      ];
}
