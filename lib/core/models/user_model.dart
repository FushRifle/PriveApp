class UserProfile {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String? country;
  final String? countryCode;
  final String? mobileNumber;
  final String? gender;
  final int? age;
  final String? occupation;
  final String? bio;
  final String? location;
  final String? work;
  final String? education;
  final List<String> languages;
  final String? avatar;
  final String? coverImage;
  final bool verified;
  final bool onboarded;
  final bool isSeenOnboarding;
  final bool isSeenDemographics;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.country,
    this.countryCode,
    this.mobileNumber,
    this.gender,
    this.age,
    this.occupation,
    this.bio,
    this.location,
    this.work,
    this.education,
    this.languages = const [],
    this.avatar,
    this.coverImage,
    this.verified = false,
    this.onboarded = false,
    this.isSeenOnboarding = false,
    this.isSeenDemographics = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      country: json['country'],
      countryCode: json['countryCode'] ?? json['country_code'],
      mobileNumber: json['mobileNumber'] ?? json['mobile_number'],
      gender: json['gender'],
      age: json['age'],
      occupation: json['occupation'],
      bio: json['bio'],
      location: json['location'],
      work: json['work'],
      education: json['education'],
      languages:
          json['languages'] != null ? List<String>.from(json['languages']) : [],
      avatar: json['avatar'],
      coverImage: json['coverImage'],
      verified: json['verified'] ?? false,
      onboarded: json['onboarded'] ?? false,
      isSeenOnboarding: json['isSeenOnboarding'] ??
          json['is_seen_onboarding'] ??
          json['onboarded'] ??
          false,
      isSeenDemographics: json['isSeenDemographics'] ??
          json['is_seen_demographics'] ??
          json['onboarded'] ??
          false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'country': country,
      'countryCode': countryCode,
      'mobileNumber': mobileNumber,
      'gender': gender,
      'age': age,
      'occupation': occupation,
      'bio': bio,
      'location': location,
      'work': work,
      'education': education,
      'languages': languages,
      'avatar': avatar,
      'coverImage': coverImage,
      'verified': verified,
      'onboarded': onboarded,
      'isSeenOnboarding': isSeenOnboarding,
      'isSeenDemographics': isSeenDemographics,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    String? country,
    String? countryCode,
    String? mobileNumber,
    String? gender,
    int? age,
    String? occupation,
    String? bio,
    String? location,
    String? work,
    String? education,
    List<String>? languages,
    String? avatar,
    String? coverImage,
    bool? verified,
    bool? onboarded,
    bool? isSeenOnboarding,
    bool? isSeenDemographics,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      work: work ?? this.work,
      education: education ?? this.education,
      languages: languages ?? this.languages,
      avatar: avatar ?? this.avatar,
      coverImage: coverImage ?? this.coverImage,
      verified: verified ?? this.verified,
      onboarded: onboarded ?? this.onboarded,
      isSeenOnboarding: isSeenOnboarding ?? this.isSeenOnboarding,
      isSeenDemographics: isSeenDemographics ?? this.isSeenDemographics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UpdateUserRequest {
  final String? name;
  final String? username;
  final String? phone;
  final int? age;
  final String? gender;
  final String? lookingFor;
  final String? occupation;
  final String? bio;
  final String? location;
  final String? work;
  final String? education;
  final List<String>? languages;
  final String? avatar;
  final String? coverImage;
  final String? country;
  final String? countryCode;
  final String? mobileNumber;

  UpdateUserRequest({
    this.name,
    this.username,
    this.phone,
    this.age,
    this.gender,
    this.lookingFor,
    this.occupation,
    this.bio,
    this.location,
    this.work,
    this.education,
    this.languages,
    this.avatar,
    this.coverImage,
    this.country,
    this.countryCode,
    this.mobileNumber,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (username != null) map['username'] = username;
    if (phone != null) map['phone'] = phone;
    if (age != null) map['age'] = age;
    if (gender != null) map['gender'] = gender;
    if (lookingFor != null) map['looking_for'] = lookingFor;
    if (occupation != null) map['occupation'] = occupation;
    if (bio != null) map['bio'] = bio;
    if (location != null) map['location'] = location;
    if (work != null) map['work'] = work;
    if (education != null) map['education'] = education;
    if (languages != null) map['languages'] = languages;
    if (avatar != null) map['avatar'] = avatar;
    if (coverImage != null) map['coverImage'] = coverImage;
    if (country != null) map['country'] = country;
    if (countryCode != null) map['countryCode'] = countryCode;
    if (mobileNumber != null) map['mobileNumber'] = mobileNumber;
    return map;
  }
}

class CreateUserRequest {
  final String supabaseId;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final int? age;
  final String? occupation;
  final String? bio;
  final String? location;
  final String? work;
  final String? education;
  final List<String>? languages;
  final String? avatar;
  final String? coverImage;

  CreateUserRequest({
    required this.supabaseId,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.age,
    this.occupation,
    this.bio,
    this.location,
    this.work,
    this.education,
    this.languages,
    this.avatar,
    this.coverImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'supabase_id': supabaseId,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'age': age,
      'occupation': occupation,
      'bio': bio,
      'location': location,
      'work': work,
      'education': education,
      'languages': languages,
      'avatar': avatar,
      'coverImage': coverImage,
    };
  }
}
