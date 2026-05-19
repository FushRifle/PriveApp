import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/data/services/socials/insights_service.dart';

part 'insights_event.dart';
part 'insights_state.dart';

class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  final InsightsService _insightsService = InsightsService();

  // Debounce tracking to avoid too many requests
  final Map<String, DateTime> _lastTrackedEvents = {};
  static const _trackingDebounce = Duration(seconds: 2);

  InsightsBloc() : super(const InsightsState()) {
    on<LoadInsights>(_onLoadInsights);
    on<RefreshInsights>(_onRefreshInsights);
    on<ChangeInsightsPeriod>(_onChangeInsightsPeriod);
    on<LoadRealtimeStats>(_onLoadRealtimeStats);
    on<RefreshRealtimeStats>(_onRefreshRealtimeStats);

    // Tracking events (fire and forget - don't await)
    on<TrackEvent>(_onTrackEvent);
    on<TrackPostView>(_onTrackPostView);
    on<TrackPostLike>(_onTrackPostLike);
    on<TrackPostComment>(_onTrackPostComment);
    on<TrackPostShare>(_onTrackPostShare);
    on<TrackReelView>(_onTrackReelView);
    on<TrackReelLike>(_onTrackReelLike);
    on<TrackReelShare>(_onTrackReelShare);
    on<TrackProfileView>(_onTrackProfileView);
    on<TrackFollow>(_onTrackFollow);
    on<TrackStoryView>(_onTrackStoryView);
    on<TrackSearch>(_onTrackSearch);

    on<ClearInsightsError>(_onClearInsightsError);
    on<ResetInsightsState>(_onResetInsightsState);
  }

  Future<void> _onLoadInsights(
    LoadInsights event,
    Emitter<InsightsState> emit,
  ) async {
    if (state.insights == null) {
      emit(state.copyWith(
        status: InsightsStatus.loading,
        isLoading: true,
        error: null,
      ));
    }

    try {
      final insightsData = await _insightsService.getInsights(days: event.days);
      final insights = InsightsData.fromJson(insightsData);

      emit(state.copyWith(
        insights: insights,
        currentPeriodDays: event.days,
        status: InsightsStatus.success,
        isLoading: false,
        error: null,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InsightsStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshInsights(
    RefreshInsights event,
    Emitter<InsightsState> emit,
  ) async {
    emit(state.copyWith(
      status: InsightsStatus.refreshing,
      isRefreshing: true,
      error: null,
    ));

    try {
      final insightsData = await _insightsService.getInsights(days: event.days);
      final insights = InsightsData.fromJson(insightsData);

      emit(state.copyWith(
        insights: insights,
        currentPeriodDays: event.days,
        status: InsightsStatus.success,
        isRefreshing: false,
        error: null,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InsightsStatus.error,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onChangeInsightsPeriod(
    ChangeInsightsPeriod event,
    Emitter<InsightsState> emit,
  ) async {
    add(LoadInsights(days: event.days));
  }

  Future<void> _onLoadRealtimeStats(
    LoadRealtimeStats event,
    Emitter<InsightsState> emit,
  ) async {
    if (state.realtimeStats == null) {
      emit(state.copyWith(
        realtimeStatus: InsightsStatus.loading,
      ));
    }

    try {
      final statsData = await _insightsService.getRealtimeStats();
      final stats = RealtimeStats.fromJson(statsData);

      emit(state.copyWith(
        realtimeStats: stats,
        realtimeStatus: InsightsStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        realtimeStatus: InsightsStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshRealtimeStats(
    RefreshRealtimeStats event,
    Emitter<InsightsState> emit,
  ) async {
    try {
      final statsData = await _insightsService.getRealtimeStats();
      final stats = RealtimeStats.fromJson(statsData);

      emit(state.copyWith(
        realtimeStats: stats,
        realtimeStatus: InsightsStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        realtimeStatus: InsightsStatus.error,
        error: e.toString(),
      ));
    }
  }

  // Tracking events - fire and forget with debounce
  Future<void> _onTrackEvent(
    TrackEvent event,
    Emitter<InsightsState> emit,
  ) async {
    final key = '${event.eventType}_${event.objectType}_${event.objectId}';

    // Debounce to avoid duplicate tracking in quick succession
    final lastTracked = _lastTrackedEvents[key];
    if (lastTracked != null &&
        DateTime.now().difference(lastTracked) < _trackingDebounce) {
      return;
    }

    _lastTrackedEvents[key] = DateTime.now();

    try {
      // Don't await - fire and forget
      _insightsService.trackEvent(
        eventType: event.eventType,
        objectType: event.objectType,
        objectId: event.objectId,
        section: event.section,
        source: event.source,
      );
    } catch (e) {
      // Silently fail - tracking shouldn't break user experience
      print('Failed to track event: $e');
    }
  }

  Future<void> _onTrackPostView(
    TrackPostView event,
    Emitter<InsightsState> emit,
  ) async {
    add(TrackEvent(
      eventType: 'view',
      objectType: 'post',
      objectId: event.postId,
      section: event.section,
    ));
  }

  Future<void> _onTrackPostLike(
    TrackPostLike event,
    Emitter<InsightsState> emit,
  ) async {
    add(TrackEvent(
      eventType: 'like',
      objectType: 'post',
      objectId: event.postId,
      section: event.section,
    ));
  }

  Future<void> _onTrackPostComment(
    TrackPostComment event,
    Emitter<InsightsState> emit,
  ) async {
    add(TrackEvent(
      eventType: 'comment',
      objectType: 'post',
      objectId: event.postId,
      section: event.section,
    ));
  }

  Future<void> _onTrackPostShare(
    TrackPostShare event,
    Emitter<InsightsState> emit,
  ) async {
    add(TrackEvent(
      eventType: 'share',
      objectType: 'post',
      objectId: event.postId,
      section: event.section,
    ));
  }

  Future<void> _onTrackReelView(
    TrackReelView event,
    Emitter<InsightsState> emit,
  ) async {
    add(TrackEvent(
      eventType: 'view',
      objectType: 'reel',
      objectId: event.reelId,
      section: event.section,
    ));
  }

  Future<void> _onTrackReelLike(
    TrackReelLike event,
    Emitter<InsightsState> emit,
  ) async {
    add(TrackEvent(
      eventType: 'like',
      objectType: 'reel',
      objectId: event.reelId,
      section: event.section,
    ));
  }

  Future<void> _onTrackReelShare(
    TrackReelShare event,
    Emitter<InsightsState> emit,
  ) async {
    add(TrackEvent(
      eventType: 'share',
      objectType: 'reel',
      objectId: event.reelId,
      section: event.section,
    ));
  }

  Future<void> _onTrackProfileView(
    TrackProfileView event,
    Emitter<InsightsState> emit,
  ) async {
    add(TrackEvent(
      eventType: 'view',
      objectType: 'profile',
      objectId: event.userId,
      section: event.section,
    ));
  }

  Future<void> _onTrackFollow(
    TrackFollow event,
    Emitter<InsightsState> emit,
  ) async {
    add(TrackEvent(
      eventType: 'follow',
      objectType: 'user',
      objectId: event.userId,
      section: event.section,
    ));
  }

  Future<void> _onTrackStoryView(
    TrackStoryView event,
    Emitter<InsightsState> emit,
  ) async {
    add(TrackEvent(
      eventType: 'view',
      objectType: 'story',
      objectId: event.storyId,
      section: event.section,
    ));
  }

  Future<void> _onTrackSearch(
    TrackSearch event,
    Emitter<InsightsState> emit,
  ) async {
    final key = 'search_${event.query}';

    final lastTracked = _lastTrackedEvents[key];
    if (lastTracked != null &&
        DateTime.now().difference(lastTracked) < _trackingDebounce) {
      return;
    }

    _lastTrackedEvents[key] = DateTime.now();

    try {
      await _insightsService.trackSearch(event.query, section: event.section);
    } catch (e) {
      print('Failed to track search: $e');
    }
  }

  void _onClearInsightsError(
    ClearInsightsError event,
    Emitter<InsightsState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  void _onResetInsightsState(
    ResetInsightsState event,
    Emitter<InsightsState> emit,
  ) {
    _lastTrackedEvents.clear();
    emit(const InsightsState());
  }
}
