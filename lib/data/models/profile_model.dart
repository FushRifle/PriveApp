class ProfileModel {
  final int id;
  final String name;
  final int age;
  final String location;
  final String bio;
  final List<String> interests;
  final String image;
  final String imageHash;
  final bool isOnline;
  final String distance;
  final bool isVerified;
  final int followerCount;
  final int postCount;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.bio,
    required this.interests,
    required this.image,
    this.imageHash = '',
    this.isOnline = false,
    this.distance = '',
    this.isVerified = false,
    this.followerCount = 0,
    this.postCount = 0,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        age: json['age'] ?? 0,
        location: json['location'] ?? '',
        bio: json['bio'] ?? '',
        interests: json['interests'] != null
            ? List<String>.from(json['interests'].map((x) => x.toString()))
            : [],
        image: json['image'] ?? '',
        imageHash: json['imageHash'] ?? '',
        isOnline: json['isOnline'] ?? false,
        distance: json['distance'] ?? '',
        isVerified: json['isVerified'] ?? false,
        followerCount: json['followerCount'] ?? 0,
        postCount: json['postCount'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'location': location,
        'bio': bio,
        'interests': interests,
        'image': image,
        'imageHash': imageHash,
        'isOnline': isOnline,
        'distance': distance,
        'isVerified': isVerified,
        'followerCount': followerCount,
        'postCount': postCount,
      };

  ProfileModel copyWith({
    int? id,
    String? name,
    int? age,
    String? location,
    String? bio,
    List<String>? interests,
    String? image,
    String? imageHash,
    bool? isOnline,
    String? distance,
    bool? isVerified,
    int? followerCount,
    int? postCount,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      image: image ?? this.image,
      imageHash: imageHash ?? this.imageHash,
      isOnline: isOnline ?? this.isOnline,
      distance: distance ?? this.distance,
      isVerified: isVerified ?? this.isVerified,
      followerCount: followerCount ?? this.followerCount,
      postCount: postCount ?? this.postCount,
    );
  }

  @override
  String toString() {
    return 'ProfileModel(id: $id, name: $name, age: $age, location: $location)';
  }
}
