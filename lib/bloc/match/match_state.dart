part of 'match_bloc.dart';

enum MatchStatus { initial, loading, success, error }

class MatchUser {
  final int id;
  final String name;
  final String username;
  final String? avatar;
  final int age;
  final String? location;
  final String? bio;
  final bool isVerified;
  final bool isMutual;

  const MatchUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    required this.age,
    this.location,
    this.bio,
    this.isVerified = false,
    this.isMutual = false,
  });

  factory MatchUser.fromJson(Map<String, dynamic> json) {
    final user = _readMap(json['user'] ?? json['profile']);

    return MatchUser(
      id: _readInt(
          json['userId'] ?? json['user_id'] ?? user['id'] ?? json['id']),
      name:
          (user['name'] ?? json['name'] ?? user['username'] ?? json['username'])
                  ?.toString() ??
              'User',
      username: (user['username'] ?? json['username'])?.toString() ?? '',
      avatar: (user['avatar'] ?? json['avatar'])?.toString(),
      age: _readInt(user['age'] ?? json['age']),
      location: (user['location'] ?? json['location'])?.toString(),
      bio: (user['bio'] ?? json['bio'])?.toString(),
      isVerified: user['verified'] == true || json['verified'] == true,
      isMutual: json['isMutual'] == true,
    );
  }
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class MatchState extends Equatable {
  final MatchStatus status;
  final List<MatchUser> matches;
  final List<MatchUser> recommendations;
  final bool isLoading;
  final bool isLiking;
  final String? error;

  const MatchState({
    this.status = MatchStatus.initial,
    this.matches = const [],
    this.recommendations = const [],
    this.isLoading = false,
    this.isLiking = false,
    this.error,
  });

  MatchState copyWith({
    MatchStatus? status,
    List<MatchUser>? matches,
    List<MatchUser>? recommendations,
    bool? isLoading,
    bool? isLiking,
    String? error,
    bool clearError = false,
  }) {
    return MatchState(
      status: status ?? this.status,
      matches: matches ?? this.matches,
      recommendations: recommendations ?? this.recommendations,
      isLoading: isLoading ?? this.isLoading,
      isLiking: isLiking ?? this.isLiking,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props =>
      [status, matches, recommendations, isLoading, isLiking, error];
}
