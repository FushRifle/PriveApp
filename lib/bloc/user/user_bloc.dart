import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/core/services/user/user_service.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserService _userService = UserService();

  bool _isRefreshingCurrentUser = false;
  Future<Map<String, dynamic>>? _currentUserFuture;

  UserBloc() : super(const UserState()) {
    on<LoadCurrentUser>(_onLoadCurrentUser);
    on<RefreshCurrentUser>(_onRefreshCurrentUser);
    on<LoadUserById>(_onLoadUserById);
    on<UpdateUser>(_onUpdateUser);
    on<UpdateUserAvatar>(_onUpdateUserAvatar);
    on<UpdateUserCoverImage>(_onUpdateUserCoverImage);
    on<UpdateUserBio>(_onUpdateUserBio);
    on<UpdateDemographicInfo>(_onUpdateDemographicInfo);
    on<CompleteOnboarding>(_onCompleteOnboarding);
    on<DeleteAccount>(_onDeleteAccount);
    on<ClearUserError>(_onClearUserError);
    on<ResetUserState>(_onResetUserState);
  }

  void setAuthToken(String token) {
    _userService.setAuthToken(token);
  }

  void clearAuthToken() {
    _userService.clearAuthToken();
  }

  Future<void> _onLoadCurrentUser(
    LoadCurrentUser event,
    Emitter<UserState> emit,
  ) async {
    if (_isRefreshingCurrentUser) return;

    if (state.currentUser == null) {
      emit(state.copyWith(
        status: UserStatus.loading,
        isLoading: true,
        clearError: true,
      ));
    }

    try {
      final userData = await _getCurrentUserOnce();

      emit(state.copyWith(
        currentUser: userData,
        status: UserStatus.success,
        isLoading: false,
        clearError: true,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UserStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshCurrentUser(
    RefreshCurrentUser event,
    Emitter<UserState> emit,
  ) async {
    if (_isRefreshingCurrentUser) return;

    _isRefreshingCurrentUser = true;

    emit(state.copyWith(
      status: UserStatus.refreshing,
      isRefreshing: true,
      clearError: true,
    ));

    try {
      final userData = await _getCurrentUserOnce();

      emit(state.copyWith(
        currentUser: userData,
        status: UserStatus.success,
        isRefreshing: false,
        clearError: true,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UserStatus.error,
        isRefreshing: false,
        error: e.toString(),
      ));
    } finally {
      _isRefreshingCurrentUser = false;
    }
  }

  Future<Map<String, dynamic>> _getCurrentUserOnce() {
    final existing = _currentUserFuture;
    if (existing != null) {
      return existing;
    }

    final future = _userService.getCurrentUser();
    _currentUserFuture = future;

    return future.whenComplete(() {
      if (_currentUserFuture == future) {
        _currentUserFuture = null;
      }
    });
  }

  Future<void> _onLoadUserById(
    LoadUserById event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
    ));

    try {
      final userData = await _userService.getUserById(event.userId);

      emit(state.copyWith(
        viewedUser: userData,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(
      status: UserStatus.saving,
      isSaving: true,
      clearError: true,
    ));

    final updateData = <String, dynamic>{};
    if (event.name != null) updateData['name'] = event.name;
    if (event.username != null) updateData['username'] = event.username;
    if (event.phone != null) updateData['phone'] = event.phone;
    if (event.age != null) updateData['age'] = event.age;
    if (event.occupation != null) updateData['occupation'] = event.occupation;
    if (event.bio != null) updateData['bio'] = event.bio;
    if (event.location != null) updateData['location'] = event.location;
    if (event.work != null) updateData['work'] = event.work;
    if (event.education != null) updateData['education'] = event.education;
    if (event.languages != null) updateData['languages'] = event.languages;
    if (event.avatar != null) updateData['avatar'] = event.avatar;
    if (event.coverImage != null) updateData['coverImage'] = event.coverImage;

    final previousUser = state.currentUser;

    try {
      // Optimistic update
      if (state.currentUser != null) {
        final optimisticUser = Map<String, dynamic>.from(state.currentUser!);
        optimisticUser.addAll(updateData);
        emit(state.copyWith(currentUser: optimisticUser));
      }

      final result = await _userService.updateUser(
        name: event.name,
        username: event.username,
        phone: event.phone,
        age: event.age,
        occupation: event.occupation,
        bio: event.bio,
        location: event.location,
        work: event.work,
        education: event.education,
        languages: event.languages,
        avatar: event.avatar,
        coverImage: event.coverImage,
      );

      emit(state.copyWith(
        currentUser: result,
        status: UserStatus.success,
        isSaving: false,
        clearError: true,
        lastUpdated: DateTime.now(),
        lastUpdateData: updateData,
      ));
    } catch (e) {
      // Refresh to revert optimistic update
      add(RefreshCurrentUser());
      emit(state.copyWith(
        currentUser: previousUser,
        status: UserStatus.error,
        isSaving: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateUserAvatar(
    UpdateUserAvatar event,
    Emitter<UserState> emit,
  ) async {
    add(UpdateUser(avatar: event.avatar));
  }

  Future<void> _onUpdateUserCoverImage(
    UpdateUserCoverImage event,
    Emitter<UserState> emit,
  ) async {
    add(UpdateUser(coverImage: event.coverImage));
  }

  Future<void> _onUpdateUserBio(
    UpdateUserBio event,
    Emitter<UserState> emit,
  ) async {
    add(UpdateUser(bio: event.bio));
  }

  Future<void> _onUpdateDemographicInfo(
    UpdateDemographicInfo event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(
      status: UserStatus.saving,
      isSaving: true,
      clearError: true,
    ));

    try {
      await _userService.updateDemographicInfo(
        age: event.age,
        gender: event.gender,
        lookingFor: event.lookingFor,
        occupation: event.occupation,
        bio: event.bio,
        location: event.location,
        work: event.work,
        education: event.education,
        interests: event.interests,
      );

      // Refresh user after demographic update
      add(RefreshCurrentUser());

      emit(state.copyWith(
        status: UserStatus.success,
        isSaving: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UserStatus.error,
        isSaving: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(
      status: UserStatus.saving,
      isSaving: true,
      clearError: true,
    ));

    try {
      await _userService.completeOnboarding();

      // Refresh user to get updated onboarding status
      add(RefreshCurrentUser());

      emit(state.copyWith(
        status: UserStatus.success,
        isSaving: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UserStatus.error,
        isSaving: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(
      status: UserStatus.deleting,
      isDeleting: true,
      clearError: true,
    ));

    try {
      await _userService.deleteAccount();

      emit(state.copyWith(
        clearCurrentUser: true,
        status: UserStatus.success,
        isDeleting: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UserStatus.error,
        isDeleting: false,
        error: e.toString(),
      ));
    }
  }

  void _onClearUserError(
    ClearUserError event,
    Emitter<UserState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  void _onResetUserState(
    ResetUserState event,
    Emitter<UserState> emit,
  ) {
    emit(const UserState());
  }
}
