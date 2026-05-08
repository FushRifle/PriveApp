class ReelModel {
  final String id;
  final int userId;
  final String username;
  final String userProfile;
  final String videoUrl;
  final String caption;
  final List<String> hashtags;
  final String audio;
  final String audioArtist;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isVerified;
  final bool isLiked;

  const ReelModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfile,
    required this.videoUrl,
    required this.caption,
    required this.hashtags,
    required this.audio,
    required this.audioArtist,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.isVerified,
    this.isLiked = false,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] ?? json['userId'] ?? json['user']['id'] ?? 0,
      username: json['username'] ??
          json['user']['username'] ??
          json['user']['name'] ??
          '',
      userProfile: json['userProfile'] ??
          json['user']['image'] ??
          json['user']['avatar'] ??
          '',
      videoUrl: json['videoUrl'] ?? json['url'] ?? '',
      caption: json['caption'] ?? '',
      hashtags:
          json['hashtags'] != null ? List<String>.from(json['hashtags']) : [],
      audio: json['audio'] ?? json['music'] ?? 'Original Sound',
      audioArtist: json['audioArtist'] ?? json['user']['name'] ?? '',
      likeCount: json['likeCount'] ?? json['likes'] ?? 0,
      commentCount: json['commentCount'] ?? json['comments'] ?? 0,
      shareCount: json['shareCount'] ?? json['shares'] ?? 0,
      isVerified: json['isVerified'] ?? json['user']['verified'] ?? false,
      isLiked: json['isLiked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfile': userProfile,
      'videoUrl': videoUrl,
      'caption': caption,
      'hashtags': hashtags,
      'audio': audio,
      'audioArtist': audioArtist,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'isVerified': isVerified,
      'isLiked': isLiked,
    };
  }

  ReelModel copyWith({
    String? id,
    int? userId,
    String? username,
    String? userProfile,
    String? videoUrl,
    String? caption,
    List<String>? hashtags,
    String? audio,
    String? audioArtist,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isVerified,
    bool? isLiked,
  }) {
    return ReelModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfile: userProfile ?? this.userProfile,
      videoUrl: videoUrl ?? this.videoUrl,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      audio: audio ?? this.audio,
      audioArtist: audioArtist ?? this.audioArtist,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isVerified: isVerified ?? this.isVerified,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
