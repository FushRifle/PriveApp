// FeedPost Model - Matches backend FeedPost structure
class FeedPost {
  final int id;
  final UserInfo user;
  final String content;
  final List<Attachment> attachments;
  final String time;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final int reposts;
  final bool isLiked;
  final bool isSaved;
  final bool isReposted;
  final List<String> hashtags;
  final DateTime createdAt;
  final String postType;
  final bool isAnonymous;
  final String? anonymousCategory;
  final String? pollQuestion;
  final List<String> pollOptions;
  final int? pollExpirationHours;

  FeedPost({
    required this.id,
    required this.user,
    required this.content,
    required this.attachments,
    required this.time,
    required this.likes,
    required this.comments,
    this.shares = 0,
    this.saves = 0,
    this.reposts = 0,
    required this.isLiked,
    this.isSaved = false,
    this.isReposted = false,
    this.hashtags = const [],
    required this.createdAt,
    this.postType = 'standard',
    this.isAnonymous = false,
    this.anonymousCategory,
    this.pollQuestion,
    this.pollOptions = const [],
    this.pollExpirationHours,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: _toInt(json['id']),
      user: UserInfo.fromJson({
        ..._asMap(json['user']),
        'id': json['userId'] ?? json['user_id'] ?? _asMap(json['user'])['id'],
      }),
      content: json['content']?.toString() ?? '',
      attachments: _parseAttachments(json['attachments']),
      time: json['time']?.toString() ?? '',
      likes: _toInt(json['likes'] ??
          json['likesCount'] ??
          json['likes_count'] ??
          json['likeCount'] ??
          json['like_count'] ??
          json['_count']?['likes']),
      comments: _toInt(json['comments'] ??
          json['commentsCount'] ??
          json['comments_count'] ??
          json['commentCount'] ??
          json['comment_count'] ??
          json['_count']?['comments']),
      shares: _toInt(json['shares'] ?? json['shareCount']),
      saves: _toInt(json['saves'] ?? json['saveCount']),
      reposts: _toInt(json['reposts'] ?? json['repostCount']),
      isLiked: json['isLiked'] == true || json['is_liked'] == true,
      isSaved: json['isSaved'] == true || json['is_saved'] == true,
      isReposted: json['isReposted'] == true || json['is_reposted'] == true,
      hashtags: _parseStringList(json['hashtags']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      postType: (json['postType'] ?? json['post_type'] ?? 'standard')
          .toString()
          .trim()
          .toLowerCase(),
      isAnonymous: json['isAnonymous'] == true ||
          json['is_anonymous'] == true ||
          (json['postType']?.toString().toLowerCase() == 'anonymous') ||
          (json['post_type']?.toString().toLowerCase() == 'anonymous'),
      anonymousCategory: json['anonymousCategory']?.toString() ??
          json['anonymous_category']?.toString(),
      pollQuestion: json['pollQuestion']?.toString() ??
          json['poll_question']?.toString() ??
          json['pollTitle']?.toString() ??
          json['poll_title']?.toString(),
      pollOptions: _parseStringList(
        json['pollOptions'] ?? json['poll_options'] ?? json['options'],
      ),
      pollExpirationHours: _toIntOrNull(
        json['pollExpirationHours'] ??
            json['poll_expiration_hours'] ??
            json['expiresInHours'] ??
            json['expires_in_hours'],
      ),
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
        'shares': shares,
        'saves': saves,
        'reposts': reposts,
        'isLiked': isLiked,
        'isSaved': isSaved,
        'isReposted': isReposted,
        'hashtags': hashtags,
        'createdAt': createdAt.toIso8601String(),
        'postType': postType,
        'isAnonymous': isAnonymous,
        'anonymousCategory': anonymousCategory,
        'pollQuestion': pollQuestion,
        'pollOptions': pollOptions,
        'pollExpirationHours': pollExpirationHours,
      };

  FeedPost copyWith({
    int? id,
    UserInfo? user,
    String? content,
    List<Attachment>? attachments,
    String? time,
    int? likes,
    int? comments,
    int? shares,
    int? saves,
    int? reposts,
    bool? isLiked,
    bool? isSaved,
    bool? isReposted,
    List<String>? hashtags,
    DateTime? createdAt,
    String? postType,
    bool? isAnonymous,
    String? anonymousCategory,
    String? pollQuestion,
    List<String>? pollOptions,
    int? pollExpirationHours,
  }) {
    return FeedPost(
      id: id ?? this.id,
      user: user ?? this.user,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      time: time ?? this.time,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      saves: saves ?? this.saves,
      reposts: reposts ?? this.reposts,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isReposted: isReposted ?? this.isReposted,
      hashtags: hashtags ?? this.hashtags,
      createdAt: createdAt ?? this.createdAt,
      postType: postType ?? this.postType,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      anonymousCategory: anonymousCategory ?? this.anonymousCategory,
      pollQuestion: pollQuestion ?? this.pollQuestion,
      pollOptions: pollOptions ?? this.pollOptions,
      pollExpirationHours: pollExpirationHours ?? this.pollExpirationHours,
    );
  }

  bool get isPoll => postType == 'poll';
  bool get isQuestion => postType == 'question';
  bool get isDailyPrompt => postType == 'daily_prompt' || postType == 'prompt';
  bool get isAnonymousPost => isAnonymous || postType == 'anonymous';
  bool get isAIPost {
    final name = user.name.trim().toLowerCase();
    final handle = user.handle.trim().toLowerCase();

    return name == 'clique official' ||
        handle == 'clique_official' ||
        handle == 'official' ||
        handle == 'cliqueofficial';
  }
  bool get isStandardPost =>
      !isPoll && !isQuestion && !isDailyPrompt && !isAnonymousPost;

  String get contentTypeLabel {
    if (isAnonymousPost) {
      final category = _labelize(anonymousCategory ?? 'anonymous');
      return category == 'Anonymous' ? 'Anonymous' : 'Anonymous / $category';
    }
    return switch (postType) {
      'poll' => 'Poll',
      'question' => 'Question',
      'daily_prompt' || 'prompt' => 'Daily Prompt',
      'anonymous' => 'Anonymous',
      _ => 'Post',
    };
  }

  static String _labelize(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return 'Anonymous';
    return cleaned
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

// UserInfo Model
class UserInfo {
  final int id;
  final String name;
  final String handle;
  final String avatar;
  final bool verified;

  const UserInfo({
    this.id = 0,
    required this.name,
    required this.handle,
    required this.avatar,
    this.verified = false,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: _toInt(json['id'] ?? json['userId'] ?? json['user_id']),
      name: json['name']?.toString() ?? 'User',
      handle: json['handle']?.toString() ?? json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      verified: json['verified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'handle': handle,
        'avatar': avatar,
        'verified': verified,
      };

  UserInfo copyWith({
    int? id,
    String? name,
    String? handle,
    String? avatar,
    bool? verified,
  }) {
    return UserInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      avatar: avatar ?? this.avatar,
      verified: verified ?? this.verified,
    );
  }
}

// Attachment Model
class Attachment {
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
}

// Comment Model
class Comment {
  final int id;
  final int userId;
  final String userName;
  final String userAvatar;
  final String content;
  final String audioUrl;
  final int duration;
  final bool isVoiceNote;
  final int likes;
  final int dislikes;
  final int replyCount;
  final bool isLiked;
  final bool isDisliked;
  final int? parentCommentId;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    this.audioUrl = '',
    this.duration = 0,
    this.isVoiceNote = false,
    this.likes = 0,
    this.dislikes = 0,
    this.replyCount = 0,
    this.isLiked = false,
    this.isDisliked = false,
    this.parentCommentId,
    required this.createdAt,
  });

  bool get hasVoiceNote => isVoiceNote || audioUrl.trim().isNotEmpty;

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
      audioUrl:
          json['audioUrl']?.toString() ?? json['audio_url']?.toString() ?? '',
      duration: _toInt(json['duration']),
      isVoiceNote: json['isVoiceNote'] == true || json['is_voice_note'] == true,
      likes: _toInt(
        json['likes'] ??
            json['likesCount'] ??
            json['likes_count'] ??
            json['likeCount'] ??
            json['like_count'] ??
            json['_count']?['likes'],
      ),
      dislikes: _toInt(
        json['dislikes'] ??
            json['dislikesCount'] ??
            json['dislikes_count'] ??
            json['dislikeCount'] ??
            json['dislike_count'] ??
            json['_count']?['dislikes'],
      ),
      replyCount: _toInt(
        json['replyCount'] ??
            json['repliesCount'] ??
            json['reply_count'] ??
            json['_count']?['replies'],
      ),
      isLiked: json['isLiked'] == true || json['is_liked'] == true,
      isDisliked: json['isDisliked'] == true || json['is_disliked'] == true,
      parentCommentId: _toIntOrNull(
        json['parentCommentId'] ??
            json['parent_comment_id'] ??
            json['replyToCommentId'] ??
            json['reply_to_comment_id'],
      ),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': content,
        'audioUrl': audioUrl,
        'duration': duration,
        'isVoiceNote': isVoiceNote,
        'likes': likes,
        'dislikes': dislikes,
        'replyCount': replyCount,
        'isLiked': isLiked,
        'isDisliked': isDisliked,
        'parentCommentId': parentCommentId,
        'createdAt': createdAt.toIso8601String(),
      };

  Comment copyWith({
    int? id,
    int? userId,
    String? userName,
    String? userAvatar,
    String? content,
    String? audioUrl,
    int? duration,
    bool? isVoiceNote,
    int? likes,
    int? dislikes,
    int? replyCount,
    bool? isLiked,
    bool? isDisliked,
    int? parentCommentId,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      isVoiceNote: isVoiceNote ?? this.isVoiceNote,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      replyCount: replyCount ?? this.replyCount,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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

// UserMedia Model
class UserMedia {
  final int id;
  final int postId;
  final String type;
  final String url;
  final String? thumbnail;
  final String? caption;
  final int likes;
  final int comments;
  final DateTime createdAt;

  UserMedia({
    required this.id,
    required this.postId,
    required this.type,
    required this.url,
    this.thumbnail,
    this.caption,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  factory UserMedia.fromJson(Map<String, dynamic> json) {
    return UserMedia(
      id: _toInt(json['id']),
      postId: _toInt(json['postId'] ?? json['post_id']),
      type: json['type']?.toString() ?? 'image',
      url: json['url']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      caption: json['caption']?.toString(),
      likes: _toInt(json['likes'] ??
          json['likesCount'] ??
          json['likes_count'] ??
          json['likeCount'] ??
          json['like_count'] ??
          json['_count']?['likes']),
      comments: _toInt(json['comments'] ??
          json['commentsCount'] ??
          json['comments_count'] ??
          json['commentCount'] ??
          json['comment_count'] ??
          json['_count']?['comments']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'type': type,
        'url': url,
        if (thumbnail != null) 'thumbnail': thumbnail,
        if (caption != null) 'caption': caption,
        'likes': likes,
        'comments': comments,
        'createdAt': createdAt.toIso8601String(),
      };
}

// UserMediaResponse Model
class UserMediaResponse {
  final List<UserMedia> media;
  final bool hasMore;
  final int page;
  final int? total;

  UserMediaResponse({
    required this.media,
    required this.hasMore,
    required this.page,
    this.total,
  });

  factory UserMediaResponse.fromJson(Map<String, dynamic> json) {
    List<UserMedia> mediaList = [];

    final mediaSource = _findList(json, ['media', 'data', 'items', 'results']);
    mediaList =
        mediaSource.map((item) => UserMedia.fromJson(_asMap(item))).toList();

    return UserMediaResponse(
      media: mediaList,
      hasMore: json['hasMore'] == true || json['has_more'] == true,
      page: _toInt(json['page'], defaultValue: 1),
      total: json['total'],
    );
  }

  UserMediaResponse copyWith({
    List<UserMedia>? media,
    bool? hasMore,
    int? page,
    int? total,
  }) {
    return UserMediaResponse(
      media: media ?? this.media,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

// Request Models
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

class CreateCommentRequest {
  final String content;
  final String? audioUrl;
  final int? duration;

  const CreateCommentRequest({
    required this.content,
    this.audioUrl,
    this.duration,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        if (audioUrl != null && audioUrl!.isNotEmpty) 'audioUrl': audioUrl,
        if (duration != null) 'duration': duration,
      };
}

// Response Wrappers
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

  PostsResponse copyWith({
    List<FeedPost>? posts,
    bool? hasMore,
    int? page,
  }) {
    return PostsResponse(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
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

  CommentsResponse copyWith({
    List<Comment>? comments,
    bool? hasMore,
    int? page,
  }) {
    return CommentsResponse(
      comments: comments ?? this.comments,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

// Helper Functions
int _toInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  if (value is List) return value.length;
  if (value is Map) {
    return _toInt(
      value['count'] ?? value['_count'] ?? value['total'],
      defaultValue: defaultValue,
    );
  }
  return defaultValue;
}

List<dynamic> _findList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) return value;
    if (value is Map) {
      final nested = _findList(_asMap(value), keys);
      if (nested.isNotEmpty) return nested;
    }
  }

  return const [];
}

int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
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

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().replaceFirst('#', '').trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((item) => item.replaceFirst('#', '').trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  return const [];
}
