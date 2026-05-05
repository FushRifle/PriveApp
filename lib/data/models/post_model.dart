class PostModel {
  final int id;
  final String name;
  final String imgProfile;
  final String picture;
  final String pictureHash;
  final String caption;
  final List<String> hashtags;
  final int like;
  final int comment;
  final int share;
  final bool isLiked;

  const PostModel({
    this.id = 0,
    required this.name,
    required this.imgProfile,
    required this.picture,
    this.pictureHash = '',
    required this.caption,
    this.hashtags = const [],
    this.like = 0,
    this.comment = 0,
    this.share = 0,
    this.isLiked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']);
    final attachments = json['attachments'];

    String picture = '';

    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;

      if (first is Map) {
        picture = (first['url'] ?? first['uri'] ?? '').toString();
      } else if (first is String) {
        picture = first;
      }
    }

    return PostModel(
      id: _toInt(json['id']),
      name: (user['name'] ??
              user['username'] ??
              json['name'] ??
              json['username'] ??
              'User')
          .toString(),
      imgProfile: (user['avatar'] ??
              user['avatarUrl'] ??
              user['avatar_url'] ??
              json['imgProfile'] ??
              json['avatar'] ??
              '')
          .toString(),
      picture: picture.isNotEmpty
          ? picture
          : (json['picture'] ??
                  json['image'] ??
                  json['imageUrl'] ??
                  json['image_url'] ??
                  '')
              .toString(),
      pictureHash:
          (json['pictureHash'] ?? json['picture_hash'] ?? '').toString(),
      caption: (json['caption'] ?? json['content'] ?? '').toString(),
      hashtags: _toStringList(json['hashtags'] ?? json['hashtag']),
      like: _toInt(json['like'] ?? json['likes'] ?? json['likesCount']),
      comment:
          _toInt(json['comment'] ?? json['comments'] ?? json['commentsCount']),
      share: _toInt(json['share'] ?? json['shares'] ?? json['sharesCount']),
      isLiked: json['isLiked'] == true || json['is_liked'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imgProfile': imgProfile,
        'picture': picture,
        'pictureHash': pictureHash,
        'caption': caption,
        'hashtags': hashtags,
        'like': like,
        'comment': comment,
        'share': share,
        'isLiked': isLiked,
      };
}

class StatusModel {
  final int id;
  final int userId;
  final String name;
  final String imgProfile;
  final String statusImage;
  final String statusImageHash;
  final String time;
  final bool isViewed;
  final int viewCount;

  const StatusModel({
    this.id = 0,
    this.userId = 0,
    required this.name,
    required this.imgProfile,
    required this.statusImage,
    this.statusImageHash = '',
    required this.time,
    this.isViewed = false,
    this.viewCount = 0,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']);
    final attachments = json['attachments'];

    String statusImage = '';

    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;

      if (first is Map) {
        statusImage = (first['url'] ?? first['uri'] ?? '').toString();
      } else if (first is String) {
        statusImage = first;
      }
    }

    return StatusModel(
      id: _toInt(json['id']),
      userId: _toInt(json['userId'] ?? json['user_id'] ?? user['id']),
      name: (user['name'] ??
              user['username'] ??
              json['name'] ??
              json['username'] ??
              'User')
          .toString(),
      imgProfile: (user['avatar'] ??
              user['avatarUrl'] ??
              user['avatar_url'] ??
              json['imgProfile'] ??
              json['avatar'] ??
              '')
          .toString(),
      statusImage: statusImage.isNotEmpty
          ? statusImage
          : (json['statusImage'] ??
                  json['status_image'] ??
                  json['image'] ??
                  json['imageUrl'] ??
                  json['image_url'] ??
                  '')
              .toString(),
      statusImageHash:
          (json['statusImageHash'] ?? json['status_image_hash'] ?? '')
              .toString(),
      time: (json['time'] ?? json['createdAt'] ?? json['created_at'] ?? '')
          .toString(),
      isViewed: json['isViewed'] == true ||
          json['isSeen'] == true ||
          json['is_seen'] == true,
      viewCount: _toInt(json['viewCount'] ?? json['view_count']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'imgProfile': imgProfile,
        'statusImage': statusImage,
        'statusImageHash': statusImageHash,
        'time': time,
        'isViewed': isViewed,
        'viewCount': viewCount,
      };
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
    return [value];
  }

  return [];
}
