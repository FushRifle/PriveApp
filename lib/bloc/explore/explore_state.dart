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
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    Set<int>? swipedProfileIds,
    String? lastSwipeAction,
  }) {
    return ExploreState(
      profiles: profiles ?? this.profiles,
      currentIndex: currentIndex ?? this.currentIndex,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalLikes: totalLikes ?? this.totalLikes,
      currentFilters: currentFilters ?? this.currentFilters,
      status: status ?? this.status,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      swipedProfileIds: swipedProfileIds ?? this.swipedProfileIds,
      lastSwipeAction: lastSwipeAction ?? this.lastSwipeAction,
    );
  }

  int get remainingProfiles => profiles.length - currentIndex;
  ProfileModel? get currentProfile =>
      currentIndex < profiles.length ? profiles[currentIndex] : null;

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
