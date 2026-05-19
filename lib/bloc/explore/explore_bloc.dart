import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cirqle/data/models/profile_model.dart';
import 'package:cirqle/data/services/explore/explore_service.dart';
import 'package:flutter/foundation.dart';

part 'explore_event.dart';
part 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final ExploreService _exploreService = ExploreService();

  ExploreBloc() : super(const ExploreState()) {
    on<LoadExploreProfiles>(_onLoadExploreProfiles);
    on<RefreshExploreProfiles>(_onRefreshExploreProfiles);
    on<LoadMoreExploreProfiles>(_onLoadMoreExploreProfiles);
    on<SwipeProfile>(_onSwipeProfile);
    on<UpdateExploreFilters>(_onUpdateExploreFilters);
    on<LoadExploreStats>(_onLoadExploreStats);
    on<ClearExploreError>(_onClearExploreError);
    on<ResetExploreState>(_onResetExploreState);
  }

  Future<void> _onLoadExploreProfiles(
    LoadExploreProfiles event,
    Emitter<ExploreState> emit,
  ) async {
    if (state.profiles.isEmpty) {
      emit(state.copyWith(
        status: ExploreStatus.loading,
        isLoading: true,
        error: null,
      ));
    }

    try {
      final result = await _exploreService.getExploreProfiles(
        page: event.page,
        filter: event.filter,
        minAge: event.minAge,
        maxAge: event.maxAge,
        distance: event.distance,
        verifiedOnly: event.verifiedOnly,
        sortBy: event.sortBy,
      );

      final newProfiles = result['profiles'] as List<ProfileModel>;
      final hasMore = result['hasMore'] as bool;

      emit(state.copyWith(
        profiles:
            event.page == 1 ? newProfiles : [...state.profiles, ...newProfiles],
        currentIndex: event.page == 1 ? 0 : state.currentIndex,
        hasMore: hasMore,
        currentPage: event.page,
        status:
            newProfiles.isEmpty ? ExploreStatus.empty : ExploreStatus.success,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExploreStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshExploreProfiles(
    RefreshExploreProfiles event,
    Emitter<ExploreState> emit,
  ) async {
    emit(state.copyWith(
      status: ExploreStatus.refreshing,
      isRefreshing: true,
      error: null,
    ));

    try {
      final result = await _exploreService.getExploreProfiles(
        page: 1,
        filter: state.currentFilters['filter'],
        minAge: state.currentFilters['minAge'],
        maxAge: state.currentFilters['maxAge'],
        distance: state.currentFilters['distance'],
        verifiedOnly: state.currentFilters['verifiedOnly'],
        sortBy: state.currentFilters['sortBy'],
      );

      final newProfiles = result['profiles'] as List<ProfileModel>;
      final hasMore = result['hasMore'] as bool;

      emit(state.copyWith(
        profiles: newProfiles,
        currentIndex: 0,
        hasMore: hasMore,
        currentPage: 1,
        status:
            newProfiles.isEmpty ? ExploreStatus.empty : ExploreStatus.success,
        isRefreshing: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExploreStatus.error,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreExploreProfiles(
    LoadMoreExploreProfiles event,
    Emitter<ExploreState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore || state.isRefreshing) return;

    emit(state.copyWith(
      status: ExploreStatus.loadingMore,
      isLoadingMore: true,
    ));

    try {
      final nextPage = state.currentPage + 1;
      final result = await _exploreService.getExploreProfiles(
        page: nextPage,
        filter: state.currentFilters['filter'],
        minAge: state.currentFilters['minAge'],
        maxAge: state.currentFilters['maxAge'],
        distance: state.currentFilters['distance'],
        verifiedOnly: state.currentFilters['verifiedOnly'],
        sortBy: state.currentFilters['sortBy'],
      );

      final newProfiles = result['profiles'] as List<ProfileModel>;
      final hasMore = result['hasMore'] as bool;

      emit(state.copyWith(
        profiles: [...state.profiles, ...newProfiles],
        hasMore: hasMore,
        currentPage: nextPage,
        status: ExploreStatus.success,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExploreStatus.error,
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSwipeProfile(
    SwipeProfile event,
    Emitter<ExploreState> emit,
  ) async {
    if (state.swipedProfileIds.contains(event.profileId)) return;

    final updatedSwipedIds = Set<int>.from(state.swipedProfileIds)
      ..add(event.profileId);

    // Update last swipe action for UI feedback
    String? actionFeedback;
    switch (event.action) {
      case 'like':
        actionFeedback = 'like';
        break;
      case 'pass':
        actionFeedback = 'pass';
        break;
      case 'super_like':
        actionFeedback = 'super_like';
        break;
    }

    emit(state.copyWith(
      swipedProfileIds: updatedSwipedIds,
      lastSwipeAction: actionFeedback,
    ));

    try {
      final response =
          await _exploreService.swipe(event.profileId, event.action);

      // Update total likes if it was a like
      if (event.action == 'like') {
        emit(state.copyWith(totalLikes: state.totalLikes + 1));
      }

      // Move to next profile
      final nextIndex = state.currentIndex + 1;

      // Clear swipe feedback after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!emit.isDone) {
          emit(state.copyWith(lastSwipeAction: null));
        }
      });

      emit(state.copyWith(
        currentIndex: nextIndex,
      ));

      // Check if it's a match
      if (response['isMatch'] == true) {
        // Emit a match event (handled in UI listener)
        // We'll handle this in the UI via a stream or callback
      }
    } catch (e) {
      // Rollback on error
      emit(state.copyWith(
        swipedProfileIds: state.swipedProfileIds..remove(event.profileId),
        lastSwipeAction: null,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateExploreFilters(
    UpdateExploreFilters event,
    Emitter<ExploreState> emit,
  ) async {
    emit(state.copyWith(
      currentFilters: event.filters,
      currentPage: 1,
      profiles: [],
      currentIndex: 0,
    ));
    add(LoadExploreProfiles(
      page: 1,
      filter: event.filters['filter'],
      minAge: event.filters['minAge'],
      maxAge: event.filters['maxAge'],
      distance: event.filters['distance'],
      verifiedOnly: event.filters['verifiedOnly'],
      sortBy: event.filters['sortBy'],
    ));
  }

  Future<void> _onLoadExploreStats(
    LoadExploreStats event,
    Emitter<ExploreState> emit,
  ) async {
    try {
      final stats = await _exploreService.getStats();
      emit(state.copyWith(
        totalLikes: stats['totalLikes'] ?? 0,
      ));
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  void _onClearExploreError(
    ClearExploreError event,
    Emitter<ExploreState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  void _onResetExploreState(
    ResetExploreState event,
    Emitter<ExploreState> emit,
  ) {
    emit(const ExploreState());
  }
}
