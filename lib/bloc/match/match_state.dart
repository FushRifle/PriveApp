part of 'match_bloc.dart';

class MatchUser {
  final int id;
  final String name;
  final String? avatar;
  final int age;
  final String? location;
  final List<String>? interests;
  final bool isVerified;

  const MatchUser({
    required this.id,
    required this.name,
    this.avatar,
    required this.age,
    this.location,
    this.interests,
    this.isVerified = false,
  });

  factory MatchUser.fromJson(Map<String, dynamic> json) {
    return MatchUser(
      id: json['id'] ?? json['userId'] ?? json['user_id'] ?? 0,
      name: json['name']?.toString() ?? 'User',
      avatar: json['avatar']?.toString(),
      age: json['age'] ?? 0,
      location: json['location']?.toString(),
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : null,
      isVerified: json['verified'] == true || json['isVerified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (avatar != null) 'avatar': avatar,
        'age': age,
        if (location != null) 'location': location,
        if (interests != null) 'interests': interests,
        'isVerified': isVerified,
      };

  MatchUser copyWith({
    int? id,
    String? name,
    String? avatar,
    int? age,
    String? location,
    List<String>? interests,
    bool? isVerified,
  }) {
    return MatchUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      age: age ?? this.age,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class Match {
  final int id;
  final MatchUser user;
  final DateTime matchedAt;
  final bool isAccepted;
  final bool isRejected;
  final String? lastMessage;

  const Match({
    required this.id,
    required this.user,
    required this.matchedAt,
    this.isAccepted = false,
    this.isRejected = false,
    this.lastMessage,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? 0,
      user: MatchUser.fromJson(json['user'] ?? json['matchedUser'] ?? {}),
      matchedAt: json['matchedAt'] != null
          ? DateTime.parse(json['matchedAt'].toString())
          : DateTime.now(),
      isAccepted: json['isAccepted'] == true,
      isRejected: json['isRejected'] == true,
      lastMessage: json['lastMessage']?.toString(),
    );
  }

  Match copyWith({
    int? id,
    MatchUser? user,
    DateTime? matchedAt,
    bool? isAccepted,
    bool? isRejected,
    String? lastMessage,
  }) {
    return Match(
      id: id ?? this.id,
      user: user ?? this.user,
      matchedAt: matchedAt ?? this.matchedAt,
      isAccepted: isAccepted ?? this.isAccepted,
      isRejected: isRejected ?? this.isRejected,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class Recommendation extends MatchUser {
  final double matchPercentage;
  final List<String> commonInterests;

  const Recommendation({
    required super.id,
    required super.name,
    super.avatar,
    required super.age,
    super.location,
    super.interests,
    super.isVerified,
    required this.matchPercentage,
    required this.commonInterests,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'User',
      avatar: json['avatar']?.toString(),
      age: json['age'] ?? 0,
      location: json['location']?.toString(),
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : null,
      isVerified: json['verified'] == true,
      matchPercentage: (json['matchPercentage'] ?? 0).toDouble(),
      commonInterests: json['commonInterests'] != null
          ? List<String>.from(json['commonInterests'])
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'matchPercentage': matchPercentage,
        'commonInterests': commonInterests,
      };
}

class MatchState extends Equatable {
  // Matches
  final List<Match> matches;
  final MatchStatus matchesStatus;

  // Recommendations
  final List<Recommendation> recommendations;
  final MatchStatus recommendationsStatus;

  // Liking status
  final Set<int> likedUserIds;
  final Set<int> pendingLikeIds;

  // Error
  final String? error;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLiking;

  const MatchState({
    this.matches = const [],
    this.matchesStatus = MatchStatus.initial,
    this.recommendations = const [],
    this.recommendationsStatus = MatchStatus.initial,
    this.likedUserIds = const {},
    this.pendingLikeIds = const {},
    this.error,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLiking = false,
  });

  MatchState copyWith({
    List<Match>? matches,
    MatchStatus? matchesStatus,
    List<Recommendation>? recommendations,
    MatchStatus? recommendationsStatus,
    Set<int>? likedUserIds,
    Set<int>? pendingLikeIds,
    String? error,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLiking,
  }) {
    return MatchState(
      matches: matches ?? this.matches,
      matchesStatus: matchesStatus ?? this.matchesStatus,
      recommendations: recommendations ?? this.recommendations,
      recommendationsStatus:
          recommendationsStatus ?? this.recommendationsStatus,
      likedUserIds: likedUserIds ?? this.likedUserIds,
      pendingLikeIds: pendingLikeIds ?? this.pendingLikeIds,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLiking: isLiking ?? this.isLiking,
    );
  }

  @override
  List<Object?> get props => [
        matches,
        matchesStatus,
        recommendations,
        recommendationsStatus,
        likedUserIds,
        pendingLikeIds,
        error,
        isLoading,
        isRefreshing,
        isLiking,
      ];
}

enum MatchStatus {
  initial,
  loading,
  refreshing,
  success,
  error,
}
