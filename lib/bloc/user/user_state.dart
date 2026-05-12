part of 'user_bloc.dart';

class User {
  final int id;
  final String? name;
  final String? username;
  final String? email;
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
  final bool isVerified;
  final bool isOnline;
  final bool hasCompletedOnboarding;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    this.name,
    this.username,
    this.email,
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
    this.isVerified = false,
    this.isOnline = false,
    this.hasCompletedOnboarding = false,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name']?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      age: json['age'] as int?,
      occupation: json['occupation']?.toString(),
      bio: json['bio']?.toString(),
      location: json['location']?.toString(),
      work: json['work']?.toString(),
      education: json['education']?.toString(),
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : null,
      avatar: json['avatar']?.toString(),
      coverImage: json['coverImage']?.toString(),
      isVerified: json['verified'] == true || json['isVerified'] == true,
      isOnline: json['isOnline'] == true,
      hasCompletedOnboarding:
          json['onboarded'] == true || json['hasCompletedOnboarding'] == true,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (name != null) 'name': name,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (age != null) 'age': age,
        if (occupation != null) 'occupation': occupation,
        if (bio != null) 'bio': bio,
        if (location != null) 'location': location,
        if (work != null) 'work': work,
        if (education != null) 'education': education,
        if (languages != null) 'languages': languages,
        if (avatar != null) 'avatar': avatar,
        if (coverImage != null) 'coverImage': coverImage,
        'isVerified': isVerified,
        'isOnline': isOnline,
        'hasCompletedOnboarding': hasCompletedOnboarding,
        if (lastSeen != null) 'lastSeen': lastSeen?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  User copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    int? age,
    String? occupation,
    String? bio,
    String? location,
    String? work,
    String? education,
    List<String>? languages,
    String? avatar,
    String? coverImage,
    bool? isVerified,
    bool? isOnline,
    bool? hasCompletedOnboarding,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      work: work ?? this.work,
      education: education ?? this.education,
      languages: languages ?? this.languages,
      avatar: avatar ?? this.avatar,
      coverImage: coverImage ?? this.coverImage,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  String get displayName => name ?? username ?? 'User';
  String get displayAvatar => avatar ?? '';
  String get displayBio => bio ?? 'No bio yet';
  String get displayLocation => location ?? 'Location not set';
  String get ageText =>
      age != null && age! > 0 ? '$age years old' : 'Age not specified';
  bool get hasCompletedProfile =>
      name != null && name!.isNotEmpty && bio != null && bio!.isNotEmpty;
}

class UserState extends Equatable {
  final User? currentUser;
  final User? viewedUser;
  final UserStatus status;
  final UserStatus viewedStatus;
  final String? error;
  final bool isLoading;
  final bool isSaving;
  final bool isRefreshing;
  final bool isDeleting;
  final DateTime? lastUpdated;
  final Map<String, dynamic>? lastUpdateData;

  const UserState({
    this.currentUser,
    this.viewedUser,
    this.status = UserStatus.initial,
    this.viewedStatus = UserStatus.initial,
    this.error,
    this.isLoading = false,
    this.isSaving = false,
    this.isRefreshing = false,
    this.isDeleting = false,
    this.lastUpdated,
    this.lastUpdateData,
  });

  UserState copyWith({
    User? currentUser,
    User? viewedUser,
    UserStatus? status,
    UserStatus? viewedStatus,
    String? error,
    bool? isLoading,
    bool? isSaving,
    bool? isRefreshing,
    bool? isDeleting,
    DateTime? lastUpdated,
    Map<String, dynamic>? lastUpdateData,
  }) {
    return UserState(
      currentUser: currentUser ?? this.currentUser,
      viewedUser: viewedUser ?? this.viewedUser,
      status: status ?? this.status,
      viewedStatus: viewedStatus ?? this.viewedStatus,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isDeleting: isDeleting ?? this.isDeleting,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastUpdateData: lastUpdateData ?? this.lastUpdateData,
    );
  }

  @override
  List<Object?> get props => [
        currentUser,
        viewedUser,
        status,
        viewedStatus,
        error,
        isLoading,
        isSaving,
        isRefreshing,
        isDeleting,
        lastUpdated,
        lastUpdateData,
      ];
}

enum UserStatus {
  initial,
  loading,
  refreshing,
  saving,
  deleting,
  success,
  error,
}
