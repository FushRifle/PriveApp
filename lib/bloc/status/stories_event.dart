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

class LikeStoryEvent extends StoriesEvent {
  final String storyId;

  const LikeStoryEvent({required this.storyId});

  @override
  List<Object?> get props => [storyId];
}

class UnlikeStoryEvent extends StoriesEvent {
  final String storyId;

  const UnlikeStoryEvent({required this.storyId});

  @override
  List<Object?> get props => [storyId];
}

class ReplyToStoryEvent extends StoriesEvent {
  final String storyId;
  final String content;

  const ReplyToStoryEvent({
    required this.storyId,
    required this.content,
  });

  @override
  List<Object?> get props => [storyId, content];
}

class ReshareStoryEvent extends StoriesEvent {
  final String storyId;

  const ReshareStoryEvent({required this.storyId});

  @override
  List<Object?> get props => [storyId];
}

class ClearStoriesError extends StoriesEvent {}
