part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

// Load current user
class LoadCurrentUser extends UserEvent {}

// Refresh current user
class RefreshCurrentUser extends UserEvent {}

// Load user by ID
class LoadUserById extends UserEvent {
  final int userId;

  const LoadUserById({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Update user
class UpdateUser extends UserEvent {
  final String? name;
  final String? username;
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

  const UpdateUser({
    this.name,
    this.username,
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

  @override
  List<Object?> get props => [
        name,
        username,
        phone,
        age,
        occupation,
        bio,
        location,
        work,
        education,
        languages,
        avatar,
        coverImage,
      ];
}

// Update user avatar
class UpdateUserAvatar extends UserEvent {
  final String avatar;

  const UpdateUserAvatar({required this.avatar});

  @override
  List<Object?> get props => [avatar];
}

// Update user cover image
class UpdateUserCoverImage extends UserEvent {
  final String coverImage;

  const UpdateUserCoverImage({required this.coverImage});

  @override
  List<Object?> get props => [coverImage];
}

// Update user bio
class UpdateUserBio extends UserEvent {
  final String bio;

  const UpdateUserBio({required this.bio});

  @override
  List<Object?> get props => [bio];
}

// Update user demographic info
class UpdateDemographicInfo extends UserEvent {
  final int age;
  final String gender;
  final String lookingFor;
  final String occupation;
  final String bio;
  final String location;
  final String work;
  final String education;
  final List<String> interests;

  const UpdateDemographicInfo({
    required this.age,
    required this.gender,
    required this.lookingFor,
    required this.occupation,
    required this.bio,
    required this.location,
    required this.work,
    required this.education,
    required this.interests,
  });

  @override
  List<Object?> get props => [
        age,
        gender,
        lookingFor,
        occupation,
        bio,
        location,
        work,
        education,
        interests,
      ];
}

// Complete onboarding
class CompleteOnboarding extends UserEvent {}

// Delete account
class DeleteAccount extends UserEvent {}

// Clear user error
class ClearUserError extends UserEvent {}

// Reset user state
class ResetUserState extends UserEvent {}
