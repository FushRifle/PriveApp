part of 'match_bloc.dart';

abstract class MatchEvent extends Equatable {
  const MatchEvent();

  @override
  List<Object?> get props => [];
}

// Load matches
class LoadMatches extends MatchEvent {}

// Refresh matches
class RefreshMatches extends MatchEvent {}

// Like a user
class LikeUser extends MatchEvent {
  final int userId;

  const LikeUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Accept a match
class AcceptMatch extends MatchEvent {
  final int matchId;

  const AcceptMatch({required this.matchId});

  @override
  List<Object?> get props => [matchId];
}

// Reject a match
class RejectMatch extends MatchEvent {
  final int matchId;

  const RejectMatch({required this.matchId});

  @override
  List<Object?> get props => [matchId];
}

// Load recommendations
class LoadRecommendations extends MatchEvent {}

// Refresh recommendations
class RefreshRecommendations extends MatchEvent {}

// Clear match error
class ClearMatchError extends MatchEvent {}

// Reset match state
class ResetMatchState extends MatchEvent {}
