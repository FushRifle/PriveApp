// gallery_model.dart
class GalleryModel {
  final String? id;
  final String image;
  final String? videoUrl;
  final String type; // 'image' or 'video'
  final String like;
  final String? caption;
  final dynamic createdAt;

  GalleryModel({
    this.id,
    required this.image,
    this.videoUrl,
    required this.type,
    required this.like,
    this.caption,
    this.createdAt,
  });

  factory GalleryModel.fromJson(Map<String, dynamic> json) {
    return GalleryModel(
      id: json['id']?.toString(),
      image: json['image'] ?? '',
      videoUrl: json['videoUrl'],
      type: json['type'] ?? 'image',
      like: json['like'] ?? '0',
      caption: json['caption'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'videoUrl': videoUrl,
      'type': type,
      'like': like,
      'caption': caption,
      'createdAt': createdAt,
    };
  }
}
