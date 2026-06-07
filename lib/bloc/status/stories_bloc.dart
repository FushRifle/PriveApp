import 'package:clique/core/services/status/status_services.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/core/models/status_model.dart';

part 'stories_event.dart';
part 'stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  final StatusService _statusService = StatusService();

  bool _isLoadingStories = false;
  DateTime? _lastStoriesRequest;

  StoriesBloc() : super(const StoriesState()) {
    on<GetStories>(_onGetStories);
    on<CreateStoryEvent>(_onCreateStory);
    on<DeleteStoryEvent>(_onDeleteStory);
    on<MarkStorySeen>(_onMarkStorySeen);
    on<LikeStoryEvent>(_onLikeStory);
    on<UnlikeStoryEvent>(_onUnlikeStory);
    on<ReplyToStoryEvent>(_onReplyToStory);
    on<ReshareStoryEvent>(_onReshareStory);
    on<ClearStoriesError>(_onClearStoriesError);
  }

  void setAuthToken(String token) {
    _statusService.setAuthToken(token);
  }

  void clearAuthToken() {
    _statusService.clearAuthToken();
  }

  Future<void> _onGetStories(
    GetStories event,
    Emitter<StoriesState> emit,
  ) async {
    if (_isLoadingStories) return;

    final now = DateTime.now();
    if (_lastStoriesRequest != null &&
        now.difference(_lastStoriesRequest!) < const Duration(seconds: 2)) {
      return;
    }

    _isLoadingStories = true;
    _lastStoriesRequest = now;

    emit(state.copyWith(status: StoriesStatus.loading, clearError: true));

    try {
      final stories = await _statusService.getStories();
      emit(state.copyWith(
        status: StoriesStatus.loaded,
        stories: stories,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: StoriesStatus.error,
        error: e.toString(),
      ));
    } finally {
      _isLoadingStories = false;
    }
  }

  Future<void> _onCreateStory(
    CreateStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(state.copyWith(
      status: StoriesStatus.loading,
      isCreating: true,
      clearError: true,
    ));

    try {
      await _statusService.createStory(
        content: event.content,
        attachments: event.attachments,
        backgroundColor: event.backgroundColor,
        textAlign: event.textAlign,
        fontSize: event.fontSize,
      );

      emit(state.copyWith(
        status: StoriesStatus.loaded,
        isCreating: false,
        clearError: true,
      ));
      add(GetStories());
    } catch (e) {
      emit(state.copyWith(
        status: StoriesStatus.error,
        isCreating: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteStory(
    DeleteStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    try {
      await _statusService.deleteStory(event.storyId);

      final updatedStories = List<Story>.from(state.stories)
        ..removeWhere((story) => story.id == event.storyId);

      emit(state.copyWith(stories: updatedStories));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onMarkStorySeen(
    MarkStorySeen event,
    Emitter<StoriesState> emit,
  ) async {
    final updatedStories = state.stories.map((story) {
      if (story.id == event.storyId && !story.isSeen) {
        return story.copyWith(isSeen: true);
      }
      return story;
    }).toList();

    emit(state.copyWith(stories: updatedStories));

    try {
      await _statusService.markStoryAsSeen(event.storyId);
    } catch (e) {
      final revertedStories = state.stories.map((story) {
        if (story.id == event.storyId) {
          return story.copyWith(isSeen: false);
        }
        return story;
      }).toList();

      emit(state.copyWith(
        stories: revertedStories,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLikeStory(
    LikeStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    final previousStories = state.stories;
    emit(state.copyWith(
      stories: _updateStory(event.storyId, (story) {
        if (story.isLiked) return story;
        return story.copyWith(
          isLiked: true,
          likeCount: story.likeCount + 1,
        );
      }),
      clearError: true,
    ));

    try {
      await _statusService.likeStory(event.storyId);
    } catch (e) {
      emit(state.copyWith(stories: previousStories, error: e.toString()));
    }
  }

  Future<void> _onUnlikeStory(
    UnlikeStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    final previousStories = state.stories;
    emit(state.copyWith(
      stories: _updateStory(event.storyId, (story) {
        if (!story.isLiked) return story;
        return story.copyWith(
          isLiked: false,
          likeCount: (story.likeCount - 1).clamp(0, 2147483647).toInt(),
        );
      }),
      clearError: true,
    ));

    try {
      await _statusService.unlikeStory(event.storyId);
    } catch (e) {
      emit(state.copyWith(stories: previousStories, error: e.toString()));
    }
  }

  Future<void> _onReplyToStory(
    ReplyToStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    final previousStories = state.stories;
    emit(state.copyWith(
      stories: _updateStory(
        event.storyId,
        (story) => story.copyWith(replyCount: story.replyCount + 1),
      ),
      clearError: true,
    ));

    try {
      await _statusService.replyToStory(
        storyId: event.storyId,
        content: event.content,
      );
    } catch (e) {
      emit(state.copyWith(stories: previousStories, error: e.toString()));
    }
  }

  Future<void> _onReshareStory(
    ReshareStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    final previousStories = state.stories;
    emit(state.copyWith(
      stories: _updateStory(event.storyId, (story) {
        if (story.isReshared) return story;
        return story.copyWith(
          isReshared: true,
          reshareCount: story.reshareCount + 1,
        );
      }),
      clearError: true,
    ));

    try {
      await _statusService.reshareStory(event.storyId);
    } catch (e) {
      emit(state.copyWith(stories: previousStories, error: e.toString()));
    }
  }

  List<Story> _updateStory(String storyId, Story Function(Story story) update) {
    return state.stories.map((story) {
      if (story.id != storyId) return story;
      return update(story);
    }).toList();
  }

  void _onClearStoriesError(
    ClearStoriesError event,
    Emitter<StoriesState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }
}
