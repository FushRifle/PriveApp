class PostModel {
  final int id;
  final int userId;
  final String name;
  final String imgProfile;
  final String picture;
  final String pictureHash;
  final String caption;
  final List<String> hashtags;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final bool isSaved;
  final String? content; // For text-only posts
  final String? postType; // 'image', 'video', 'text'
  final DateTime createdAt;
  final bool isPrivate;
  final String? backgroundColor;
  final String? textAlign;
  final double? fontSize;

  const PostModel({
    this.id = 0,
    this.userId = 0,
    required this.name,
    required this.imgProfile,
    this.picture = '',
    this.pictureHash = '',
    this.caption = '',
    this.hashtags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.content,
    this.postType,
    required this.createdAt,
    this.isPrivate = false,
    this.backgroundColor,
    this.textAlign,
    this.fontSize,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']);
    final attachments = json['attachments'];

    // Determine post type
    String? postType = json['postType'] ?? json['post_type'];
    String? content = json['content'] ?? json['statusText'];

    // Auto-detect text-only post
    if (postType == null) {
      if (content != null &&
          content.isNotEmpty &&
          (attachments == null || attachments.isEmpty)) {
        postType = 'text';
      } else {
        postType = 'image';
      }
    }

    String picture = '';

    // Only get picture if it's not a text post
    if (postType != 'text' && attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        picture = (first['url'] ?? first['uri'] ?? '').toString();
      } else if (first is String) {
        picture = first;
      }
    }

    // If still no picture, check direct fields
    if (picture.isEmpty && postType != 'text') {
      picture = (json['picture'] ??
              json['image'] ??
              json['imageUrl'] ??
              json['image_url'] ??
              json['mediaUrl'] ??
              '')
          .toString();
    }

    // Parse caption or content
    String caption = json['caption']?.toString() ?? '';
    if (caption.isEmpty && content != null && postType == 'text') {
      caption = content;
    }

    // Parse background color for text posts
    String? backgroundColor =
        json['backgroundColor'] ?? json['background_color'] ?? json['bgColor'];

    // Parse text alignment
    String? textAlign = json['textAlign'] ?? json['text_align'];

    // Parse font size
    double? fontSize;
    if (json['fontSize'] != null) {
      fontSize = _toDouble(json['fontSize']);
    } else if (json['font_size'] != null) {
      fontSize = _toDouble(json['font_size']);
    }

    return PostModel(
      id: _toInt(json['id']),
      userId: _toInt(json['userId'] ?? json['user_id'] ?? user['id']),
      name: _getDisplayName(user, json),
      imgProfile: _getAvatarUrl(user, json),
      picture: picture,
      pictureHash:
          (json['pictureHash'] ?? json['picture_hash'] ?? '').toString(),
      caption: caption,
      hashtags: _toStringList(json['hashtags'] ?? json['hashtag']),
      likeCount: _toInt(json['like'] ??
          json['likes'] ??
          json['likesCount'] ??
          json['likeCount']),
      commentCount: _toInt(json['comment'] ??
          json['comments'] ??
          json['commentsCount'] ??
          json['commentCount']),
      shareCount: _toInt(json['share'] ??
          json['shares'] ??
          json['sharesCount'] ??
          json['shareCount']),
      isLiked: json['isLiked'] == true || json['is_liked'] == true,
      isSaved: json['isSaved'] == true || json['is_saved'] == true,
      content: content,
      postType: postType,
      createdAt: _parseDateTime(
          json['createdAt'] ?? json['created_at'] ?? json['time']),
      isPrivate: json['isPrivate'] == true || json['is_private'] == true,
      backgroundColor: backgroundColor,
      textAlign: textAlign,
      fontSize: fontSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'imgProfile': imgProfile,
        'picture': picture,
        'pictureHash': pictureHash,
        'caption': caption,
        'hashtags': hashtags,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'shareCount': shareCount,
        'isLiked': isLiked,
        'isSaved': isSaved,
        'content': content,
        'postType': postType,
        'createdAt': createdAt.toIso8601String(),
        'isPrivate': isPrivate,
        'backgroundColor': backgroundColor,
        'textAlign': textAlign,
        'fontSize': fontSize,
      };

  // Helper getters
  bool get isTextOnly =>
      postType == 'text' ||
      (content != null && content!.isNotEmpty && picture.isEmpty);
  bool get hasImage => picture.isNotEmpty;
  String get displayText => content ?? caption;

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

  String get formattedLikeCount {
    if (likeCount >= 1000000) {
      return '${(likeCount / 1000000).toStringAsFixed(1)}M';
    } else if (likeCount >= 1000) {
      return '${(likeCount / 1000).toStringAsFixed(1)}K';
    }
    return likeCount.toString();
  }

  String get formattedCommentCount {
    if (commentCount >= 1000000) {
      return '${(commentCount / 1000000).toStringAsFixed(1)}M';
    } else if (commentCount >= 1000) {
      return '${(commentCount / 1000).toStringAsFixed(1)}K';
    }
    return commentCount.toString();
  }

  String get formattedShareCount {
    if (shareCount >= 1000000) {
      return '${(shareCount / 1000000).toStringAsFixed(1)}M';
    } else if (shareCount >= 1000) {
      return '${(shareCount / 1000).toStringAsFixed(1)}K';
    }
    return shareCount.toString();
  }

  String get effectiveBackgroundColor {
    if (backgroundColor != null && backgroundColor!.isNotEmpty) {
      return backgroundColor!;
    }
    return isTextOnly ? '#1D1B20' : '#000000';
  }

  String get effectiveTextAlign => textAlign ?? 'center';
  double get effectiveFontSize => fontSize ?? 18.0;
}

// Helper functions
String _getDisplayName(Map<String, dynamic> user, Map<String, dynamic> json) {
  final name = user['name'] ?? json['name'];
  final username = user['username'] ?? json['username'];
  final email = user['email'] ?? json['email'];

  if (name != null && name.toString().trim().isNotEmpty) {
    return name.toString();
  }
  if (username != null && username.toString().trim().isNotEmpty) {
    return username.toString();
  }
  if (email != null && email.toString().trim().isNotEmpty) {
    return email.toString().split('@').first;
  }
  return 'User';
}

String _getAvatarUrl(Map<String, dynamic> user, Map<String, dynamic> json) {
  return (user['avatar'] ??
          user['avatarUrl'] ??
          user['avatar_url'] ??
          json['imgProfile'] ??
          json['avatar'] ??
          json['profileImage'] ??
          '')
      .toString();
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

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 18.0;
  return 18.0;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    return value.split(',').map((e) => e.trim()).toList();
  }
  return [];
}
