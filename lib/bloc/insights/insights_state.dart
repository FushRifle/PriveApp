part of 'insights_bloc.dart';

class InsightsData {
  final int totalViews;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final int totalFollowers;
  final int profileViews;
  final double engagementRate;
  final List<DailyStats> dailyStats;
  final List<TopContent> topPosts;
  final List<TopContent> topReels;
  final AudienceDemographics demographics;

  const InsightsData({
    this.totalViews = 0,
    this.totalLikes = 0,
    this.totalComments = 0,
    this.totalShares = 0,
    this.totalFollowers = 0,
    this.profileViews = 0,
    this.engagementRate = 0.0,
    this.dailyStats = const [],
    this.topPosts = const [],
    this.topReels = const [],
    required this.demographics,
  });

  factory InsightsData.fromJson(Map<String, dynamic> json) {
    return InsightsData(
      totalViews: json['totalViews'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      totalShares: json['totalShares'] ?? 0,
      totalFollowers: json['totalFollowers'] ?? 0,
      profileViews: json['profileViews'] ?? 0,
      engagementRate: (json['engagementRate'] ?? 0.0).toDouble(),
      dailyStats: (json['dailyStats'] as List?)
              ?.map((d) => DailyStats.fromJson(d))
              .toList() ??
          [],
      topPosts: (json['topPosts'] as List?)
              ?.map((p) => TopContent.fromJson(p))
              .toList() ??
          [],
      topReels: (json['topReels'] as List?)
              ?.map((r) => TopContent.fromJson(r))
              .toList() ??
          [],
      demographics: AudienceDemographics.fromJson(json['demographics'] ?? {}),
    );
  }

  InsightsData copyWith({
    int? totalViews,
    int? totalLikes,
    int? totalComments,
    int? totalShares,
    int? totalFollowers,
    int? profileViews,
    double? engagementRate,
    List<DailyStats>? dailyStats,
    List<TopContent>? topPosts,
    List<TopContent>? topReels,
    AudienceDemographics? demographics,
  }) {
    return InsightsData(
      totalViews: totalViews ?? this.totalViews,
      totalLikes: totalLikes ?? this.totalLikes,
      totalComments: totalComments ?? this.totalComments,
      totalShares: totalShares ?? this.totalShares,
      totalFollowers: totalFollowers ?? this.totalFollowers,
      profileViews: profileViews ?? this.profileViews,
      engagementRate: engagementRate ?? this.engagementRate,
      dailyStats: dailyStats ?? this.dailyStats,
      topPosts: topPosts ?? this.topPosts,
      topReels: topReels ?? this.topReels,
      demographics: demographics ?? this.demographics,
    );
  }
}

class DailyStats {
  final DateTime date;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int newFollowers;

  const DailyStats({
    required this.date,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.newFollowers,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      newFollowers: json['newFollowers'] ?? 0,
    );
  }
}

class TopContent {
  final int id;
  final String title;
  final String? thumbnail;
  final int views;
  final int likes;
  final int comments;
  final int shares;

  const TopContent({
    required this.id,
    required this.title,
    this.thumbnail,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
  });

  factory TopContent.fromJson(Map<String, dynamic> json) {
    return TopContent(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
    );
  }
}

class AudienceDemographics {
  final Map<String, int> ageGroups;
  final Map<String, int> gender;
  final Map<String, int> topLocations;
  final Map<String, int> deviceTypes;

  const AudienceDemographics({
    this.ageGroups = const {},
    this.gender = const {},
    this.topLocations = const {},
    this.deviceTypes = const {},
  });

  factory AudienceDemographics.fromJson(Map<String, dynamic> json) {
    return AudienceDemographics(
      ageGroups: Map<String, int>.from(json['ageGroups'] ?? {}),
      gender: Map<String, int>.from(json['gender'] ?? {}),
      topLocations: Map<String, int>.from(json['topLocations'] ?? {}),
      deviceTypes: Map<String, int>.from(json['deviceTypes'] ?? {}),
    );
  }
}

class RealtimeStats {
  final int onlineFollowers;
  final int activeSessions;
  final int viewsLastHour;
  final int likesLastHour;
  final int commentsLastHour;
  final DateTime updatedAt;

  const RealtimeStats({
    this.onlineFollowers = 0,
    this.activeSessions = 0,
    this.viewsLastHour = 0,
    this.likesLastHour = 0,
    this.commentsLastHour = 0,
    required this.updatedAt,
  });

  factory RealtimeStats.fromJson(Map<String, dynamic> json) {
    return RealtimeStats(
      onlineFollowers: json['onlineFollowers'] ?? 0,
      activeSessions: json['activeSessions'] ?? 0,
      viewsLastHour: json['viewsLastHour'] ?? 0,
      likesLastHour: json['likesLastHour'] ?? 0,
      commentsLastHour: json['commentsLastHour'] ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }
}

class InsightsState extends Equatable {
  final InsightsData? insights;
  final RealtimeStats? realtimeStats;
  final int currentPeriodDays;
  final InsightsStatus status;
  final InsightsStatus realtimeStatus;
  final String? error;
  final bool isLoading;
  final bool isRefreshing;
  final DateTime? lastUpdated;

  const InsightsState({
    this.insights,
    this.realtimeStats,
    this.currentPeriodDays = 30,
    this.status = InsightsStatus.initial,
    this.realtimeStatus = InsightsStatus.initial,
    this.error,
    this.isLoading = false,
    this.isRefreshing = false,
    this.lastUpdated,
  });

  InsightsState copyWith({
    InsightsData? insights,
    RealtimeStats? realtimeStats,
    int? currentPeriodDays,
    InsightsStatus? status,
    InsightsStatus? realtimeStatus,
    String? error,
    bool? isLoading,
    bool? isRefreshing,
    DateTime? lastUpdated,
  }) {
    return InsightsState(
      insights: insights ?? this.insights,
      realtimeStats: realtimeStats ?? this.realtimeStats,
      currentPeriodDays: currentPeriodDays ?? this.currentPeriodDays,
      status: status ?? this.status,
      realtimeStatus: realtimeStatus ?? this.realtimeStatus,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        insights,
        realtimeStats,
        currentPeriodDays,
        status,
        realtimeStatus,
        error,
        isLoading,
        isRefreshing,
        lastUpdated,
      ];
}

enum InsightsStatus {
  initial,
  loading,
  refreshing,
  success,
  error,
}
