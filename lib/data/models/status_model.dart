class StatusModel {
  final String name;
  final String imgProfile;
  final String statusImage;
  final String statusImageHash;
  final String time;
  final bool isViewed;
  final int viewCount;

  const StatusModel({
    required this.name,
    required this.imgProfile,
    required this.statusImage,
    this.statusImageHash = '',
    required this.time,
    this.isViewed = false,
    this.viewCount = 0,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) => StatusModel(
        name: json['name'] ?? '',
        imgProfile: json['imgProfile'] ?? '',
        statusImage: json['statusImage'] ?? '',
        statusImageHash: json['statusImageHash'] ?? '',
        time: json['time'] ?? '',
        isViewed: json['isViewed'] ?? false,
        viewCount: json['viewCount'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'imgProfile': imgProfile,
        'statusImage': statusImage,
        'statusImageHash': statusImageHash,
        'time': time,
        'isViewed': isViewed,
        'viewCount': viewCount,
      };
}
