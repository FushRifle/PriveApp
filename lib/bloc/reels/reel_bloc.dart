import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/core/services/reel/reel_service.dart';

part 'reel_event.dart';
part 'reel_state.dart';

class ReelBloc extends Bloc<ReelEvent, ReelState> {
  final ReelService _reelService = ReelService();
  static const int _pageSize = 10;

  bool _isLoadingInitial = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;

  ReelBloc() : super(const ReelState()) {
    on<LoadReels>(_onLoadReels);
    on<RefreshReels>(_onRefreshReels);
    on<LoadMoreReels>(_onLoadMoreReels);
    on<CreateReel>(_onCreateReel);
    on<LikeReel>(_onLikeReel);
    on<UnlikeReel>(_onUnlikeReel);
    on<ShareReel>(_onShareReel);
    on<RepostReel>(_onRepostReel);
    on<IncrementReelCommentCount>(_onIncrementReelCommentCount);
    on<ClearReelError>(_onClearReelError);
    on<ResetReelState>(_onResetReelState);
  }

  Future<void> _onLoadReels(
    LoadReels event,
    Emitter<ReelState> emit,
  ) async {
    if (_isLoadingInitial || _isRefreshing) return;

    _isLoadingInitial = true;

    if (state.reels.isEmpty || event.page == 1) {
      emit(state.copyWith(
        status: ReelStatus.loading,
        isLoading: true,
        clearError: true,
      ));
    }

    try {
      final cachedReels = _reelService.readCachedReels(page: event.page);
      if (cachedReels != null && cachedReels.isNotEmpty) {
        emit(state.copyWith(
          reels: _dedupeReels(cachedReels),
          currentPage: event.page,
          hasMore: cachedReels.length >= _pageSize,
          status: ReelStatus.success,
          isLoading: false,
          clearError: true,
        ));
      }

      final reels = await _reelService.getReels(
        page: event.page,
        forceRefresh: cachedReels == null || cachedReels.isEmpty,
      );

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
    } finally {
      _isLoadingInitial = false;
    }
  }

  Future<void> _onRefreshReels(
    RefreshReels event,
    Emitter<ReelState> emit,
  ) async {
    if (_isRefreshing || _isLoadingInitial) return;

    _isRefreshing = true;

    emit(state.copyWith(
      status: ReelStatus.refreshing,
      isRefreshing: true,
      clearError: true,
    ));

    try {
      final cachedReels = _reelService.readCachedReels(page: 1);
      if (cachedReels != null && cachedReels.isNotEmpty) {
        emit(state.copyWith(
          reels: _dedupeReels(cachedReels),
          currentPage: 1,
          hasMore: cachedReels.length >= _pageSize,
          status: ReelStatus.success,
          isRefreshing: false,
          clearError: true,
        ));
      }

      final reels = await _reelService.getReels(
        page: 1,
        forceRefresh: true,
      );

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
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _onLoadMoreReels(
    LoadMoreReels event,
    Emitter<ReelState> emit,
  ) async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.isRefreshing ||
        _isLoadingMore ||
        _isRefreshing ||
        _isLoadingInitial) {
      return;
    }

    _isLoadingMore = true;

    emit(state.copyWith(
      status: ReelStatus.loadingMore,
      isLoadingMore: true,
      clearError: true,
    ));

    try {
      final nextPage = state.currentPage + 1;
      final cachedReels = _reelService.readCachedReels(page: nextPage);
      if (cachedReels != null && cachedReels.isNotEmpty) {
        emit(state.copyWith(
          reels: _dedupeReels([...state.reels, ...cachedReels]),
          currentPage: nextPage,
          hasMore: cachedReels.length >= _pageSize,
          status: ReelStatus.success,
          isLoadingMore: false,
          clearError: true,
        ));
      }

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
    } finally {
      _isLoadingMore = false;
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
      'reaction': event.reaction,
      'likes': _readInt(oldReel['likes']) + 1,
    };

    emit(state.copyWith(reels: updatedReels));

    try {
      await _reelService.likeReel(
        event.reelId,
        reaction: event.reaction,
      );
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
      'reaction': null,
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

  Future<void> _onRepostReel(
    RepostReel event,
    Emitter<ReelState> emit,
  ) async {
    final resolvedIndex = _resolveReelIndex(event.reelId, event.index);
    if (resolvedIndex < 0 || resolvedIndex >= state.reels.length) return;

    final oldReel = state.reels[resolvedIndex];
    if (oldReel is! Map) return;

    if (_readBool(oldReel['isReposted'] ?? oldReel['is_reposted'])) return;

    final updatedReels = List<dynamic>.from(state.reels);
    updatedReels[resolvedIndex] = {
      ...Map<String, dynamic>.from(oldReel),
      'isReposted': true,
      'reposts': _readInt(oldReel['reposts'] ?? oldReel['repostCount']) + 1,
    };

    emit(state.copyWith(reels: updatedReels, clearError: true));

    try {
      await _reelService.repostReel(
        reelId: event.reelId,
        content: event.content,
      );
    } catch (e) {
      final rolledBackReels = List<dynamic>.from(state.reels);
      rolledBackReels[resolvedIndex] = oldReel;
      emit(state.copyWith(
        reels: rolledBackReels,
        error: e.toString(),
      ));
    }
  }

  int _resolveReelIndex(String reelId, int fallbackIndex) {
    if (fallbackIndex >= 0 && fallbackIndex < state.reels.length) {
      final candidate = state.reels[fallbackIndex];
      if (candidate is Map && _readReelId(candidate) == reelId) {
        return fallbackIndex;
      }
    }

    for (var index = 0; index < state.reels.length; index++) {
      final reel = state.reels[index];
      if (reel is Map && _readReelId(reel) == reelId) {
        return index;
      }
    }

    return fallbackIndex;
  }

  String _readReelId(Map reel) {
    final id = reel['id'] ?? reel['reelId'] ?? reel['reel_id'];
    return id?.toString() ?? '';
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

  bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }
}
