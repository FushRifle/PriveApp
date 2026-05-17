part of 'stories_bloc.dart';

abstract class StoriesEvent extends Equatable {
  const StoriesEvent();

  @override
  List<Object?> get props => [];
}

class GetStories extends StoriesEvent {}

class CreateStoryEvent extends StoriesEvent {
  final String content;
  final List<Attachment>? attachments;
  final String? backgroundColor;
  final String? textAlign;
  final double? fontSize;

  const CreateStoryEvent({
    required this.content,
    this.attachments,
    this.backgroundColor,
    this.textAlign,
    this.fontSize,
  });

  @override
  List<Object?> get props =>
      [content, attachments, backgroundColor, textAlign, fontSize];
}

class DeleteStoryEvent extends StoriesEvent {
  final String storyId;

  const DeleteStoryEvent({required this.storyId});

  @override
  List<Object?> get props => [storyId];
}

class MarkStorySeen extends StoriesEvent {
  final String storyId;

  const MarkStorySeen({required this.storyId});

  @override
  List<Object?> get props => [storyId];
}

class ClearStoriesError extends StoriesEvent {}
