part of 'stories_bloc.dart';

enum StoriesStatus { initial, loading, loaded, error }

class StoriesState extends Equatable {
  final StoriesStatus status;
  final List<Story> stories;
  final String? error;
  final bool isCreating;
  final Map<String, dynamic>? lastReply;

  const StoriesState({
    this.status = StoriesStatus.initial,
    this.stories = const [],
    this.error,
    this.isCreating = false,
    this.lastReply,
  });

  StoriesState copyWith({
    StoriesStatus? status,
    List<Story>? stories,
    String? error,
    bool? isCreating,
    Map<String, dynamic>? lastReply,
    bool clearError = false,
    bool clearLastReply = false,
  }) {
    return StoriesState(
      status: status ?? this.status,
      stories: stories ?? this.stories,
      error: clearError ? null : error ?? this.error,
      isCreating: isCreating ?? this.isCreating,
      lastReply: clearLastReply ? null : lastReply ?? this.lastReply,
    );
  }

  @override
  List<Object?> get props => [status, stories, error, isCreating, lastReply];
}
