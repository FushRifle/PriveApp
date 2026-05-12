import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:Prive/data/services/explore/explore_service.dart';
import 'package:Prive/data/models/profile_model.dart';

part 'explore_event.dart';
part 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final ExploreService _exploreService = ExploreService();

  Map<String, dynamic> _currentQueryParams = {};

  ExploreBloc() : super(const ExploreState()) {
    on<LoadExploreProfiles>(_onLoadExploreProfiles);
    on<RefreshExploreProfiles>(_onRefreshExploreProfiles);
    on<LoadMoreExploreProfiles>(_onLoadMoreExploreProfiles);
    on<SwipeProfile>(_onSwipeProfile);
    on<LoadExploreFilters>(_onLoadExploreFilters);
    on<LoadMatches>(_onLoadMatches);
    on<LoadMoreMatches>(_onLoadMoreMatches);
    on<LoadLikedProfiles>(_onLoadLikedProfiles);
    on<LoadLikedByProfiles>(_onLoadLikedByProfiles);
    on<LoadExploreStats>(_onLoadExploreStats);
    on<UpdateExploreFilters>(_onUpdateExploreFilters);
    on<ClearExploreError>(_onClearExploreError);
    on<ResetExploreState>(_onResetExploreState);
  }

  Future<void> _onLoadExploreProfiles(
    LoadExploreProfiles event,
    Emitter<ExploreState> emit,
  ) async {
    if (state.isLoading) return;

    // Save current query params for pagination
    _currentQueryParams = {
      'filter': event.filter,
      if (event.minAge != null) 'minAge': event.minAge,
      if (event.maxAge != null) 'maxAge': event.maxAge,
      if (event.distance != null) 'distance': event.distance,
      if (event.verifiedOnly != null) 'verifiedOnly': event.verifiedOnly,
      if (event.sortBy != null) 'sortBy': event.sortBy,
    };

    emit(state.copyWith(
      status: ExploreStatus.loading,
      isLoading: true,
      error: null,
    ));

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

      emit(state.copyWith(
        profiles: result['profiles'],
        hasMoreProfiles: result['hasMore'],
        currentPage: result['page'],
        totalProfiles: result['total'],
        status: ExploreStatus.success,
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
        filter: state.currentFilter,
        minAge: state.minAge,
        maxAge: state.maxAge,
        distance: state.distance,
        verifiedOnly: state.verifiedOnly,
        sortBy: state.sortBy,
      );

      emit(state.copyWith(
        profiles: result['profiles'],
        hasMoreProfiles: result['hasMore'],
        currentPage: result['page'],
        totalProfiles: result['total'],
        status: ExploreStatus.success,
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
    if (!state.hasMoreProfiles || state.isLoadingMore || state.isRefreshing)
      return;

    emit(state.copyWith(
      status: ExploreStatus.loadingMore,
      isLoadingMore: true,
    ));

    try {
      final nextPage = state.currentPage + 1;
      final result = await _exploreService.getExploreProfiles(
        page: nextPage,
        filter: state.currentFilter,
        minAge: state.minAge,
        maxAge: state.maxAge,
        distance: state.distance,
        verifiedOnly: state.verifiedOnly,
        sortBy: state.sortBy,
      );

      final updatedProfiles = List<ProfileModel>.from(state.profiles)
        ..addAll(result['profiles']);

      emit(state.copyWith(
        profiles: updatedProfiles,
        hasMoreProfiles: result['hasMore'],
        currentPage: result['page'],
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
    // Find and remove the swiped profile optimistically
    final swipedIndex =
        state.profiles.indexWhere((p) => p.id == event.profileId);
    if (swipedIndex == -1) return;

    final updatedProfiles = List<ProfileModel>.from(state.profiles)
      ..removeAt(swipedIndex);

    emit(state.copyWith(
      profiles: updatedProfiles,
    ));

    try {
      final result = await _exploreService.swipe(event.profileId, event.action);

      // If it's a match, you might want to show a match dialog
      if (result['isMatch'] == true) {
        // Emit match event or show dialog (handled in UI)
      }
    } catch (e) {
      // Rollback on error
      emit(state.copyWith(
        profiles: state.profiles,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadExploreFilters(
    LoadExploreFilters event,
    Emitter<ExploreState> emit,
  ) async {
    try {
      final filters = await _exploreService.getFilters();
      emit(state.copyWith(
        availableFilters: filters,
      ));
    } catch (e) {
      print('Error loading filters: $e');
    }
  }

  Future<void> _onLoadMatches(
    LoadMatches event,
    Emitter<ExploreState> emit,
  ) async {
    emit(state.copyWith(
      matchesStatus: ExploreStatus.loading,
    ));

    try {
      final result = await _exploreService.getMatches(page: event.page);

      emit(state.copyWith(
        matches: result['matches'] ?? [],
        hasMoreMatches: result['hasMore'] ?? false,
        matchesPage: result['page'] ?? 1,
        matchesStatus: ExploreStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        matchesStatus: ExploreStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreMatches(
    LoadMoreMatches event,
    Emitter<ExploreState> emit,
  ) async {
    if (!state.hasMoreMatches || state.matchesStatus == ExploreStatus.loading)
      return;

    emit(state.copyWith(matchesStatus: ExploreStatus.loadingMore));

    try {
      final nextPage = state.matchesPage + 1;
      final result = await _exploreService.getMatches(page: nextPage);

      final updatedMatches = List.from(state.matches)
        ..addAll(result['matches'] ?? []);

      emit(state.copyWith(
        matches: updatedMatches,
        hasMoreMatches: result['hasMore'] ?? false,
        matchesPage: result['page'] ?? nextPage,
        matchesStatus: ExploreStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        matchesStatus: ExploreStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadLikedProfiles(
    LoadLikedProfiles event,
    Emitter<ExploreState> emit,
  ) async {
    emit(state.copyWith(likedStatus: ExploreStatus.loading));

    try {
      final result = await _exploreService.getLikedProfiles(page: event.page);

      emit(state.copyWith(
        likedProfiles: result['profiles'] ?? [],
        hasMoreLiked: result['hasMore'] ?? false,
        likedStatus: ExploreStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        likedStatus: ExploreStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadLikedByProfiles(
    LoadLikedByProfiles event,
    Emitter<ExploreState> emit,
  ) async {
    emit(state.copyWith(likedByStatus: ExploreStatus.loading));

    try {
      final result = await _exploreService.getLikedByProfiles(page: event.page);

      emit(state.copyWith(
        likedByProfiles: result['profiles'] ?? [],
        hasMoreLikedBy: result['hasMore'] ?? false,
        likedByStatus: ExploreStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        likedByStatus: ExploreStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadExploreStats(
    LoadExploreStats event,
    Emitter<ExploreState> emit,
  ) async {
    emit(state.copyWith(statsStatus: ExploreStatus.loading));

    try {
      final stats = await _exploreService.getStats();

      emit(state.copyWith(
        stats: stats,
        statsStatus: ExploreStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        statsStatus: ExploreStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateExploreFilters(
    UpdateExploreFilters event,
    Emitter<ExploreState> emit,
  ) async {
    emit(state.copyWith(
      currentFilter: event.filter,
      minAge: event.minAge,
      maxAge: event.maxAge,
      distance: event.distance,
      verifiedOnly: event.verifiedOnly,
      sortBy: event.sortBy,
    ));

    // Reload profiles with new filters
    add(const LoadExploreProfiles(page: 1));
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
