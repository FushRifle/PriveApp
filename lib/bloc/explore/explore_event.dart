part of 'explore_bloc.dart';

abstract class ExploreEvent extends Equatable {
  const ExploreEvent();

  @override
  List<Object?> get props => [];
}

// Load explore profiles
class LoadExploreProfiles extends ExploreEvent {
  final int page;
  final String filter;
  final int? minAge;
  final int? maxAge;
  final int? distance;
  final bool? verifiedOnly;
  final String? sortBy;

  const LoadExploreProfiles({
    this.page = 1,
    this.filter = 'all',
    this.minAge,
    this.maxAge,
    this.distance,
    this.verifiedOnly,
    this.sortBy,
  });

  @override
  List<Object?> get props => [
        page,
        filter,
        minAge,
        maxAge,
        distance,
        verifiedOnly,
        sortBy,
      ];
}

// Refresh explore profiles
class RefreshExploreProfiles extends ExploreEvent {}

// Load more profiles (pagination)
class LoadMoreExploreProfiles extends ExploreEvent {}

// Swipe on a profile
class SwipeProfile extends ExploreEvent {
  final int profileId;
  final String action; // 'like', 'pass', 'super_like'

  const SwipeProfile({
    required this.profileId,
    required this.action,
  });

  @override
  List<Object?> get props => [profileId, action];
}

// Load filters
class LoadExploreFilters extends ExploreEvent {}

// Load matches
class LoadMatches extends ExploreEvent {
  final int page;

  const LoadMatches({this.page = 1});

  @override
  List<Object?> get props => [page];
}

// Load more matches
class LoadMoreMatches extends ExploreEvent {}

// Load liked profiles
class LoadLikedProfiles extends ExploreEvent {
  final int page;

  const LoadLikedProfiles({this.page = 1});

  @override
  List<Object?> get props => [page];
}

// Load liked by profiles
class LoadLikedByProfiles extends ExploreEvent {
  final int page;

  const LoadLikedByProfiles({this.page = 1});

  @override
  List<Object?> get props => [page];
}

// Load stats
class LoadExploreStats extends ExploreEvent {}

// Update filters
class UpdateExploreFilters extends ExploreEvent {
  final String filter;
  final int? minAge;
  final int? maxAge;
  final int? distance;
  final bool? verifiedOnly;
  final String? sortBy;

  const UpdateExploreFilters({
    this.filter = 'all',
    this.minAge,
    this.maxAge,
    this.distance,
    this.verifiedOnly,
    this.sortBy,
  });

  @override
  List<Object?> get props => [
        filter,
        minAge,
        maxAge,
        distance,
        verifiedOnly,
        sortBy,
      ];
}

// Clear explore error
class ClearExploreError extends ExploreEvent {}

// Reset explore state
class ResetExploreState extends ExploreEvent {}
