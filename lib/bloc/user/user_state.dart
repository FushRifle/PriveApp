part of 'user_bloc.dart';

enum UserStatus {
  initial,
  loading,
  success,
  refreshing,
  saving,
  error,
  deleting,
}

class UserState extends Equatable {
  final UserStatus status;
  final Map<String, dynamic>? currentUser;
  final Map<String, dynamic>? viewedUser;
  final bool isLoading;
  final bool isRefreshing;
  final bool isSaving;
  final bool isDeleting;
  final String? error;
  final DateTime? lastUpdated;
  final Map<String, dynamic>? lastUpdateData;

  const UserState({
    this.status = UserStatus.initial,
    this.currentUser,
    this.viewedUser,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isSaving = false,
    this.isDeleting = false,
    this.error,
    this.lastUpdated,
    this.lastUpdateData,
  });

  UserState copyWith({
    UserStatus? status,
    Map<String, dynamic>? currentUser,
    Map<String, dynamic>? viewedUser,
    bool? isLoading,
    bool? isRefreshing,
    bool? isSaving,
    bool? isDeleting,
    String? error,
    DateTime? lastUpdated,
    Map<String, dynamic>? lastUpdateData,
    bool clearCurrentUser = false,
    bool clearViewedUser = false,
    bool clearError = false,
  }) {
    return UserState(
      status: status ?? this.status,
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      viewedUser: clearViewedUser ? null : viewedUser ?? this.viewedUser,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      error: clearError ? null : error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastUpdateData: lastUpdateData ?? this.lastUpdateData,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentUser,
        viewedUser,
        isLoading,
        isRefreshing,
        isSaving,
        isDeleting,
        error,
        lastUpdated,
        lastUpdateData,
      ];
}
