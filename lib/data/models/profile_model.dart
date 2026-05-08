class ProfileModel {
  final int id;
  final String name;
  final int age;
  final String occupation;
  final int distance;
  final String image;
  final List<String>? interests;
  final bool verified;
  final String bio;
  final String lastActive;
  final int matchScore;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.occupation,
    required this.distance,
    required this.image,
    this.interests,
    required this.verified,
    required this.bio,
    required this.lastActive,
    required this.matchScore,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        age: json['age'] ?? 0,
        occupation: json['occupation'] ?? '',
        distance: json['distance'] ?? 0,
        image: json['image'] ?? '',
        interests: json['interests'] != null
            ? List<String>.from(json['interests'].map((x) => x.toString()))
            : null,
        verified: json['verified'] ?? false,
        bio: json['bio'] ?? '',
        lastActive: json['lastActive'] ?? '',
        matchScore: json['matchScore'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'occupation': occupation,
        'distance': distance,
        'image': image,
        'interests': interests,
        'verified': verified,
        'bio': bio,
        'lastActive': lastActive,
        'matchScore': matchScore,
      };

  ProfileModel copyWith({
    int? id,
    String? name,
    int? age,
    String? occupation,
    int? distance,
    String? image,
    List<String>? interests,
    bool? verified,
    String? bio,
    String? lastActive,
    int? matchScore,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      distance: distance ?? this.distance,
      image: image ?? this.image,
      interests: interests ?? this.interests,
      verified: verified ?? this.verified,
      bio: bio ?? this.bio,
      lastActive: lastActive ?? this.lastActive,
      matchScore: matchScore ?? this.matchScore,
    );
  }

  // Helper getters for UI compatibility
  String get location => '$distance km away';
  String get distanceText => '$distance km away';
  bool get isOnline => lastActive == 'active now';
  bool get isVerified => verified;
  int get followerCount => 0; // Not in API, provide default
  int get postCount => 0; // Not in API, provide default
  String get imageHash => ''; // Not in API, provide default

  @override
  String toString() {
    return 'ProfileModel(id: $id, name: $name, age: $age, distance: $distance km, matchScore: $matchScore)';
  }
}
