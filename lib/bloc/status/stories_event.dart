part of 'stories_bloc.dart';

abstract class StoriesEvent extends Equatable {
  const StoriesEvent();

  @override
  List<Object?> get props => [];
}

class GetStories extends StoriesEvent {
  final bool refresh;
  final bool silent;

  const GetStories({
    this.refresh = false,
    this.silent = false,
  });

  @override
  List<Object?> get props => [refresh, silent];
}

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

class UpdateStoryEvent extends StoriesEvent {
  final String storyId;
  final String content;
  final List<Attachment>? attachments;
  final String? backgroundColor;
  final String? textAlign;
  final double? fontSize;

  const UpdateStoryEvent({
    required this.storyId,
    required this.content,
    this.attachments,
    this.backgroundColor,
    this.textAlign,
    this.fontSize,
  });

  @override
  List<Object?> get props =>
      [storyId, content, attachments, backgroundColor, textAlign, fontSize];
}

class DeleteStoryEvent extends StoriesEvent {
  final String storyId;
  final Completer<void>? completer;

  const DeleteStoryEvent({
    required this.storyId,
    this.completer,
  });

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
  final String reaction;

  const LikeStoryEvent({
    required this.storyId,
    this.reaction = 'Like',
  });

  @override
  List<Object?> get props => [storyId, reaction];
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
  final int? receiverId;

  const ReplyToStoryEvent({
    required this.storyId,
    required this.content,
    this.receiverId,
  });

  @override
  List<Object?> get props => [storyId, content, receiverId];
}

class ReshareStoryEvent extends StoriesEvent {
  final String storyId;

  const ReshareStoryEvent({required this.storyId});

  @override
  List<Object?> get props => [storyId];
}

class ClearStoriesError extends StoriesEvent {}
