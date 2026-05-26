import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/data/services/match/match_service.dart';

part 'match_event.dart';
part 'match_state.dart';

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final MatchService _matchService = MatchService();

  MatchBloc() : super(const MatchState()) {
    on<LoadMatches>(_onLoadMatches);
    on<LoadRecommendations>(_onLoadRecommendations);
    on<LikeUser>(_onLikeUser);
    on<AcceptMatch>(_onAcceptMatch);
    on<RejectMatch>(_onRejectMatch);
    on<ClearMatchError>(_onClearMatchError);
    on<ResetMatchState>(_onResetMatchState);
  }

  Future<void> _onLoadMatches(
    LoadMatches event,
    Emitter<MatchState> emit,
  ) async {
    if (state.matches.isEmpty) {
      emit(state.copyWith(status: MatchStatus.loading, isLoading: true));
    }

    try {
      final data = await _matchService.getMatches();
      final matches = (data).map((item) => MatchUser.fromJson(item)).toList();

      emit(state.copyWith(
        matches: matches,
        status: MatchStatus.success,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MatchStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadRecommendations(
    LoadRecommendations event,
    Emitter<MatchState> emit,
  ) async {
    if (state.recommendations.isEmpty) {
      emit(state.copyWith(status: MatchStatus.loading, isLoading: true));
    }

    try {
      final data = await _matchService.getRecommendations();
      final recommendations =
          (data).map((item) => MatchUser.fromJson(item)).toList();

      emit(state.copyWith(
        recommendations: recommendations,
        status: MatchStatus.success,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MatchStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLikeUser(
    LikeUser event,
    Emitter<MatchState> emit,
  ) async {
    emit(state.copyWith(isLiking: true, clearError: true));

    try {
      await _matchService.likeUser(event.userId);
      // Refresh recommendations after liking
      add(LoadRecommendations());
      emit(state.copyWith(isLiking: false));
    } catch (e) {
      emit(state.copyWith(
        status: MatchStatus.error,
        isLiking: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onAcceptMatch(
    AcceptMatch event,
    Emitter<MatchState> emit,
  ) async {
    try {
      await _matchService.acceptMatch(event.matchId);
      add(LoadMatches());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRejectMatch(
    RejectMatch event,
    Emitter<MatchState> emit,
  ) async {
    try {
      await _matchService.rejectMatch(event.matchId);
      add(LoadMatches());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onClearMatchError(ClearMatchError event, Emitter<MatchState> emit) {
    emit(state.copyWith(clearError: true));
  }

  void _onResetMatchState(ResetMatchState event, Emitter<MatchState> emit) {
    emit(const MatchState());
  }
}
