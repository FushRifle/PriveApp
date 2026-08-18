part of 'reel_bloc.dart';

abstract class ReelEvent extends Equatable {
  const ReelEvent();

  @override
  List<Object?> get props => [];
}

class LoadReels extends ReelEvent {
  final int page;

  const LoadReels({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class RefreshReels extends ReelEvent {}

class LoadMoreReels extends ReelEvent {}

class CreateReel extends ReelEvent {
  final Map<String, dynamic> data;

  const CreateReel({required this.data});

  @override
  List<Object?> get props => [data];
}

class DeleteReel extends ReelEvent {
  final String reelId;
  final Completer<void>? completer;

  const DeleteReel({
    required this.reelId,
    this.completer,
  });

  @override
  List<Object?> get props => [reelId];
}

class LikeReel extends ReelEvent {
  final String reelId;
  final int index;
  final String reaction;

  const LikeReel({
    required this.reelId,
    required this.index,
    this.reaction = 'Like',
  });

  @override
  List<Object?> get props => [reelId, index, reaction];
}

class UnlikeReel extends ReelEvent {
  final String reelId;
  final int index;

  const UnlikeReel({required this.reelId, required this.index});

  @override
  List<Object?> get props => [reelId, index];
}

class ShareReel extends ReelEvent {
  final String reelId;
  final int index;

  const ShareReel({required this.reelId, required this.index});

  @override
  List<Object?> get props => [reelId, index];
}

class RepostReel extends ReelEvent {
  final String reelId;
  final int index;
  final String content;

  const RepostReel({
    required this.reelId,
    required this.index,
    this.content = '',
  });

  @override
  List<Object?> get props => [reelId, index, content];
}

class IncrementReelCommentCount extends ReelEvent {
  final String reelId;
  final int index;

  const IncrementReelCommentCount({
    required this.reelId,
    required this.index,
  });

  @override
  List<Object?> get props => [reelId, index];
}

class ClearReelError extends ReelEvent {}

class ResetReelState extends ReelEvent {}
