import 'package:clique/data/services/status/status_services.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/data/models/status_model.dart';

part 'stories_event.dart';
part 'stories_state.dart';

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  final StatusService _statusService = StatusService();

  StoriesBloc() : super(const StoriesState()) {
    on<GetStories>(_onGetStories);
    on<CreateStoryEvent>(_onCreateStory);
    on<DeleteStoryEvent>(_onDeleteStory);
    on<MarkStorySeen>(_onMarkStorySeen);
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
    }
  }

  Future<void> _onCreateStory(
    CreateStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, clearError: true));

    try {
      await _statusService.createStory(
        content: event.content,
        attachments: event.attachments,
        backgroundColor: event.backgroundColor,
        textAlign: event.textAlign,
        fontSize: event.fontSize,
      );

      emit(state.copyWith(isCreating: false));
      add(GetStories());
    } catch (e) {
      emit(state.copyWith(
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

  void _onClearStoriesError(
    ClearStoriesError event,
    Emitter<StoriesState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }
}
