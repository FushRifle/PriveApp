part of 'explore_bloc.dart';

class ExploreState extends Equatable {
  final List<ProfileModel> profiles;
  final int currentIndex;
  final bool hasMore;
  final int currentPage;
  final int totalLikes;
  final Map<String, dynamic> currentFilters;
  final ExploreStatus status;
  final String? error;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final Set<int> swipedProfileIds;
  final String? lastSwipeAction;
  final String? matchId;
  final ProfileModel? matchedProfile;

  const ExploreState({
    this.profiles = const [],
    this.currentIndex = 0,
    this.hasMore = true,
    this.currentPage = 1,
    this.totalLikes = 0,
    this.currentFilters = const {
      'filter': 'all',
      'page': 1,
      'minAge': null,
      'maxAge': null,
      'distance': null,
      'interests': <String>[],
      'verifiedOnly': false,
      'sortBy': null,
    },
    this.status = ExploreStatus.initial,
    this.error,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.swipedProfileIds = const {},
    this.lastSwipeAction,
    this.matchId,
    this.matchedProfile,
  });

  ExploreState copyWith({
    List<ProfileModel>? profiles,
    int? currentIndex,
    bool? hasMore,
    int? currentPage,
    int? totalLikes,
    Map<String, dynamic>? currentFilters,
    ExploreStatus? status,
    String? error,
    bool clearError = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    Set<int>? swipedProfileIds,
    String? lastSwipeAction,
    bool clearLastSwipeAction = false,
    String? matchId,
    bool clearMatchId = false,
    ProfileModel? matchedProfile,
    bool clearMatchedProfile = false,
  }) {
    return ExploreState(
      profiles: profiles ?? this.profiles,
      currentIndex: currentIndex ?? this.currentIndex,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalLikes: totalLikes ?? this.totalLikes,
      currentFilters: currentFilters ?? this.currentFilters,
      status: status ?? this.status,
      error: clearError ? null : error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      swipedProfileIds: swipedProfileIds ?? this.swipedProfileIds,
      lastSwipeAction:
          clearLastSwipeAction ? null : lastSwipeAction ?? this.lastSwipeAction,
      matchId: clearMatchId ? null : matchId ?? this.matchId,
      matchedProfile:
          clearMatchedProfile ? null : matchedProfile ?? this.matchedProfile,
    );
  }

  int get remainingProfiles {
    final remaining = profiles.length - currentIndex;
    return remaining < 0 ? 0 : remaining;
  }

  ProfileModel? get currentProfile {
    if (profiles.isEmpty) return null;
    if (currentIndex < 0) return null;
    if (currentIndex >= profiles.length) return null;

    return profiles[currentIndex];
  }

  bool get hasProfiles => profiles.isNotEmpty;

  bool get hasCurrentProfile => currentProfile != null;

  bool get canLoadMore {
    return hasMore && !isLoading && !isLoadingMore && !isRefreshing;
  }

  bool get isBusy {
    return isLoading || isLoadingMore || isRefreshing;
  }

  @override
  List<Object?> get props => [
        profiles,
        currentIndex,
        hasMore,
        currentPage,
        totalLikes,
        currentFilters,
        status,
        error,
        isLoading,
        isLoadingMore,
        isRefreshing,
        swipedProfileIds,
        lastSwipeAction,
        matchId,
        matchedProfile,
      ];
}

enum ExploreStatus {
  initial,
  loading,
  loadingMore,
  refreshing,
  success,
  empty,
  error,
}
