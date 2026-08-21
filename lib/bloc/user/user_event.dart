part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadCurrentUser extends UserEvent {}

class HydrateCurrentUser extends UserEvent {
  final Map<String, dynamic> user;

  const HydrateCurrentUser(this.user);

  @override
  List<Object?> get props => [user];
}

class RefreshCurrentUser extends UserEvent {}

class LoadUserById extends UserEvent {
  final int userId;
  const LoadUserById({required this.userId});

  @override
  List<Object?> get props => [userId];
}

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

class UpdateUserAvatar extends UserEvent {
  final String avatar;
  const UpdateUserAvatar({required this.avatar});

  @override
  List<Object?> get props => [avatar];
}

class UpdateUserCoverImage extends UserEvent {
  final String coverImage;
  const UpdateUserCoverImage({required this.coverImage});

  @override
  List<Object?> get props => [coverImage];
}

class UpdateUserBio extends UserEvent {
  final String bio;
  const UpdateUserBio({required this.bio});

  @override
  List<Object?> get props => [bio];
}

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

class CompleteOnboarding extends UserEvent {}

class DeleteAccount extends UserEvent {}

class ClearUserError extends UserEvent {}

class ResetUserState extends UserEvent {}
