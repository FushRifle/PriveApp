import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cirqle/data/services/reel/reel_service.dart';

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
    on<ClearReelError>(_onClearReelError);
    on<ResetReelState>(_onResetReelState);
  }

  Future<void> _onLoadReels(
    LoadReels event,
    Emitter<ReelState> emit,
  ) async {
    if (state.reels.isEmpty) {
      emit(state.copyWith(
        status: ReelStatus.loading,
        isLoading: true,
      ));
    }

    try {
      final reels = await _reelService.getReels(page: event.page);

      emit(state.copyWith(
        reels: reels,
        currentPage: event.page,
        hasMore: reels.length >= _pageSize,
        status: ReelStatus.success,
        isLoading: false,
        error: null,
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
    ));

    try {
      final reels = await _reelService.getReels(page: 1);

      emit(state.copyWith(
        reels: reels,
        currentPage: 1,
        hasMore: reels.length >= _pageSize,
        status: ReelStatus.success,
        isRefreshing: false,
        error: null,
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
    ));

    try {
      final nextPage = state.currentPage + 1;
      final newReels = await _reelService.getReels(page: nextPage);

      final updatedReels = List<dynamic>.from(state.reels)..addAll(newReels);

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
    try {
      await _reelService.createReel(event.data);
      // Refresh after creating
      add(RefreshReels());
    } catch (e) {
      emit(state.copyWith(
        status: ReelStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLikeReel(
    LikeReel event,
    Emitter<ReelState> emit,
  ) async {
    final oldReel = state.reels[event.index];

    // Optimistic update
    final updatedReels = List<dynamic>.from(state.reels);
    updatedReels[event.index] = {
      ...oldReel,
      'isLiked': true,
      'likes': (oldReel['likes'] ?? 0) + 1,
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
    final oldReel = state.reels[event.index];

    // Optimistic update
    final updatedReels = List<dynamic>.from(state.reels);
    updatedReels[event.index] = {
      ...oldReel,
      'isLiked': false,
      'likes': ((oldReel['likes'] ?? 0) - 1).clamp(0, 999999),
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
    try {
      await _reelService.shareReel(event.reelId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onClearReelError(
    ClearReelError event,
    Emitter<ReelState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  void _onResetReelState(
    ResetReelState event,
    Emitter<ReelState> emit,
  ) {
    emit(const ReelState());
  }
}
