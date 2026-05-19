import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cirqle/data/services/match/match_service.dart';

part 'match_event.dart';
part 'match_state.dart';

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final MatchService _matchService = MatchService();

  MatchBloc() : super(const MatchState()) {
    on<LoadMatches>(_onLoadMatches);
    on<RefreshMatches>(_onRefreshMatches);
    on<LikeUser>(_onLikeUser);
    on<AcceptMatch>(_onAcceptMatch);
    on<RejectMatch>(_onRejectMatch);
    on<LoadRecommendations>(_onLoadRecommendations);
    on<RefreshRecommendations>(_onRefreshRecommendations);
    on<ClearMatchError>(_onClearMatchError);
    on<ResetMatchState>(_onResetMatchState);
  }

  Future<void> _onLoadMatches(
    LoadMatches event,
    Emitter<MatchState> emit,
  ) async {
    if (state.matches.isEmpty) {
      emit(state.copyWith(
        matchesStatus: MatchStatus.loading,
        isLoading: true,
      ));
    }

    try {
      final matchesData = await _matchService.getMatches();
      final matches = matchesData.map((m) => Match.fromJson(m)).toList();

      emit(state.copyWith(
        matches: matches,
        matchesStatus: MatchStatus.success,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        matchesStatus: MatchStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshMatches(
    RefreshMatches event,
    Emitter<MatchState> emit,
  ) async {
    emit(state.copyWith(
      matchesStatus: MatchStatus.refreshing,
      isRefreshing: true,
    ));

    try {
      final matchesData = await _matchService.getMatches();
      final matches = matchesData.map((m) => Match.fromJson(m)).toList();

      emit(state.copyWith(
        matches: matches,
        matchesStatus: MatchStatus.success,
        isRefreshing: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        matchesStatus: MatchStatus.error,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLikeUser(
    LikeUser event,
    Emitter<MatchState> emit,
  ) async {
    // Prevent duplicate likes
    if (state.likedUserIds.contains(event.userId)) return;

    // Add to pending likes
    final updatedPending = Set<int>.from(state.pendingLikeIds)
      ..add(event.userId);

    emit(state.copyWith(
      pendingLikeIds: updatedPending,
      isLiking: true,
    ));

    try {
      final result = await _matchService.likeUser(event.userId);

      // Add to liked set
      final updatedLiked = Set<int>.from(state.likedUserIds)..add(event.userId);

      emit(state.copyWith(
        likedUserIds: updatedLiked,
        pendingLikeIds: state.pendingLikeIds..remove(event.userId),
        isLiking: false,
        error: null,
      ));

      // If it's a match, refresh matches
      if (result['isMatch'] == true) {
        add(RefreshMatches());
      }
    } catch (e) {
      emit(state.copyWith(
        pendingLikeIds: state.pendingLikeIds..remove(event.userId),
        isLiking: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onAcceptMatch(
    AcceptMatch event,
    Emitter<MatchState> emit,
  ) async {
    // Optimistic update
    final updatedMatches = state.matches.map((match) {
      if (match.id == event.matchId) {
        return match.copyWith(isAccepted: true, isRejected: false);
      }
      return match;
    }).toList();

    emit(state.copyWith(
      matches: updatedMatches,
    ));

    try {
      await _matchService.acceptMatch(event.matchId);
    } catch (e) {
      // Rollback on error
      final rolledBackMatches = state.matches.map((match) {
        if (match.id == event.matchId) {
          return match.copyWith(isAccepted: false, isRejected: false);
        }
        return match;
      }).toList();

      emit(state.copyWith(
        matches: rolledBackMatches,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRejectMatch(
    RejectMatch event,
    Emitter<MatchState> emit,
  ) async {
    // Optimistic update - remove from list or mark as rejected
    final updatedMatches = state.matches.where((match) {
      return match.id != event.matchId;
    }).toList();

    emit(state.copyWith(
      matches: updatedMatches,
    ));

    try {
      await _matchService.rejectMatch(event.matchId);
    } catch (e) {
      // Refresh matches on error to restore state
      add(RefreshMatches());
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onLoadRecommendations(
    LoadRecommendations event,
    Emitter<MatchState> emit,
  ) async {
    if (state.recommendations.isEmpty) {
      emit(state.copyWith(
        recommendationsStatus: MatchStatus.loading,
        isLoading: true,
      ));
    }

    try {
      final recommendationsData = await _matchService.getRecommendations();
      final recommendations =
          recommendationsData.map((r) => Recommendation.fromJson(r)).toList();

      emit(state.copyWith(
        recommendations: recommendations,
        recommendationsStatus: MatchStatus.success,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        recommendationsStatus: MatchStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshRecommendations(
    RefreshRecommendations event,
    Emitter<MatchState> emit,
  ) async {
    emit(state.copyWith(
      recommendationsStatus: MatchStatus.refreshing,
      isRefreshing: true,
    ));

    try {
      final recommendationsData = await _matchService.getRecommendations();
      final recommendations =
          recommendationsData.map((r) => Recommendation.fromJson(r)).toList();

      emit(state.copyWith(
        recommendations: recommendations,
        recommendationsStatus: MatchStatus.success,
        isRefreshing: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        recommendationsStatus: MatchStatus.error,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  void _onClearMatchError(
    ClearMatchError event,
    Emitter<MatchState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  void _onResetMatchState(
    ResetMatchState event,
    Emitter<MatchState> emit,
  ) {
    emit(const MatchState());
  }
}
