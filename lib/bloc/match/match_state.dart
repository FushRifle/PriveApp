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
    return MatchUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['username'] ?? 'User',
      username: json['username'] ?? '',
      avatar: json['avatar'],
      age: json['age'] ?? 0,
      location: json['location'],
      bio: json['bio'],
      isVerified: json['verified'] == true,
      isMutual: json['isMutual'] == true,
    );
  }
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
