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
        onlineViewers: _readInt(
          data['onlineViewers'] ?? data['viewers'] ?? data['viewsToday'],
        ),
        activeSessions: _readInt(
          data['activeSessions'] ?? data['sessions'] ?? data['likesToday'],
        ),
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
    final root = _unwrapInsightsPayload(data);

    final overview = _readMap(root['overview'] ?? root['summary']);
    final previousOverview =
        _readMap(root['previousOverview'] ?? root['previous_summary']);

    final demographicsData =
        _readMap(root['demographics'] ?? root['audienceDemographics']);
    final locationsData = _readList(root['topLocations'] ?? root['locations']);
    final ageRangesData = _readList(root['ageRanges'] ?? root['ages']);
    final chartDataMap = _readMap(root['chartData'] ?? root['charts']);
    final metrics = _readList(root['metrics'] ?? root['dailyMetrics']);
    final genderData = _readMap(demographicsData['genders']);
    final ageGroupData = _readMap(demographicsData['ageGroups']);
    final previousEngagementRate =
        _readDouble(root['previousEngagementRate']) ?? 0;
    final totalViews = overview['totalViews'] ??
        overview['views'] ??
        root['totalViews'] ??
        root['totalImpressions'] ??
        root['views'];
    final totalEngagement = overview['totalEngagement'] ??
        overview['engagement'] ??
        root['totalEngagement'] ??
        root['engagement'];
    final newFollowers = overview['newFollowers'] ??
        root['newFollowers'] ??
        root['followerGrowth'] ??
        root['followers'];
    final totalReach = overview['totalReach'] ??
        overview['reach'] ??
        root['totalReach'] ??
        root['reach'];

    return InsightsData(
      totalViews: _readInt(totalViews),
      totalViewsChange: _getChangePercentage(
        totalViews,
        previousOverview['totalViews'],
      ),
      totalEngagement: _readInt(totalEngagement),
      totalEngagementChange: _getChangePercentage(
        totalEngagement,
        previousOverview['totalEngagement'],
      ),
      newFollowers: _readInt(newFollowers),
      newFollowersChange: _getChangePercentage(
        newFollowers,
        previousOverview['newFollowers'],
      ),
      totalReach: _readInt(totalReach),
      totalReachChange: _getChangePercentage(
        totalReach,
        previousOverview['totalReach'],
      ),
      engagementRate: _readDouble(root['engagementRate']) ??
          _readDouble(root['averageEngagementRate']) ??
          0,
      previousEngagementRate: previousEngagementRate,
      demographics: Demographics(
        male: _readInt(demographicsData['male'] ?? genderData['male']),
        female: _readInt(demographicsData['female'] ?? genderData['female']),
        other: _readInt(demographicsData['other'] ?? genderData['other']),
      ),
      topLocations: (locationsData)
          .map(_readMap)
          .where((item) => item.isNotEmpty)
          .map((item) => TopLocation(
                location: item['location']?.toString() ??
                    [item['city'], item['country']]
                        .where((value) =>
                            value != null && value.toString().isNotEmpty)
                        .join(', '),
                percentage: _readDouble(item['percentage']) ?? 0,
              ))
          .toList(),
      ageRanges: (ageRangesData.isNotEmpty
              ? ageRangesData
              : ageGroupData.entries
                  .map((entry) => {
                        'range': entry.key,
                        'count': entry.value,
                      })
                  .toList())
          .map(_readMap)
          .where((item) => item.isNotEmpty)
          .map((item) => AgeRange(
                range: item['range']?.toString() ?? '',
                count: _readInt(item['count']),
              ))
          .toList(),
      chartData: chartDataMap.isNotEmpty
          ? _parseChartData(chartDataMap)
          : _parseMetricsChartData(metrics),
    );
  }

  Map<String, dynamic> _unwrapInsightsPayload(Map<String, dynamic> data) {
    for (final key in ['data', 'insights', 'analytics']) {
      final value = data[key];
      if (value is Map) return _readMap(value);
    }

    return data;
  }

  double _getChangePercentage(dynamic current, dynamic previous) {
    final currentValue = _readDouble(current);
    final previousValue = _readDouble(previous);

    if (currentValue == null || previousValue == null || previousValue == 0) {
      return 0;
    }

    return ((currentValue - previousValue) / previousValue) * 100;
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

  Map<String, List<ChartDataPoint>> _parseMetricsChartData(List metrics) {
    final views = <ChartDataPoint>[];
    final engagement = <ChartDataPoint>[];
    final reach = <ChartDataPoint>[];

    for (final item in metrics.reversed) {
      if (item is! Map) continue;

      final metric = Map<String, dynamic>.from(item);
      final label = _formatMetricDate(metric['date']);

      views.add(
        ChartDataPoint(
          label: label,
          value: _readInt(metric['impressions']).toDouble(),
        ),
      );
      engagement.add(
        ChartDataPoint(
          label: label,
          value: _readInt(metric['engagement']).toDouble(),
        ),
      );
      reach.add(
        ChartDataPoint(
          label: label,
          value: _readInt(metric['reach']).toDouble(),
        ),
      );
    }

    return {
      'views': views,
      'engagement': engagement,
      'reach': reach,
    };
  }

  String _formatMetricDate(dynamic value) {
    if (value == null) return '';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return '${parsed.month}/${parsed.day}';
  }

  Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    return {};
  }

  List<dynamic> _readList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;

    return 0;
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
