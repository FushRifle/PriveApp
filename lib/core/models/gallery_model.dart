// gallery_model.dart
import 'package:equatable/equatable.dart';

class GalleryModel extends Equatable {
  final String? id;
  final int? postId;
  final String image;
  final String? thumbnail;
  final String? videoUrl;
  final String type; // 'image' or 'video'
  final String like;
  final int likesCount;
  final int commentsCount;
  final String? caption;
  final dynamic createdAt;
  final DateTime? createdAtDate;
  final bool isLiked;

  const GalleryModel({
    this.id,
    this.postId,
    required this.image,
    this.thumbnail,
    this.videoUrl,
    required this.type,
    required this.like,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.caption,
    this.createdAt,
    this.createdAtDate,
    this.isLiked = false,
  });

  factory GalleryModel.fromJson(Map<String, dynamic> json) {
    // Extract likes count from various possible formats
    int likesCount = 0;
    if (json['likes'] != null) {
      if (json['likes'] is int) {
        likesCount = json['likes'];
      } else if (json['likes'] is String) {
        likesCount = int.tryParse(json['likes']) ?? 0;
      } else if (json['likes'] is Map) {
        likesCount = json['likes']['count'] ?? 0;
      }
    } else if (json['likesCount'] != null) {
      likesCount = json['likesCount'] is int
          ? json['likesCount']
          : int.tryParse(json['likesCount'].toString()) ?? 0;
    } else if (json['like'] != null) {
      if (json['like'] is int) {
        likesCount = json['like'];
      } else if (json['like'] is String) {
        likesCount = int.tryParse(json['like']) ?? 0;
      }
    }

    // Extract comments count
    int commentsCount = 0;
    if (json['comments'] != null) {
      if (json['comments'] is int) {
        commentsCount = json['comments'];
      } else if (json['comments'] is String) {
        commentsCount = int.tryParse(json['comments']) ?? 0;
      }
    } else if (json['commentsCount'] != null) {
      commentsCount = json['commentsCount'] is int
          ? json['commentsCount']
          : int.tryParse(json['commentsCount'].toString()) ?? 0;
    }

    // Parse date
    DateTime? createdAtDate;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is DateTime) {
        createdAtDate = json['createdAt'];
      } else if (json['createdAt'] is String) {
        createdAtDate = DateTime.tryParse(json['createdAt']);
      }
    }

    // Format likes string
    final likeString = _formatLikes(likesCount);

    return GalleryModel(
      id: json['id']?.toString(),
      postId: json['postId'] ?? json['post_id'],
      image: json['image'] ?? json['url'] ?? '',
      thumbnail: json['thumbnail'] ?? json['thumb'],
      videoUrl: json['videoUrl'] ?? json['video_url'],
      type: json['type'] ?? 'image',
      like: json['like']?.toString() ?? likeString,
      likesCount: likesCount,
      commentsCount: commentsCount,
      caption: json['caption'] ?? json['content'],
      createdAt: json['createdAt'],
      createdAtDate: createdAtDate,
      isLiked: json['isLiked'] ?? json['is_liked'] ?? false,
    );
  }

  // Factory method specifically for UserMedia from FeedService
  factory GalleryModel.fromUserMedia(UserMedia userMedia) {
    return GalleryModel(
      id: userMedia.id.toString(),
      postId: userMedia.postId,
      image: userMedia.url,
      thumbnail: userMedia.thumbnail,
      videoUrl: userMedia.type == 'video' ? userMedia.url : null,
      type: userMedia.type,
      like: _formatLikes(userMedia.likes),
      likesCount: userMedia.likes,
      commentsCount: userMedia.comments,
      caption: userMedia.caption,
      createdAt: userMedia.createdAt,
      createdAtDate: userMedia.createdAt,
      isLiked: false, // You might want to fetch this separately
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'image': image,
      'thumbnail': thumbnail,
      'videoUrl': videoUrl,
      'type': type,
      'like': like,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'caption': caption,
      'createdAt': createdAt?.toIso8601String() ?? createdAt,
      'isLiked': isLiked,
    };
  }

  // Helper method to format likes
  static String _formatLikes(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // Get formatted date string
  String getFormattedDate() {
    if (createdAtDate != null) {
      final now = DateTime.now();
      final difference = now.difference(createdAtDate!);

      if (difference.inDays > 7) {
        return '${createdAtDate!.month}/${createdAtDate!.day}/${createdAtDate!.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    }
    return '';
  }

  // Create a copy with updated fields
  GalleryModel copyWith({
    String? id,
    int? postId,
    String? image,
    String? thumbnail,
    String? videoUrl,
    String? type,
    String? like,
    int? likesCount,
    int? commentsCount,
    String? caption,
    dynamic createdAt,
    DateTime? createdAtDate,
    bool? isLiked,
  }) {
    return GalleryModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      image: image ?? this.image,
      thumbnail: thumbnail ?? this.thumbnail,
      videoUrl: videoUrl ?? this.videoUrl,
      type: type ?? this.type,
      like: like ?? this.like,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      createdAtDate: createdAtDate ?? this.createdAtDate,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  @override
  List<Object?> get props => [
        id,
        postId,
        image,
        thumbnail,
        videoUrl,
        type,
        like,
        likesCount,
        commentsCount,
        caption,
        createdAt,
        createdAtDate,
        isLiked
      ];
}

// UserMedia model (if not already in a separate file)
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
      id: json['id'] ?? 0,
      postId: json['postId'] ?? json['post_id'] ?? 0,
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'],
      caption: json['caption'],
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'type': type,
      'url': url,
      'thumbnail': thumbnail,
      'caption': caption,
      'likes': likes,
      'comments': comments,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
