import 'package:flutter/material.dart';

// ============================================================================
// FeedPost Model - Matches backend FeedPost structure
// ============================================================================
class FeedPost {
  final int id;
  final UserInfo user;
  final String content;
  final List<Attachment> attachments;
  final String time;
  final int likes;
  final int comments;
  final bool isLiked;
  final DateTime createdAt;

  FeedPost({
    required this.id,
    required this.user,
    required this.content,
    required this.attachments,
    required this.time,
    required this.likes,
    required this.comments,
    required this.isLiked,
    required this.createdAt,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: _toInt(json['id']),
      user: UserInfo.fromJson(_asMap(json['user'])),
      content: json['content']?.toString() ?? '',
      attachments: _parseAttachments(json['attachments']),
      time: json['time']?.toString() ?? '',
      likes: _toInt(json['likes']),
      comments: _toInt(json['comments']),
      isLiked: json['isLiked'] == true || json['is_liked'] == true,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': user.toJson(),
        'content': content,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'time': time,
        'likes': likes,
        'comments': comments,
        'isLiked': isLiked,
        'createdAt': createdAt.toIso8601String(),
      };

  // Helper to convert to PostModel (your existing model)
  Map<String, dynamic> toPostModelJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'content': content,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'likes': likes,
      'comments': comments,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// ============================================================================
// UserInfo Model
// ============================================================================
class UserInfo {
  final String name;
  final String handle;
  final String avatar;
  final bool verified;

  const UserInfo({
    required this.name,
    required this.handle,
    required this.avatar,
    this.verified = false,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      name: json['name']?.toString() ?? 'User',
      handle: json['handle']?.toString() ?? json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      verified: json['verified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'handle': handle,
        'avatar': avatar,
        'verified': verified,
      };
}

// ============================================================================
// Attachment Model
// ============================================================================
class Attachment {
  final String? id;
  final String type; // 'image', 'video', 'audio'
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
      type: json['type']?.toString() ?? 'image',
      url: json['url']?.toString() ?? '',
      uri: json['uri']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      width: _toIntOrNull(json['width']),
      height: _toIntOrNull(json['height']),
      createdAt: _parseDateTimeOrNull(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
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

// ============================================================================
// Story Model - Matches backend Story structure
// ============================================================================
class Story {
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
    required this.attachments,
    required this.time,
    required this.isMe,
    required this.isSeen,
    required this.viewCount,
    this.backgroundColor,
    this.textAlign,
    this.fontSize,
    required this.createdAt,
    required this.expiresAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id']?.toString() ?? '',
      userId: _toInt(json['userId'] ?? json['user_id']),
      user: StoryUser.fromJson(_asMap(json['user'])),
      content: json['content']?.toString(),
      attachments: _parseAttachments(json['attachments']),
      time: json['time']?.toString() ?? '',
      isMe: json['isMe'] == true || json['is_me'] == true,
      isSeen: json['isSeen'] == true || json['is_seen'] == true,
      viewCount: _toInt(json['viewCount'] ?? json['view_count']),
      backgroundColor: json['backgroundColor']?.toString() ??
          json['background_color']?.toString(),
      textAlign:
          json['textAlign']?.toString() ?? json['text_align']?.toString(),
      fontSize: _toDoubleOrNull(json['fontSize'] ?? json['font_size']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      expiresAt: _parseDateTime(json['expiresAt'] ?? json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'user': user.toJson(),
        if (content != null) 'content': content,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'time': time,
        'isMe': isMe,
        'isSeen': isSeen,
        'viewCount': viewCount,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        if (textAlign != null) 'textAlign': textAlign,
        if (fontSize != null) 'fontSize': fontSize,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  double get effectiveFontSize => fontSize ?? 24.0;

  String get effectiveBackgroundColor => backgroundColor ?? '#1D1B20';

  TextAlign get effectiveTextAlign {
    switch (textAlign?.toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  bool get hasMedia => attachments.isNotEmpty;
  bool get hasImage => attachments.any((a) => a.type == 'image');
  bool get hasVideo => attachments.any((a) => a.type == 'video');
  String? get firstMediaUrl =>
      attachments.isNotEmpty ? attachments.first.url : null;
}

// ============================================================================
// StoryUser Model - User info within story context
// ============================================================================
class StoryUser {
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
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'User',
      username: json['username']?.toString() ?? '',
      handle: json['handle']?.toString() ?? json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      verified: json['verified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'handle': handle,
        'avatar': avatar,
        'verified': verified,
      };
}

// ============================================================================
// Comment Model - Matches backend Comment structure
// ============================================================================
class Comment {
  final int id;
  final int userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: _toInt(json['id']),
      userId: _toInt(json['userId'] ?? json['user_id']),
      userName: json['userName']?.toString() ??
          json['user_name']?.toString() ??
          'User',
      userAvatar: json['userAvatar']?.toString() ??
          json['user_avatar']?.toString() ??
          '',
      content: json['content']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  String get formattedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

// ============================================================================
// Request Models
// ============================================================================
class CreatePostRequest {
  final String content;
  final List<Attachment> attachments;

  const CreatePostRequest({
    required this.content,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        if (attachments.isNotEmpty)
          'attachments': attachments.map((a) => a.toJson()).toList(),
      };
}

class CreateStoryRequest {
  final String? content;
  final List<Attachment> attachments;
  final String? backgroundColor;
  final String? textAlign;
  final double? fontSize;

  const CreateStoryRequest({
    this.content,
    this.attachments = const [],
    this.backgroundColor,
    this.textAlign,
    this.fontSize,
  });

  Map<String, dynamic> toJson() => {
        if (content != null && content!.isNotEmpty) 'content': content,
        if (attachments.isNotEmpty)
          'attachments': attachments.map((a) => a.toJson()).toList(),
        if (backgroundColor != null && backgroundColor!.isNotEmpty)
          'backgroundColor': backgroundColor,
        if (textAlign != null && textAlign!.isNotEmpty) 'textAlign': textAlign,
        if (fontSize != null) 'fontSize': fontSize,
      };
}

class CreateCommentRequest {
  final String content;

  const CreateCommentRequest({required this.content});

  Map<String, dynamic> toJson() => {'content': content};
}

// ============================================================================
// Response Wrappers
// ============================================================================
class PostsResponse {
  final List<FeedPost> posts;
  final bool hasMore;
  final int page;

  const PostsResponse({
    required this.posts,
    required this.hasMore,
    required this.page,
  });

  factory PostsResponse.fromJson(Map<String, dynamic> json) {
    List<FeedPost> posts = [];

    if (json['posts'] is List) {
      posts = (json['posts'] as List)
          .map((p) => FeedPost.fromJson(_asMap(p)))
          .toList();
    } else if (json['data'] is List) {
      posts = (json['data'] as List)
          .map((p) => FeedPost.fromJson(_asMap(p)))
          .toList();
    }

    return PostsResponse(
      posts: posts,
      hasMore: json['hasMore'] == true || json['has_more'] == true,
      page: _toInt(json['page'], defaultValue: 1),
    );
  }
}

class CommentsResponse {
  final List<Comment> comments;
  final bool hasMore;
  final int page;

  const CommentsResponse({
    required this.comments,
    required this.hasMore,
    required this.page,
  });

  factory CommentsResponse.fromJson(Map<String, dynamic> json) {
    List<Comment> comments = [];

    if (json['comments'] is List) {
      comments = (json['comments'] as List)
          .map((c) => Comment.fromJson(_asMap(c)))
          .toList();
    } else if (json['data'] is List) {
      comments = (json['data'] as List)
          .map((c) => Comment.fromJson(_asMap(c)))
          .toList();
    }

    return CommentsResponse(
      comments: comments,
      hasMore: json['hasMore'] == true || json['has_more'] == true,
      page: _toInt(json['page'], defaultValue: 1),
    );
  }

  get length => null;
}

// ============================================================================
// Helper Functions
// ============================================================================
int _toInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double _toDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

DateTime? _parseDateTimeOrNull(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<Attachment> _parseAttachments(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((a) => Attachment.fromJson(_asMap(a)))
        .toList();
  }
  return [];
}
