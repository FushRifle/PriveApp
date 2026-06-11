part of 'feed_bloc.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

// Load feed posts
class GetFeedPosts extends FeedEvent {
  final int page;
  final bool refresh;
  final bool silent;

  const GetFeedPosts({
    this.page = 1,
    this.refresh = false,
    this.silent = false,
  });

  @override
  List<Object?> get props => [page, refresh, silent];
}

// Refresh feed
class RefreshFeed extends FeedEvent {}

class SilentRefreshFeed extends FeedEvent {}

// Load more posts (pagination)
class LoadMoreFeedPosts extends FeedEvent {}

// Create a post
class CreateFeedPost extends FeedEvent {
  final String content;
  final List<Map<String, dynamic>>? attachments;
  final String postType;
  final bool isAnonymous;
  final String? anonymousCategory;
  final List<String>? pollOptions;
  final int? pollExpirationHours;

  const CreateFeedPost({
    required this.content,
    this.attachments,
    this.postType = 'standard',
    this.isAnonymous = false,
    this.anonymousCategory,
    this.pollOptions,
    this.pollExpirationHours,
  });

  @override
  List<Object?> get props =>
      [
        content,
        attachments,
        postType,
        isAnonymous,
        anonymousCategory,
        pollOptions,
        pollExpirationHours,
      ];
}

// Like a post
class LikeFeedPost extends FeedEvent {
  final int postId;

  const LikeFeedPost({required this.postId});

  @override
  List<Object?> get props => [postId];
}

// Unlike a post
class UnlikeFeedPost extends FeedEvent {
  final int postId;

  const UnlikeFeedPost({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class SaveFeedPost extends FeedEvent {
  final int postId;

  const SaveFeedPost({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class UnsaveFeedPost extends FeedEvent {
  final int postId;

  const UnsaveFeedPost({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class ShareFeedPost extends FeedEvent {
  final int postId;

  const ShareFeedPost({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class RepostFeedPost extends FeedEvent {
  final int postId;
  final String content;

  const RepostFeedPost({
    required this.postId,
    this.content = '',
  });

  @override
  List<Object?> get props => [postId, content];
}

// Load comments for a post
class GetPostComments extends FeedEvent {
  final int postId;
  final int page;

  const GetPostComments({required this.postId, this.page = 1});

  @override
  List<Object?> get props => [postId, page];
}

// Load more comments
class LoadMoreComments extends FeedEvent {
  final int postId;

  const LoadMoreComments({required this.postId});

  @override
  List<Object?> get props => [postId];
}

// Create a comment
class CreatePostComment extends FeedEvent {
  final int postId;
  final String content;
  final int? replyToCommentId;

  const CreatePostComment({
    required this.postId,
    required this.content,
    this.replyToCommentId,
  });

  @override
  List<Object?> get props => [postId, content, replyToCommentId];
}

class LikePostComment extends FeedEvent {
  final int postId;
  final int commentId;

  const LikePostComment({
    required this.postId,
    required this.commentId,
  });

  @override
  List<Object?> get props => [postId, commentId];
}

class DislikePostComment extends FeedEvent {
  final int postId;
  final int commentId;

  const DislikePostComment({
    required this.postId,
    required this.commentId,
  });

  @override
  List<Object?> get props => [postId, commentId];
}

// Get user media (gallery)
class GetUserMedia extends FeedEvent {
  final int userId;
  final int page;
  final String? type;

  const GetUserMedia({
    required this.userId,
    this.page = 1,
    this.type,
  });

  @override
  List<Object?> get props => [userId, page, type];
}

// Load more user media
class LoadMoreUserMedia extends FeedEvent {
  final int userId;
  final String? type;

  const LoadMoreUserMedia({required this.userId, this.type});

  @override
  List<Object?> get props => [userId, type];
}

class DeleteFeedPost extends FeedEvent {
  final int postId;

  const DeleteFeedPost({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class UpdateFeedPost extends FeedEvent {
  final int postId;
  final String content;

  const UpdateFeedPost({
    required this.postId,
    required this.content,
  });

  @override
  List<Object?> get props => [postId, content];
}

// Clear errors
class ClearFeedError extends FeedEvent {}

// Reset feed state
class ResetFeedState extends FeedEvent {}
