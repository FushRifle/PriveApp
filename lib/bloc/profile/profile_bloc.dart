import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/data/services/profile/profile_service.dart';
import 'package:clique/data/services/user/user_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService _profileService = ProfileService();
  final UserService _userService = UserService();

  ProfileBloc() : super(const ProfileState()) {
    on<LoadMyProfile>(_onLoadMyProfile);
    on<RefreshMyProfile>(_onRefreshMyProfile);
    on<LoadProfileByUserId>(_onLoadProfileByUserId);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateProfileAvatar>(_onUpdateProfileAvatar);
    on<UpdateProfileCoverImage>(_onUpdateProfileCoverImage);
    on<UpdateProfileDisplayName>(_onUpdateProfileDisplayName);
    on<UpdateProfileBio>(_onUpdateProfileBio);
    on<UpdateProfileInterests>(_onUpdateProfileInterests);
    on<UpdateProfilePhotos>(_onUpdateProfilePhotos);
    on<UpdateProfileSettings>(_onUpdateProfileSettings);
    on<ClearProfileError>(_onClearProfileError);
    on<ResetProfileState>(_onResetProfileState);
  }

  void setAuthToken(String token) {
    _profileService.setAuthToken(token);
    _userService.setAuthToken(token);
  }

  void clearAuthToken() {
    _profileService.clearAuthToken();
    _userService.clearAuthToken();
  }

  Future<void> _onLoadMyProfile(
    LoadMyProfile event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.myProfile == null) {
      emit(state.copyWith(
        status: ProfileStatus.loading,
        isLoading: true,
        error: null,
      ));
    }

    try {
      // Fetch both profile and user data in parallel
      final results = await Future.wait([
        _profileService.getMyProfile(),
        _userService.getCurrentUser(),
      ]);

      final profileData = results[0];
      final userData = results[1];

      // Merge user data into profile
      final mergedProfile = {
        ...profileData,
        'avatar': userData['avatar'] ?? profileData['avatar'],
        'name': userData['name'] ?? profileData['displayName'],
        'email': userData['email'],
        'username': userData['username'],
        'verified': userData['verified'] ?? false,
      };

      final profile = Profile.fromJson(mergedProfile);

      emit(state.copyWith(
        myProfile: profile,
        status: ProfileStatus.success,
        isLoading: false,
        error: null,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshMyProfile(
    RefreshMyProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      status: ProfileStatus.refreshing,
      isRefreshing: true,
      error: null,
    ));

    try {
      final results = await Future.wait([
        _profileService.getMyProfile(),
        _userService.getCurrentUser(),
      ]);

      final profileData = results[0];
      final userData = results[1];

      final mergedProfile = {
        ...profileData,
        'avatar': userData['avatar'] ?? profileData['avatar'],
        'name': userData['name'] ?? profileData['displayName'],
        'email': userData['email'],
        'username': userData['username'],
        'verified': userData['verified'] ?? false,
      };

      final profile = Profile.fromJson(mergedProfile);

      emit(state.copyWith(
        myProfile: profile,
        status: ProfileStatus.success,
        isRefreshing: false,
        error: null,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProfileStatus.error,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadProfileByUserId(
    LoadProfileByUserId event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      viewedStatus: ProfileStatus.loading,
      isLoading: true,
      error: null,
    ));

    try {
      final results = await Future.wait([
        _profileService.getProfileByUserId(event.userId),
        _userService.getUserById(event.userId),
      ]);

      final profileData = results[0];
      final userData = results[1];

      final mergedProfile = {
        ...profileData,
        'avatar': userData['avatar'] ?? profileData['avatar'],
        'name': userData['name'] ?? profileData['displayName'],
        'username': userData['username'],
        'verified': userData['verified'] ?? false,
      };

      final profile = Profile.fromJson(mergedProfile);

      emit(state.copyWith(
        viewedProfile: profile,
        viewedStatus: ProfileStatus.success,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        viewedStatus: ProfileStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(
      status: ProfileStatus.saving,
      isSaving: true,
      error: null,
    ));

    try {
      // Optimistic update
      final currentProfile = state.myProfile;
      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          displayName: event.data['displayName'] ??
              event.data['name'] ??
              currentProfile.displayName,
          bio: event.data['bio'] ?? currentProfile.bio,
          avatar: event.data['avatar'] ?? currentProfile.avatar,
          coverImage: event.data['coverImage'] ?? currentProfile.coverImage,
          interests: event.data['interests'] ?? currentProfile.interests,
          gender: event.data['gender'] ?? currentProfile.gender,
          lookingFor: event.data['lookingFor'] ?? currentProfile.lookingFor,
          location: event.data['location'] ?? currentProfile.location,
          work: event.data['work'] ?? currentProfile.work,
          education: event.data['education'] ?? currentProfile.education,
          age: event.data['age'] ?? currentProfile.age,
          photos: event.data['photos'] ?? currentProfile.photos,
        );
        emit(state.copyWith(myProfile: updatedProfile));
      }

      // Send update to API
      final result = await _profileService.updateMyProfile(event.data);
      final updatedProfile = Profile.fromJson(result);

      // Also update user data if needed
      if (event.data['avatar'] != null || event.data['displayName'] != null) {
        await _userService.updateUser(
          name: event.data['displayName'],
          avatar: event.data['avatar'],
        );
      }

      emit(state.copyWith(
        myProfile: updatedProfile,
        status: ProfileStatus.success,
        isSaving: false,
        error: null,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      // Refresh to revert optimistic update
      add(RefreshMyProfile());
      emit(state.copyWith(
        status: ProfileStatus.error,
        isSaving: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateProfileAvatar(
    UpdateProfileAvatar event,
    Emitter<ProfileState> emit,
  ) async {
    add(UpdateProfile(data: {'avatar': event.avatarUrl}));
  }

  Future<void> _onUpdateProfileCoverImage(
    UpdateProfileCoverImage event,
    Emitter<ProfileState> emit,
  ) async {
    add(UpdateProfile(data: {'coverImage': event.coverImageUrl}));
  }

  Future<void> _onUpdateProfileDisplayName(
    UpdateProfileDisplayName event,
    Emitter<ProfileState> emit,
  ) async {
    add(UpdateProfile(data: {'displayName': event.displayName}));
  }

  Future<void> _onUpdateProfileBio(
    UpdateProfileBio event,
    Emitter<ProfileState> emit,
  ) async {
    add(UpdateProfile(data: {'bio': event.bio}));
  }

  Future<void> _onUpdateProfileInterests(
    UpdateProfileInterests event,
    Emitter<ProfileState> emit,
  ) async {
    add(UpdateProfile(data: {'interests': event.interests}));
  }

  Future<void> _onUpdateProfilePhotos(
    UpdateProfilePhotos event,
    Emitter<ProfileState> emit,
  ) async {
    add(UpdateProfile(data: {'photos': event.photos}));
  }

  Future<void> _onUpdateProfileSettings(
    UpdateProfileSettings event,
    Emitter<ProfileState> emit,
  ) async {
    add(UpdateProfile(data: {'settings': event.settings}));
  }

  void _onClearProfileError(
    ClearProfileError event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  void _onResetProfileState(
    ResetProfileState event,
    Emitter<ProfileState> emit,
  ) {
    emit(const ProfileState());
  }
}
