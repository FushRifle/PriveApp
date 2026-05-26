import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:clique/data/services/insights/insights_service.dart';

part 'insights_event.dart';
part 'insights_state.dart';

class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  final InsightsService _service = InsightsService();

  InsightsBloc() : super(const InsightsState()) {
    on<LoadInsights>(_onLoadInsights);
    on<RefreshInsights>(_onRefreshInsights);
    on<ChangeInsightsPeriod>(_onChangeInsightsPeriod);
    on<LoadRealtimeStats>(_onLoadRealtimeStats);
    on<RefreshRealtimeStats>(_onRefreshRealtimeStats);
    on<ClearInsightsError>(_onClearInsightsError);
    on<ResetInsightsState>(_onResetInsightsState);
  }

  Future<void> _onLoadInsights(
    LoadInsights event,
    Emitter<InsightsState> emit,
  ) async {
    if (state.insights == null) {
      emit(state.copyWith(status: InsightsStatus.loading, clearError: true));
    }

    try {
      final data = await _service.getInsights(days: event.days);
      final insights = _parseInsightsData(data);

      emit(state.copyWith(
        insights: insights,
        currentPeriodDays: event.days,
        status: InsightsStatus.success,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InsightsStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshInsights(
    RefreshInsights event,
    Emitter<InsightsState> emit,
  ) async {
    emit(state.copyWith(status: InsightsStatus.refreshing, clearError: true));

    try {
      final data = await _service.getInsights(days: event.days);
      final insights = _parseInsightsData(data);

      emit(state.copyWith(
        insights: insights,
        currentPeriodDays: event.days,
        status: InsightsStatus.success,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: InsightsStatus.error,
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
    try {
      final data = await _service.getRealtimeStats();
      final stats = RealtimeStats(
        onlineViewers: data['onlineViewers'] ?? data['viewers'] ?? 0,
        activeSessions: data['activeSessions'] ?? data['sessions'] ?? 0,
      );

      emit(state.copyWith(realtimeStats: stats));
    } catch (e) {
      // Silently fail - realtime stats are non-critical
      debugPrint('Failed to load realtime stats: $e');
    }
  }

  Future<void> _onRefreshRealtimeStats(
    RefreshRealtimeStats event,
    Emitter<InsightsState> emit,
  ) async {
    add(LoadRealtimeStats());
  }

  void _onClearInsightsError(
    ClearInsightsError event,
    Emitter<InsightsState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  void _onResetInsightsState(
    ResetInsightsState event,
    Emitter<InsightsState> emit,
  ) {
    emit(const InsightsState());
  }

  InsightsData _parseInsightsData(Map<String, dynamic> data) {
    final overview = data['overview'] as Map<String, dynamic>? ?? {};
    final previousOverview =
        data['previousOverview'] as Map<String, dynamic>? ?? {};

    final demographicsData =
        data['demographics'] as Map<String, dynamic>? ?? {};
    final locationsData = data['topLocations'] as List? ?? [];
    final ageRangesData = data['ageRanges'] as List? ?? [];
    final chartDataMap = data['chartData'] as Map<String, dynamic>? ?? {};

    return InsightsData(
      totalViews: overview['totalViews'] ?? 0,
      totalViewsChange: _getChangePercentage(
        overview['totalViews'],
        previousOverview['totalViews'],
      ),
      totalEngagement: overview['totalEngagement'] ?? 0,
      totalEngagementChange: _getChangePercentage(
        overview['totalEngagement'],
        previousOverview['totalEngagement'],
      ),
      newFollowers: overview['newFollowers'] ?? 0,
      newFollowersChange: _getChangePercentage(
        overview['newFollowers'],
        previousOverview['newFollowers'],
      ),
      totalReach: overview['totalReach'] ?? 0,
      totalReachChange: _getChangePercentage(
        overview['totalReach'],
        previousOverview['totalReach'],
      ),
      engagementRate: (data['engagementRate'] as num?)?.toDouble() ?? 0,
      previousEngagementRate:
          (data['previousEngagementRate'] as num?)?.toDouble() ?? 0,
      demographics: Demographics(
        male: demographicsData['male'] ?? 0,
        female: demographicsData['female'] ?? 0,
        other: demographicsData['other'] ?? 0,
      ),
      topLocations: (locationsData)
          .map((item) => TopLocation(
                location: item['location'] ?? '',
                percentage: (item['percentage'] as num?)?.toDouble() ?? 0,
              ))
          .toList(),
      ageRanges: (ageRangesData)
          .map((item) => AgeRange(
                range: item['range'] ?? '',
                count: item['count'] ?? 0,
              ))
          .toList(),
      chartData: _parseChartData(chartDataMap),
    );
  }

  double _getChangePercentage(dynamic current, dynamic previous) {
    if (current == null || previous == null || previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  Map<String, List<ChartDataPoint>> _parseChartData(Map<String, dynamic> data) {
    final result = <String, List<ChartDataPoint>>{};

    if (data['views'] is List) {
      result['views'] = (data['views'] as List)
          .map((item) => ChartDataPoint(
                label: item['day']?.toString() ?? '',
                value: (item['value'] as num?)?.toDouble() ?? 0,
              ))
          .toList();
    }

    if (data['engagement'] is List) {
      result['engagement'] = (data['engagement'] as List)
          .map((item) => ChartDataPoint(
                label: item['day']?.toString() ?? '',
                value: (item['value'] as num?)?.toDouble() ?? 0,
              ))
          .toList();
    }

    if (data['reach'] is List) {
      result['reach'] = (data['reach'] as List)
          .map((item) => ChartDataPoint(
                label: item['day']?.toString() ?? '',
                value: (item['value'] as num?)?.toDouble() ?? 0,
              ))
          .toList();
    }

    return result;
  }
}
