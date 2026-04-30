class ReelModel {
  final String username;
  final String userProfile;
  final String videoUrl;
  final String caption;
  final List<String> hashtags;
  final String audio;
  final String audioArtist;
  final String like;
  final String comment;
  final String share;
  final bool isVerified;
  final bool isLiked;

  const ReelModel({
    required this.username,
    required this.userProfile,
    required this.videoUrl,
    required this.caption,
    required this.hashtags,
    required this.audio,
    required this.audioArtist,
    required this.like,
    required this.comment,
    required this.share,
    this.isVerified = false,
    this.isLiked = false,
  });
}
