part of 'insights_bloc.dart';

abstract class InsightsEvent extends Equatable {
  const InsightsEvent();

  @override
  List<Object?> get props => [];
}

// Load insights
class LoadInsights extends InsightsEvent {
  final int days;

  const LoadInsights({this.days = 30});

  @override
  List<Object?> get props => [days];
}

// Refresh insights
class RefreshInsights extends InsightsEvent {
  final int days;

  const RefreshInsights({this.days = 30});

  @override
  List<Object?> get props => [days];
}

// Change insights period
class ChangeInsightsPeriod extends InsightsEvent {
  final int days;

  const ChangeInsightsPeriod({required this.days});

  @override
  List<Object?> get props => [days];
}

// Load realtime stats
class LoadRealtimeStats extends InsightsEvent {}

// Refresh realtime stats
class RefreshRealtimeStats extends InsightsEvent {}

// Track event (fire and forget)
class TrackEvent extends InsightsEvent {
  final String eventType;
  final String objectType;
  final int objectId;
  final String? section;
  final String? source;

  const TrackEvent({
    required this.eventType,
    required this.objectType,
    required this.objectId,
    this.section,
    this.source,
  });

  @override
  List<Object?> get props => [eventType, objectType, objectId, section, source];
}

// Track post events (convenience)
class TrackPostView extends InsightsEvent {
  final int postId;
  final String? section;

  const TrackPostView({required this.postId, this.section});

  @override
  List<Object?> get props => [postId, section];
}

class TrackPostLike extends InsightsEvent {
  final int postId;
  final String? section;

  const TrackPostLike({required this.postId, this.section});

  @override
  List<Object?> get props => [postId, section];
}

class TrackPostComment extends InsightsEvent {
  final int postId;
  final String? section;

  const TrackPostComment({required this.postId, this.section});

  @override
  List<Object?> get props => [postId, section];
}

class TrackPostShare extends InsightsEvent {
  final int postId;
  final String? section;

  const TrackPostShare({required this.postId, this.section});

  @override
  List<Object?> get props => [postId, section];
}

// Track reel events
class TrackReelView extends InsightsEvent {
  final int reelId;
  final String? section;

  const TrackReelView({required this.reelId, this.section});

  @override
  List<Object?> get props => [reelId, section];
}

class TrackReelLike extends InsightsEvent {
  final int reelId;
  final String? section;

  const TrackReelLike({required this.reelId, this.section});

  @override
  List<Object?> get props => [reelId, section];
}

class TrackReelShare extends InsightsEvent {
  final int reelId;
  final String? section;

  const TrackReelShare({required this.reelId, this.section});

  @override
  List<Object?> get props => [reelId, section];
}

// Track profile events
class TrackProfileView extends InsightsEvent {
  final int userId;
  final String? section;

  const TrackProfileView({required this.userId, this.section});

  @override
  List<Object?> get props => [userId, section];
}

class TrackFollow extends InsightsEvent {
  final int userId;
  final String? section;

  const TrackFollow({required this.userId, this.section});

  @override
  List<Object?> get props => [userId, section];
}

// Track story events
class TrackStoryView extends InsightsEvent {
  final int storyId;
  final String? section;

  const TrackStoryView({required this.storyId, this.section});

  @override
  List<Object?> get props => [storyId, section];
}

// Track search
class TrackSearch extends InsightsEvent {
  final String query;
  final String? section;

  const TrackSearch({required this.query, this.section});

  @override
  List<Object?> get props => [query, section];
}

// Clear insights error
class ClearInsightsError extends InsightsEvent {}

// Reset insights state
class ResetInsightsState extends InsightsEvent {}
