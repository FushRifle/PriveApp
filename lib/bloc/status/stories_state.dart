part of 'stories_bloc.dart';

enum StoriesStatus { initial, loading, loaded, error }

class StoriesState extends Equatable {
  final StoriesStatus status;
  final List<Story> stories;
  final String? error;
  final bool isCreating;

  const StoriesState({
    this.status = StoriesStatus.initial,
    this.stories = const [],
    this.error,
    this.isCreating = false,
  });

  StoriesState copyWith({
    StoriesStatus? status,
    List<Story>? stories,
    String? error,
    bool? isCreating,
  }) {
    return StoriesState(
      status: status ?? this.status,
      stories: stories ?? this.stories,
      error: error ?? this.error,
      isCreating: isCreating ?? this.isCreating,
    );
  }

  @override
  List<Object?> get props => [status, stories, error, isCreating];
}
