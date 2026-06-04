import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/data/services/reel/reel_service.dart';

part 'reel_event.dart';
part 'reel_state.dart';

class ReelBloc extends Bloc<ReelEvent, ReelState> {
  final ReelService _reelService = ReelService();
  static const int _pageSize = 10;

  ReelBloc() : super(const ReelState()) {
    on<LoadReels>(_onLoadReels);
    on<RefreshReels>(_onRefreshReels);
    on<LoadMoreReels>(_onLoadMoreReels);
    on<CreateReel>(_onCreateReel);
    on<LikeReel>(_onLikeReel);
    on<UnlikeReel>(_onUnlikeReel);
    on<ShareReel>(_onShareReel);
    on<IncrementReelCommentCount>(_onIncrementReelCommentCount);
    on<ClearReelError>(_onClearReelError);
    on<ResetReelState>(_onResetReelState);
  }

  Future<void> _onLoadReels(
    LoadReels event,
    Emitter<ReelState> emit,
  ) async {
    if (state.reels.isEmpty || event.page == 1) {
      emit(state.copyWith(
        status: ReelStatus.loading,
        isLoading: true,
        clearError: true,
      ));
    }

    try {
      final reels = await _reelService.getReels(page: event.page);

      emit(state.copyWith(
        reels: _dedupeReels(reels),
        currentPage: event.page,
        hasMore: reels.length >= _pageSize,
        status: ReelStatus.success,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReelStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshReels(
    RefreshReels event,
    Emitter<ReelState> emit,
  ) async {
    emit(state.copyWith(
      status: ReelStatus.refreshing,
      isRefreshing: true,
      clearError: true,
    ));

    try {
      final reels = await _reelService.getReels(page: 1);

      emit(state.copyWith(
        reels: _dedupeReels(reels),
        currentPage: 1,
        hasMore: reels.length >= _pageSize,
        status: ReelStatus.success,
        isRefreshing: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReelStatus.error,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreReels(
    LoadMoreReels event,
    Emitter<ReelState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore || state.isRefreshing) return;

    emit(state.copyWith(
      status: ReelStatus.loadingMore,
      isLoadingMore: true,
      clearError: true,
    ));

    try {
      final nextPage = state.currentPage + 1;
      final newReels = await _reelService.getReels(page: nextPage);

      final updatedReels = _dedupeReels([...state.reels, ...newReels]);

      emit(state.copyWith(
        reels: updatedReels,
        currentPage: nextPage,
        hasMore: newReels.length >= _pageSize,
        status: ReelStatus.success,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReelStatus.error,
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCreateReel(
    CreateReel event,
    Emitter<ReelState> emit,
  ) async {
    emit(state.copyWith(
      status: ReelStatus.creating,
      isCreating: true,
      clearError: true,
    ));

    try {
      final reel = await _reelService.createReel(event.data);
      final updatedReels =
          reel.isEmpty ? state.reels : _dedupeReels([reel, ...state.reels]);

      emit(state.copyWith(
        reels: updatedReels,
        status: ReelStatus.created,
        isCreating: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReelStatus.error,
        isCreating: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLikeReel(
    LikeReel event,
    Emitter<ReelState> emit,
  ) async {
    if (event.index < 0 || event.index >= state.reels.length) return;

    final oldReel = state.reels[event.index];
    if (oldReel is! Map) return;

    // Optimistic update
    final updatedReels = List<dynamic>.from(state.reels);
    updatedReels[event.index] = {
      ...Map<String, dynamic>.from(oldReel),
      'isLiked': true,
      'likes': _readInt(oldReel['likes']) + 1,
    };

    emit(state.copyWith(reels: updatedReels));

    try {
      await _reelService.likeReel(event.reelId);
    } catch (e) {
      // Rollback on error
      final rolledBackReels = List<dynamic>.from(state.reels);
      rolledBackReels[event.index] = oldReel;
      emit(state.copyWith(
        reels: rolledBackReels,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUnlikeReel(
    UnlikeReel event,
    Emitter<ReelState> emit,
  ) async {
    if (event.index < 0 || event.index >= state.reels.length) return;

    final oldReel = state.reels[event.index];
    if (oldReel is! Map) return;

    // Optimistic update
    final updatedReels = List<dynamic>.from(state.reels);
    updatedReels[event.index] = {
      ...Map<String, dynamic>.from(oldReel),
      'isLiked': false,
      'likes': (_readInt(oldReel['likes']) - 1).clamp(0, 999999).toInt(),
    };

    emit(state.copyWith(reels: updatedReels));

    try {
      await _reelService.unlikeReel(event.reelId);
    } catch (e) {
      // Rollback on error
      final rolledBackReels = List<dynamic>.from(state.reels);
      rolledBackReels[event.index] = oldReel;
      emit(state.copyWith(
        reels: rolledBackReels,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onShareReel(
    ShareReel event,
    Emitter<ReelState> emit,
  ) async {
    if (event.index < 0 || event.index >= state.reels.length) return;

    final oldReel = state.reels[event.index];
    if (oldReel is! Map) return;

    final updatedReels = List<dynamic>.from(state.reels);
    updatedReels[event.index] = {
      ...Map<String, dynamic>.from(oldReel),
      'shares': _readInt(oldReel['shares'] ?? oldReel['shareCount']) + 1,
    };

    emit(state.copyWith(reels: updatedReels, clearError: true));

    try {
      await _reelService.shareReel(event.reelId);
    } catch (e) {
      final rolledBackReels = List<dynamic>.from(state.reels);
      rolledBackReels[event.index] = oldReel;
      emit(state.copyWith(
        reels: rolledBackReels,
        error: e.toString(),
      ));
    }
  }

  void _onIncrementReelCommentCount(
    IncrementReelCommentCount event,
    Emitter<ReelState> emit,
  ) {
    if (event.index < 0 || event.index >= state.reels.length) return;

    final oldReel = state.reels[event.index];
    if (oldReel is! Map) return;

    final updatedReels = List<dynamic>.from(state.reels);
    updatedReels[event.index] = {
      ...Map<String, dynamic>.from(oldReel),
      'comments': _readInt(oldReel['comments'] ?? oldReel['commentCount']) + 1,
    };

    emit(state.copyWith(reels: updatedReels, clearError: true));
  }

  void _onClearReelError(
    ClearReelError event,
    Emitter<ReelState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  void _onResetReelState(
    ResetReelState event,
    Emitter<ReelState> emit,
  ) {
    emit(const ReelState());
  }

  List<dynamic> _dedupeReels(List<dynamic> reels) {
    final seen = <Object>{};
    final deduped = <dynamic>[];

    for (final reel in reels) {
      final id = reel is Map ? reel['id'] ?? reel['_id'] : null;
      if (id == null) {
        deduped.add(reel);
        continue;
      }

      if (seen.add(id)) {
        deduped.add(reel);
      }
    }

    return deduped;
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
