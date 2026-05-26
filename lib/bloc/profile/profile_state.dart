part of 'profile_bloc.dart';

class Profile {
  final int id;
  final int userId;
  final String? displayName;
  final String? bio;
  final String? avatar;
  final String? coverImage;
  final List<String> photos;
  final List<String> interests;
  final int age;
  final String? gender;
  final String? lookingFor;
  final String? location;
  final String? work;
  final String? education;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? settings;
  final bool isVerified;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.userId,
    this.displayName,
    this.bio,
    this.avatar,
    this.coverImage,
    this.photos = const [],
    this.interests = const [],
    required this.age,
    this.gender,
    this.lookingFor,
    this.location,
    this.work,
    this.education,
    this.latitude,
    this.longitude,
    this.settings,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? json['user_id'] ?? 0,
      displayName: json['displayName']?.toString() ?? json['name']?.toString(),
      bio: json['bio']?.toString(),
      avatar: json['avatar']?.toString(),
      coverImage: json['coverImage']?.toString() ??
          json['cover_image']?.toString(), // Added cover image
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
      interests:
          json['interests'] != null ? List<String>.from(json['interests']) : [],
      age: json['age'] ?? 0,
      gender: json['gender']?.toString(),
      lookingFor: json['lookingFor']?.toString(),
      location: json['location']?.toString(),
      work: json['work']?.toString(),
      education: json['education']?.toString(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      settings: json['settings'] as Map<String, dynamic>?,
      isVerified: json['verified'] == true || json['isVerified'] == true,
      isOnline: json['isOnline'] == true,
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
        'userId': userId,
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (avatar != null) 'avatar': avatar,
        if (coverImage != null) 'coverImage': coverImage, // Added cover image
        'photos': photos,
        'interests': interests,
        'age': age,
        if (gender != null) 'gender': gender,
        if (lookingFor != null) 'lookingFor': lookingFor,
        if (location != null) 'location': location,
        if (work != null) 'work': work,
        if (education != null) 'education': education,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (settings != null) 'settings': settings,
        'isVerified': isVerified,
        'isOnline': isOnline,
        if (lastSeen != null) 'lastSeen': lastSeen?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Profile copyWith({
    int? id,
    int? userId,
    String? displayName,
    String? bio,
    String? avatar,
    String? coverImage, // Added cover image
    List<String>? photos,
    List<String>? interests,
    int? age,
    String? gender,
    String? lookingFor,
    String? location,
    String? work,
    String? education,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? settings,
    bool? isVerified,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      coverImage: coverImage ?? this.coverImage, // Added cover image
      photos: photos ?? this.photos,
      interests: interests ?? this.interests,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      location: location ?? this.location,
      work: work ?? this.work,
      education: education ?? this.education,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      settings: settings ?? this.settings,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  String get displayNameOrDefault => displayName ?? 'User';
  String get avatarOrDefault => avatar ?? '';
  String get coverImageOrDefault => coverImage ?? '';
  String get bioOrDefault => bio ?? 'No bio yet';
  String get locationOrDefault => location ?? 'Location not set';
  List<String> get photosOrDefault => photos.isEmpty ? [] : photos;
  bool get hasPhotos => photos.isNotEmpty;
  bool get hasInterests => interests.isNotEmpty;
  String get ageText => age > 0 ? '$age years old' : 'Age not specified';
  String get workOrDefault => work ?? 'Work not specified';
  String get educationOrDefault => education ?? 'Education not specified';
  String get lookingForOrDefault => lookingFor ?? 'Not specified';
}

enum ProfileStatus {
  initial,
  loading,
  refreshing,
  saving,
  success,
  error,
}

class ProfileState extends Equatable {
  final Profile? myProfile;
  final Profile? viewedProfile;
  final ProfileStatus status;
  final ProfileStatus viewedStatus;
  final String? error;
  final bool isLoading;
  final bool isSaving;
  final bool isRefreshing;
  final DateTime? lastUpdated;

  const ProfileState({
    this.myProfile,
    this.viewedProfile,
    this.status = ProfileStatus.initial,
    this.viewedStatus = ProfileStatus.initial,
    this.error,
    this.isLoading = false,
    this.isSaving = false,
    this.isRefreshing = false,
    this.lastUpdated,
  });

  ProfileState copyWith({
    Profile? myProfile,
    Profile? viewedProfile,
    ProfileStatus? status,
    ProfileStatus? viewedStatus,
    String? error,
    bool? isLoading,
    bool? isSaving,
    bool? isRefreshing,
    DateTime? lastUpdated,
    bool clearMyProfile = false,
    bool clearViewedProfile = false,
    bool clearError = false,
  }) {
    return ProfileState(
      myProfile: clearMyProfile ? null : myProfile ?? this.myProfile,
      viewedProfile:
          clearViewedProfile ? null : viewedProfile ?? this.viewedProfile,
      status: status ?? this.status,
      viewedStatus: viewedStatus ?? this.viewedStatus,
      error: clearError ? null : error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        myProfile,
        viewedProfile,
        status,
        viewedStatus,
        error,
        isLoading,
        isSaving,
        isRefreshing,
        lastUpdated,
      ];
}
