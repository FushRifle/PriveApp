part of 'match_bloc.dart';

abstract class MatchEvent extends Equatable {
  const MatchEvent();

  @override
  List<Object?> get props => [];
}

class LoadMatches extends MatchEvent {}

class LoadRecommendations extends MatchEvent {}

class LikeUser extends MatchEvent {
  final int userId;
  const LikeUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class AcceptMatch extends MatchEvent {
  final int matchId;
  const AcceptMatch({required this.matchId});

  @override
  List<Object?> get props => [matchId];
}

class RejectMatch extends MatchEvent {
  final int matchId;
  const RejectMatch({required this.matchId});

  @override
  List<Object?> get props => [matchId];
}

class ClearMatchError extends MatchEvent {}

class ResetMatchState extends MatchEvent {}
