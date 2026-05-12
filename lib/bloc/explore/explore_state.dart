part of 'explore_bloc.dart';

class ExploreState extends Equatable {
  // Profiles
  final List<ProfileModel> profiles;
  final bool hasMoreProfiles;
  final int currentPage;
  final int totalProfiles;

  // Filters
  final String currentFilter;
  final int? minAge;
  final int? maxAge;
  final int? distance;
  final bool? verifiedOnly;
  final String? sortBy;
  final List<dynamic> availableFilters;

  // Matches
  final List<dynamic> matches;
  final bool hasMoreMatches;
  final int matchesPage;

  // Liked profiles
  final List<dynamic> likedProfiles;
  final bool hasMoreLiked;

  // Liked by profiles
  final List<dynamic> likedByProfiles;
  final bool hasMoreLikedBy;

  // Stats
  final Map<String, dynamic>? stats;

  // Status
  final ExploreStatus status;
  final ExploreStatus matchesStatus;
  final ExploreStatus likedStatus;
  final ExploreStatus likedByStatus;
  final ExploreStatus statsStatus;
  final String? error;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;

  const ExploreState({
    this.profiles = const [],
    this.hasMoreProfiles = true,
    this.currentPage = 1,
    this.totalProfiles = 0,
    this.currentFilter = 'all',
    this.minAge,
    this.maxAge,
    this.distance,
    this.verifiedOnly,
    this.sortBy,
    this.availableFilters = const [],
    this.matches = const [],
    this.hasMoreMatches = true,
    this.matchesPage = 1,
    this.likedProfiles = const [],
    this.hasMoreLiked = true,
    this.likedByProfiles = const [],
    this.hasMoreLikedBy = true,
    this.stats,
    this.status = ExploreStatus.initial,
    this.matchesStatus = ExploreStatus.initial,
    this.likedStatus = ExploreStatus.initial,
    this.likedByStatus = ExploreStatus.initial,
    this.statsStatus = ExploreStatus.initial,
    this.error,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });

  ExploreState copyWith({
    List<ProfileModel>? profiles,
    bool? hasMoreProfiles,
    int? currentPage,
    int? totalProfiles,
    String? currentFilter,
    int? minAge,
    int? maxAge,
    int? distance,
    bool? verifiedOnly,
    String? sortBy,
    List<dynamic>? availableFilters,
    List<dynamic>? matches,
    bool? hasMoreMatches,
    int? matchesPage,
    List<dynamic>? likedProfiles,
    bool? hasMoreLiked,
    List<dynamic>? likedByProfiles,
    bool? hasMoreLikedBy,
    Map<String, dynamic>? stats,
    ExploreStatus? status,
    ExploreStatus? matchesStatus,
    ExploreStatus? likedStatus,
    ExploreStatus? likedByStatus,
    ExploreStatus? statsStatus,
    String? error,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return ExploreState(
      profiles: profiles ?? this.profiles,
      hasMoreProfiles: hasMoreProfiles ?? this.hasMoreProfiles,
      currentPage: currentPage ?? this.currentPage,
      totalProfiles: totalProfiles ?? this.totalProfiles,
      currentFilter: currentFilter ?? this.currentFilter,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      distance: distance ?? this.distance,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      sortBy: sortBy ?? this.sortBy,
      availableFilters: availableFilters ?? this.availableFilters,
      matches: matches ?? this.matches,
      hasMoreMatches: hasMoreMatches ?? this.hasMoreMatches,
      matchesPage: matchesPage ?? this.matchesPage,
      likedProfiles: likedProfiles ?? this.likedProfiles,
      hasMoreLiked: hasMoreLiked ?? this.hasMoreLiked,
      likedByProfiles: likedByProfiles ?? this.likedByProfiles,
      hasMoreLikedBy: hasMoreLikedBy ?? this.hasMoreLikedBy,
      stats: stats ?? this.stats,
      status: status ?? this.status,
      matchesStatus: matchesStatus ?? this.matchesStatus,
      likedStatus: likedStatus ?? this.likedStatus,
      likedByStatus: likedByStatus ?? this.likedByStatus,
      statsStatus: statsStatus ?? this.statsStatus,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        profiles,
        hasMoreProfiles,
        currentPage,
        totalProfiles,
        currentFilter,
        minAge,
        maxAge,
        distance,
        verifiedOnly,
        sortBy,
        availableFilters,
        matches,
        hasMoreMatches,
        matchesPage,
        likedProfiles,
        hasMoreLiked,
        likedByProfiles,
        hasMoreLikedBy,
        stats,
        status,
        matchesStatus,
        likedStatus,
        likedByStatus,
        statsStatus,
        error,
        isLoading,
        isLoadingMore,
        isRefreshing,
      ];
}

enum ExploreStatus {
  initial,
  loading,
  loadingMore,
  refreshing,
  success,
  error,
}
