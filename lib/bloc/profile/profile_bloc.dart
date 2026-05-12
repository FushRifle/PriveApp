import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:Prive/data/services/user/profile_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService _profileService = ProfileService();

  ProfileBloc() : super(const ProfileState()) {
    on<LoadMyProfile>(_onLoadMyProfile);
    on<RefreshMyProfile>(_onRefreshMyProfile);
    on<LoadProfileByUserId>(_onLoadProfileByUserId);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateProfileAvatar>(_onUpdateProfileAvatar);
    on<UpdateProfileBio>(_onUpdateProfileBio);
    on<UpdateProfileInterests>(_onUpdateProfileInterests);
    on<UpdateProfilePhotos>(_onUpdateProfilePhotos);
    on<UpdateProfileSettings>(_onUpdateProfileSettings);
    on<ClearProfileError>(_onClearProfileError);
    on<ResetProfileState>(_onResetProfileState);
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
      final profileData = await _profileService.getMyProfile();
      final profile = Profile.fromJson(profileData);

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
      final profileData = await _profileService.getMyProfile();
      final profile = Profile.fromJson(profileData);

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
      final profileData =
          await _profileService.getProfileByUserId(event.userId);
      final profile = Profile.fromJson(profileData);

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
          displayName: event.data['displayName'] ?? currentProfile.displayName,
          bio: event.data['bio'] ?? currentProfile.bio,
          avatar: event.data['avatar'] ?? currentProfile.avatar,
          interests: event.data['interests'] ?? currentProfile.interests,
          gender: event.data['gender'] ?? currentProfile.gender,
          location: event.data['location'] ?? currentProfile.location,
          settings: event.data['settings'] ?? currentProfile.settings,
        );
        emit(state.copyWith(myProfile: updatedProfile));
      }

      final result = await _profileService.updateMyProfile(event.data);
      final updatedProfile = Profile.fromJson(result);

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
