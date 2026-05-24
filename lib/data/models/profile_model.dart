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

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: _readInt(json['id']),
      name: _readString(
        json['name'] ??
            json['displayName'] ??
            json['display_name'] ??
            json['username'],
      ),
      age: _readInt(json['age']),
      occupation: _readString(json['occupation']),
      distance: _readInt(json['distance']),
      image: _readString(
        json['image'] ??
            json['avatar'] ??
            json['profileImage'] ??
            json['profile_image'] ??
            json['photo'],
      ),
      interests: _readStringList(json['interests']),
      verified: _readBool(
        json['verified'] ?? json['isVerified'] ?? json['is_verified'],
      ),
      bio: _readString(json['bio']),
      lastActive: _readString(
        json['lastActive'] ?? json['last_active'],
      ),
      matchScore: _readInt(
        json['matchScore'] ?? json['match_score'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
  }

  ProfileModel copyWith({
    int? id,
    String? name,
    int? age,
    String? occupation,
    int? distance,
    String? image,
    List<String>? interests,
    bool clearInterests = false,
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
      interests: clearInterests ? null : interests ?? this.interests,
      verified: verified ?? this.verified,
      bio: bio ?? this.bio,
      lastActive: lastActive ?? this.lastActive,
      matchScore: matchScore ?? this.matchScore,
    );
  }

  String get location => '$distance km away';

  String get distanceText {
    if (distance <= 0) {
      return 'Nearby';
    }

    return '$distance km away';
  }

  bool get isOnline {
    final value = lastActive.trim().toLowerCase();

    return value == 'active now' || value == 'online' || value == 'now';
  }

  bool get isVerified => verified;

  int get followerCount => 0;

  int get postCount => 0;

  String get imageHash => '';

  @override
  String toString() {
    return 'ProfileModel(id: $id, name: $name, age: $age, distance: $distance km, matchScore: $matchScore)';
  }

  static String _readString(dynamic value) {
    if (value == null) return '';

    return value.toString().trim();
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;

    return 0;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase().trim();

      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }

    return false;
  }

  static List<String>? _readStringList(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      final result = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();

      return result.isEmpty ? null : result;
    }

    if (value is String && value.trim().isNotEmpty) {
      final result = value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      return result.isEmpty ? null : result;
    }

    return null;
  }
}
