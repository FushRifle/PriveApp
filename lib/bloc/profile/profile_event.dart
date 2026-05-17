part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

// Load my profile
class LoadMyProfile extends ProfileEvent {}

// Refresh my profile
class RefreshMyProfile extends ProfileEvent {}

// Load profile by user ID
class LoadProfileByUserId extends ProfileEvent {
  final int userId;

  const LoadProfileByUserId({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Update profile
class UpdateProfile extends ProfileEvent {
  final Map<String, dynamic> data;

  const UpdateProfile({required this.data});

  @override
  List<Object?> get props => [data];
}

// Update specific profile fields (convenience)
class UpdateProfileAvatar extends ProfileEvent {
  final String avatarUrl;

  const UpdateProfileAvatar({required this.avatarUrl});

  @override
  List<Object?> get props => [avatarUrl];
}

class UpdateProfileCoverImage extends ProfileEvent {
  // Added cover image event
  final String coverImageUrl;

  const UpdateProfileCoverImage({required this.coverImageUrl});

  @override
  List<Object?> get props => [coverImageUrl];
}

class UpdateProfileDisplayName extends ProfileEvent {
  // Added display name event
  final String displayName;

  const UpdateProfileDisplayName({required this.displayName});

  @override
  List<Object?> get props => [displayName];
}

class UpdateProfileBio extends ProfileEvent {
  final String bio;

  const UpdateProfileBio({required this.bio});

  @override
  List<Object?> get props => [bio];
}

class UpdateProfileInterests extends ProfileEvent {
  final List<String> interests;

  const UpdateProfileInterests({required this.interests});

  @override
  List<Object?> get props => [interests];
}

class UpdateProfilePhotos extends ProfileEvent {
  final List<String> photos;

  const UpdateProfilePhotos({required this.photos});

  @override
  List<Object?> get props => [photos];
}

class UpdateProfileSettings extends ProfileEvent {
  final Map<String, dynamic> settings;

  const UpdateProfileSettings({required this.settings});

  @override
  List<Object?> get props => [settings];
}

// Clear profile error
class ClearProfileError extends ProfileEvent {}

// Reset profile state
class ResetProfileState extends ProfileEvent {}
