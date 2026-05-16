import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:Prive/data/services/user/user_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserService _userService = UserService();

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
      final userData = await _userService.getCurrentUser();
      final profile = _convertUserDataToProfile(userData);

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
      final userData = await _userService.getCurrentUser();
      final profile = _convertUserDataToProfile(userData);

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
      final userData = await _userService.getUserById(event.userId);
      final profile = _convertUserDataToProfile(userData);

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
          displayName: event.data['name'] ??
              event.data['displayName'] ??
              currentProfile.displayName,
          bio: event.data['bio'] ?? currentProfile.bio,
          avatar: event.data['avatar'] ?? currentProfile.avatar,
          interests: event.data['interests'] ?? currentProfile.interests,
          gender: event.data['gender'] ?? currentProfile.gender,
          location: event.data['location'] ?? currentProfile.location,
          work: event.data['work'] ?? currentProfile.work,
          education: event.data['education'] ?? currentProfile.education,
          age: event.data['age'] ?? currentProfile.age,
        );
        emit(state.copyWith(myProfile: updatedProfile));
      }

      // Prepare data for UserService
      final updateData = <String, dynamic>{};
      if (event.data.containsKey('name')) {
        updateData['name'] = event.data['name'];
      }
      if (event.data.containsKey('displayName')) {
        updateData['name'] = event.data['displayName'];
      }
      if (event.data.containsKey('bio')) updateData['bio'] = event.data['bio'];
      if (event.data.containsKey('avatar')) {
        updateData['avatar'] = event.data['avatar'];
      }
      if (event.data.containsKey('interests')) {
        updateData['languages'] = event.data['interests'];
      }
      if (event.data.containsKey('gender')) {
        updateData['gender'] = event.data['gender'];
      }
      if (event.data.containsKey('location')) {
        updateData['location'] = event.data['location'];
      }
      if (event.data.containsKey('work')) {
        updateData['work'] = event.data['work'];
      }
      if (event.data.containsKey('education')) {
        updateData['education'] = event.data['education'];
      }
      if (event.data.containsKey('age')) updateData['age'] = event.data['age'];
      if (event.data.containsKey('coverImage')) {
        updateData['coverImage'] = event.data['coverImage'];
      }

      final result = await _userService.updateUser(
        name: updateData['name'],
        bio: updateData['bio'],
        avatar: updateData['avatar'],
        location: updateData['location'],
        work: updateData['work'],
        education: updateData['education'],
        age: updateData['age'],
        languages: updateData['languages'],
        coverImage: updateData['coverImage'],
      );

      final updatedProfile = _convertUserDataToProfile(result);

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
    // UserService doesn't have a direct photos update method
    // You might need to handle this separately
    add(UpdateProfile(data: {'photos': event.photos}));
  }

  Future<void> _onUpdateProfileSettings(
    UpdateProfileSettings event,
    Emitter<ProfileState> emit,
  ) async {
    // UserService doesn't have a settings update method
    // You might need to handle this separately
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

  // Helper method to convert UserService response to Profile model
  Profile _convertUserDataToProfile(Map<String, dynamic> userData) {
    return Profile(
      id: userData['id'] ?? 0,
      userId: userData['id'] ?? userData['userId'] ?? 0,
      displayName: userData['name'] ?? userData['displayName'],
      bio: userData['bio'],
      avatar: userData['avatar'],
      photos: userData['photos'] != null
          ? List<String>.from(userData['photos'])
          : (userData['avatar'] != null ? [userData['avatar']] : []),
      interests: userData['languages'] != null
          ? List<String>.from(userData['languages'])
          : (userData['interests'] != null
              ? List<String>.from(userData['interests'])
              : []),
      age: userData['age'] ?? 0,
      gender: userData['gender'],
      location: userData['location'],
      latitude: userData['latitude']?.toDouble(),
      longitude: userData['longitude']?.toDouble(),
      settings: userData['settings'] as Map<String, dynamic>?,
      isVerified: userData['verified'] == true,
      isOnline: userData['isOnline'] == true,
      lastSeen: userData['lastSeen'] != null
          ? DateTime.tryParse(userData['lastSeen'].toString())
          : null,
      createdAt: userData['createdAt'] != null
          ? DateTime.parse(userData['createdAt'].toString())
          : DateTime.now(),
      updatedAt: userData['updatedAt'] != null
          ? DateTime.parse(userData['updatedAt'].toString())
          : DateTime.now(),
    );
  }
}
