part of 'insights_bloc.dart';

enum InsightsStatus { initial, loading, refreshing, success, error }

class ChartDataPoint {
  final String label;
  final double value;

  const ChartDataPoint({required this.label, required this.value});
}

class Demographics {
  final int male;
  final int female;
  final int other;

  const Demographics({
    this.male = 0,
    this.female = 0,
    this.other = 0,
  });
}

class TopLocation {
  final String location;
  final double percentage;

  const TopLocation({required this.location, required this.percentage});
}

class AgeRange {
  final String range;
  final int count;

  const AgeRange({required this.range, required this.count});
}

class InsightsData {
  final int totalViews;
  final double totalViewsChange;
  final int totalEngagement;
  final double totalEngagementChange;
  final int newFollowers;
  final double newFollowersChange;
  final int totalReach;
  final double totalReachChange;
  final double engagementRate;
  final double previousEngagementRate;
  final Demographics demographics;
  final List<TopLocation> topLocations;
  final List<AgeRange> ageRanges;
  final Map<String, List<ChartDataPoint>> chartData;

  const InsightsData({
    this.totalViews = 0,
    this.totalViewsChange = 0,
    this.totalEngagement = 0,
    this.totalEngagementChange = 0,
    this.newFollowers = 0,
    this.newFollowersChange = 0,
    this.totalReach = 0,
    this.totalReachChange = 0,
    this.engagementRate = 0,
    this.previousEngagementRate = 0,
    this.demographics = const Demographics(),
    this.topLocations = const [],
    this.ageRanges = const [],
    this.chartData = const {},
  });
}

class RealtimeStats {
  final int onlineViewers;
  final int activeSessions;

  const RealtimeStats({
    this.onlineViewers = 0,
    this.activeSessions = 0,
  });
}

class InsightsState extends Equatable {
  final InsightsStatus status;
  final InsightsData? insights;
  final RealtimeStats? realtimeStats;
  final int currentPeriodDays;
  final String? error;

  const InsightsState({
    this.status = InsightsStatus.initial,
    this.insights,
    this.realtimeStats,
    this.currentPeriodDays = 30,
    this.error,
  });

  InsightsState copyWith({
    InsightsStatus? status,
    InsightsData? insights,
    RealtimeStats? realtimeStats,
    int? currentPeriodDays,
    String? error,
    bool clearError = false,
  }) {
    return InsightsState(
      status: status ?? this.status,
      insights: insights ?? this.insights,
      realtimeStats: realtimeStats ?? this.realtimeStats,
      currentPeriodDays: currentPeriodDays ?? this.currentPeriodDays,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        insights,
        realtimeStats,
        currentPeriodDays,
        error,
      ];
}
