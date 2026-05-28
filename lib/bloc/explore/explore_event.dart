part of 'explore_bloc.dart';

abstract class ExploreEvent extends Equatable {
  const ExploreEvent();

  @override
  List<Object?> get props => [];
}

class LoadExploreProfiles extends ExploreEvent {
  final int page;
  final String filter;
  final int? minAge;
  final int? maxAge;
  final int? distance;
  final List<String>? interests;
  final bool? verifiedOnly;
  final String? sortBy;

  const LoadExploreProfiles({
    this.page = 1,
    this.filter = 'all',
    this.minAge,
    this.maxAge,
    this.distance,
    this.interests,
    this.verifiedOnly = false,
    this.sortBy,
  });

  @override
  List<Object?> get props => [
        page,
        filter,
        minAge,
        maxAge,
        distance,
        interests,
        verifiedOnly,
        sortBy,
      ];
}

class RefreshExploreProfiles extends ExploreEvent {
  const RefreshExploreProfiles();
}

class LoadMoreExploreProfiles extends ExploreEvent {
  const LoadMoreExploreProfiles();
}

class SwipeProfile extends ExploreEvent {
  final int profileId;
  final String action;
  final int index;

  const SwipeProfile({
    required this.profileId,
    required this.action,
    required this.index,
  });

  @override
  List<Object?> get props => [
        profileId,
        action,
        index,
      ];
}

class UpdateExploreFilters extends ExploreEvent {
  final Map<String, dynamic> filters;

  const UpdateExploreFilters({
    required this.filters,
  });

  @override
  List<Object?> get props => [
        filters,
      ];
}

class LoadExploreStats extends ExploreEvent {
  const LoadExploreStats();
}

class ClearExploreError extends ExploreEvent {
  const ClearExploreError();
}

class ClearSwipeFeedback extends ExploreEvent {
  const ClearSwipeFeedback();
}

class ClearMatchState extends ExploreEvent {
  const ClearMatchState();
}

class ResetExploreState extends ExploreEvent {
  const ResetExploreState();
}
