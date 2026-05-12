// lib/ui/bloc/home/feed_state.dart
part of 'feed_bloc.dart';

class FeedState extends Equatable {
  final List<Map<String, dynamic>> posts;
  final List<Map<String, dynamic>> stories;
  final Map<String, dynamic> user;
  final FeedStatus status;
  final FeedStatus storiesStatus;
  final bool hasMore;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.stories = const [],
    this.user = const {},
    this.status = FeedStatus.initial,
    this.storiesStatus = FeedStatus.initial,
    this.hasMore = true,
    this.error,
  });

  FeedState copyWith({
    List<Map<String, dynamic>>? posts,
    List<Map<String, dynamic>>? stories,
    Map<String, dynamic>? user,
    FeedStatus? status,
    FeedStatus? storiesStatus,
    bool? hasMore,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      stories: stories ?? this.stories,
      user: user ?? this.user,
      status: status ?? this.status,
      storiesStatus: storiesStatus ?? this.storiesStatus,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        posts,
        stories,
        user,
        status,
        storiesStatus,
        hasMore,
        error,
      ];
}

enum FeedStatus {
  initial,
  loading,
  loadingMore,
  success,
  failure,
}
