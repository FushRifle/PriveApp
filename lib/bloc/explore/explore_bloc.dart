import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'package:clique/core/models/profile_model.dart';
import 'package:clique/core/services/explore/explore_service.dart';

part 'explore_event.dart';
part 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final ExploreService _exploreService = ExploreService();

  bool _isLoadingProfiles = false;
  bool _isRefreshingProfiles = false;
  bool _isLoadingMoreProfiles = false;
  bool _isSwiping = false;
  bool _isLoadingStats = false;

  Timer? _feedbackTimer;

  ExploreBloc() : super(const ExploreState()) {
    on<LoadExploreProfiles>(_onLoadExploreProfiles);
    on<RefreshExploreProfiles>(_onRefreshExploreProfiles);
    on<LoadMoreExploreProfiles>(_onLoadMoreExploreProfiles);
    on<SwipeProfile>(_onSwipeProfile);
    on<UpdateExploreFilters>(_onUpdateExploreFilters);
    on<LoadExploreStats>(_onLoadExploreStats);
    on<ClearExploreError>(_onClearExploreError);
    on<ClearSwipeFeedback>(_onClearSwipeFeedback);
    on<ClearMatchState>(_onClearMatchState);
    on<ResetExploreState>(_onResetExploreState);
  }

  Future<void> _onLoadExploreProfiles(
    LoadExploreProfiles event,
    Emitter<ExploreState> emit,
  ) async {
    if (_isLoadingProfiles) return;

    _isLoadingProfiles = true;

    final filters = _mergedFilters(
      page: event.page,
      filter: event.filter,
      minAge: event.minAge,
      maxAge: event.maxAge,
      distance: event.distance,
      interests: event.interests,
      verifiedOnly: event.verifiedOnly,
      sortBy: event.sortBy,
    );

    if (state.profiles.isEmpty || event.page == 1) {
      emit(
        state.copyWith(
          status: ExploreStatus.loading,
          isLoading: true,
          isLoadingMore: false,
          isRefreshing: false,
          currentFilters: filters,
          clearError: true,
          clearMatchId: true,
          clearMatchedProfile: true,
        ),
      );
    }

    try {
      final result = await _exploreService.getExploreProfiles(
        page: event.page,
        filter: filters['filter'] ?? 'all',
        minAge: filters['minAge'],
        maxAge: filters['maxAge'],
        distance: filters['distance'],
        interests: _readStringList(filters['interests']),
        verifiedOnly: filters['verifiedOnly'] ?? false,
        sortBy: filters['sortBy'],
      );

      final newProfiles = _readProfiles(result['profiles']);
      final hasMore = _readBool(result['hasMore']);

      final mergedProfiles = event.page == 1
          ? _dedupeProfiles(newProfiles)
          : _dedupeProfiles([
              ...state.profiles,
              ...newProfiles,
            ]);

      final nextIndex = event.page == 1 ? 0 : state.currentIndex;

      emit(
        state.copyWith(
          profiles: mergedProfiles,
          currentIndex: nextIndex,
          hasMore: hasMore,
          currentPage: event.page,
          currentFilters: filters,
          status: mergedProfiles.isEmpty
              ? ExploreStatus.empty
              : ExploreStatus.success,
          isLoading: false,
          isLoadingMore: false,
          isRefreshing: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: state.profiles.isEmpty
              ? ExploreStatus.error
              : ExploreStatus.success,
          isLoading: false,
          isLoadingMore: false,
          isRefreshing: false,
          error: e.toString(),
        ),
      );
    } finally {
      _isLoadingProfiles = false;
    }
  }

  Future<void> _onRefreshExploreProfiles(
    RefreshExploreProfiles event,
    Emitter<ExploreState> emit,
  ) async {
    if (_isRefreshingProfiles) return;

    _isRefreshingProfiles = true;

    emit(
      state.copyWith(
        status: ExploreStatus.refreshing,
        isRefreshing: true,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
        clearMatchId: true,
        clearMatchedProfile: true,
      ),
    );

    try {
      final filters = state.currentFilters;

      final result = await _exploreService.getExploreProfiles(
        page: 1,
        filter: filters['filter'] ?? 'all',
        minAge: filters['minAge'],
        maxAge: filters['maxAge'],
        distance: filters['distance'],
        interests: _readStringList(filters['interests']),
        verifiedOnly: filters['verifiedOnly'] ?? false,
        sortBy: filters['sortBy'],
      );

      final newProfiles = _dedupeProfiles(
        _readProfiles(result['profiles']),
      );

      final hasMore = _readBool(result['hasMore']);

      emit(
        state.copyWith(
          profiles: newProfiles,
          currentIndex: 0,
          hasMore: hasMore,
          currentPage: 1,
          status:
              newProfiles.isEmpty ? ExploreStatus.empty : ExploreStatus.success,
          isRefreshing: false,
          isLoading: false,
          isLoadingMore: false,
          clearError: true,
          clearLastSwipeAction: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: state.profiles.isEmpty
              ? ExploreStatus.error
              : ExploreStatus.success,
          isRefreshing: false,
          isLoading: false,
          isLoadingMore: false,
          error: e.toString(),
        ),
      );
    } finally {
      _isRefreshingProfiles = false;
    }
  }

  Future<void> _onLoadMoreExploreProfiles(
    LoadMoreExploreProfiles event,
    Emitter<ExploreState> emit,
  ) async {
    if (_isLoadingMoreProfiles) return;
    if (!state.canLoadMore) return;

    _isLoadingMoreProfiles = true;

    emit(
      state.copyWith(
        status: ExploreStatus.loadingMore,
        isLoadingMore: true,
        clearError: true,
      ),
    );

    try {
      final filters = state.currentFilters;
      final nextPage = state.currentPage + 1;

      final result = await _exploreService.getExploreProfiles(
        page: nextPage,
        filter: filters['filter'] ?? 'all',
        minAge: filters['minAge'],
        maxAge: filters['maxAge'],
        distance: filters['distance'],
        interests: _readStringList(filters['interests']),
        verifiedOnly: filters['verifiedOnly'] ?? false,
        sortBy: filters['sortBy'],
      );

      final newProfiles = _readProfiles(result['profiles']);
      final hasMore = _readBool(result['hasMore']);

      final mergedProfiles = _dedupeProfiles([
        ...state.profiles,
        ...newProfiles,
      ]);

      emit(
        state.copyWith(
          profiles: mergedProfiles,
          hasMore: hasMore,
          currentPage: nextPage,
          status: mergedProfiles.isEmpty
              ? ExploreStatus.empty
              : ExploreStatus.success,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ExploreStatus.success,
          isLoadingMore: false,
          error: e.toString(),
        ),
      );
    } finally {
      _isLoadingMoreProfiles = false;
    }
  }

  Future<void> _onSwipeProfile(
    SwipeProfile event,
    Emitter<ExploreState> emit,
  ) async {
    if (_isSwiping) return;
    if (state.swipedProfileIds.contains(event.profileId)) return;

    final currentProfile =
        _profileById(event.profileId) ?? state.currentProfile;

    if (currentProfile == null) return;

    _isSwiping = true;

    final previousState = state;

    final updatedSwipedIds = Set<int>.from(state.swipedProfileIds)
      ..add(event.profileId);

    final actionFeedback = _normalizeSwipeAction(event.action);

    final nextIndex = _safeNextIndex(event.index);

    emit(
      state.copyWith(
        currentIndex: nextIndex,
        swipedProfileIds: updatedSwipedIds,
        lastSwipeAction: actionFeedback,
        totalLikes:
            event.action == 'like' ? state.totalLikes + 1 : state.totalLikes,
        clearError: true,
        clearMatchId: true,
        clearMatchedProfile: true,
      ),
    );

    _scheduleClearSwipeFeedback();

    try {
      final response = await _exploreService.swipe(
        event.profileId,
        event.action,
      );

      final isMatch = _readBool(response['isMatch'] ?? response['is_match']);

      final matchId =
          response['matchId'] ?? response['match_id'] ?? response['id'];

      if (isMatch) {
        emit(
          state.copyWith(
            matchId: matchId?.toString(),
            matchedProfile: currentProfile,
          ),
        );
      }

      if (state.remainingProfiles <= 3 && state.hasMore) {
        add(const LoadMoreExploreProfiles());
      }

      if (state.currentIndex >= state.profiles.length && !state.hasMore) {
        emit(
          state.copyWith(
            status: ExploreStatus.empty,
          ),
        );
      }
    } catch (e) {
      emit(
        previousState.copyWith(
          error: e.toString(),
          clearMatchId: true,
          clearMatchedProfile: true,
          clearLastSwipeAction: true,
        ),
      );
    } finally {
      _isSwiping = false;
    }
  }

  Future<void> _onUpdateExploreFilters(
    UpdateExploreFilters event,
    Emitter<ExploreState> emit,
  ) async {
    final filters = {
      ...state.currentFilters,
      ...event.filters,
      'page': 1,
    };

    emit(
      state.copyWith(
        currentFilters: filters,
        profiles: const [],
        currentIndex: 0,
        currentPage: 1,
        hasMore: true,
        swipedProfileIds: const {},
        status: ExploreStatus.loading,
        isLoading: true,
        clearError: true,
        clearLastSwipeAction: true,
        clearMatchId: true,
        clearMatchedProfile: true,
      ),
    );

    add(
      LoadExploreProfiles(
        page: 1,
        filter: filters['filter'] ?? 'all',
        minAge: filters['minAge'],
        maxAge: filters['maxAge'],
        distance: filters['distance'],
        interests: _readStringList(filters['interests']),
        verifiedOnly: filters['verifiedOnly'] ?? false,
        sortBy: filters['sortBy'],
      ),
    );
  }

  Future<void> _onLoadExploreStats(
    LoadExploreStats event,
    Emitter<ExploreState> emit,
  ) async {
    if (_isLoadingStats) return;

    _isLoadingStats = true;

    try {
      final stats = await _exploreService.getStats();

      emit(
        state.copyWith(
          totalLikes: _readInt(stats['totalLikes'] ?? stats['total_likes']),
        ),
      );
    } catch (e) {
      debugPrint('Error loading explore stats: $e');
    } finally {
      _isLoadingStats = false;
    }
  }

  void _onClearExploreError(
    ClearExploreError event,
    Emitter<ExploreState> emit,
  ) {
    emit(
      state.copyWith(
        clearError: true,
      ),
    );
  }

  void _onClearSwipeFeedback(
    ClearSwipeFeedback event,
    Emitter<ExploreState> emit,
  ) {
    emit(
      state.copyWith(
        clearLastSwipeAction: true,
      ),
    );
  }

  void _onClearMatchState(
    ClearMatchState event,
    Emitter<ExploreState> emit,
  ) {
    emit(
      state.copyWith(
        clearMatchId: true,
        clearMatchedProfile: true,
      ),
    );
  }

  void _onResetExploreState(
    ResetExploreState event,
    Emitter<ExploreState> emit,
  ) {
    _feedbackTimer?.cancel();

    emit(const ExploreState());
  }

  Map<String, dynamic> _mergedFilters({
    required int page,
    required String filter,
    int? minAge,
    int? maxAge,
    int? distance,
    List<String>? interests,
    bool? verifiedOnly,
    String? sortBy,
  }) {
    return {
      ...state.currentFilters,
      'page': page,
      'filter': filter,
      'minAge': minAge,
      'maxAge': maxAge,
      'distance': distance,
      'interests': interests ?? state.currentFilters['interests'],
      'verifiedOnly': verifiedOnly ?? false,
      'sortBy': sortBy,
    };
  }

  List<ProfileModel> _readProfiles(dynamic value) {
    if (value is List<ProfileModel>) {
      return value;
    }

    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => ProfileModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return [];
  }

  List<ProfileModel> _dedupeProfiles(List<ProfileModel> profiles) {
    final map = <int, ProfileModel>{};

    for (final profile in profiles) {
      if (profile.id <= 0) continue;

      map[profile.id] = profile;
    }

    return map.values.toList();
  }

  ProfileModel? _profileById(int profileId) {
    for (final profile in state.profiles) {
      if (profile.id == profileId) {
        return profile;
      }
    }

    return null;
  }

  int _safeNextIndex(int eventIndex) {
    final expectedNext = eventIndex + 1;
    final currentNext = state.currentIndex + 1;

    final next = expectedNext > currentNext ? expectedNext : currentNext;

    if (next > state.profiles.length) {
      return state.profiles.length;
    }

    return next;
  }

  String? _normalizeSwipeAction(String action) {
    switch (action) {
      case 'like':
        return 'like';
      case 'pass':
        return 'pass';
      case 'super_like':
        return 'super_like';
      default:
        return null;
    }
  }

  void _scheduleClearSwipeFeedback() {
    _feedbackTimer?.cancel();

    _feedbackTimer = Timer(
      const Duration(milliseconds: 500),
      () {
        add(const ClearSwipeFeedback());
      },
    );
  }

  bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();

      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }

    return false;
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;

    return 0;
  }

  List<String>? _readStringList(dynamic value) {
    if (value == null) return null;

    if (value is List<String>) {
      return value.where((item) => item.trim().isNotEmpty).toList();
    }

    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return null;
  }

  @override
  Future<void> close() {
    _feedbackTimer?.cancel();

    return super.close();
  }
}
