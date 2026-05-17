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

  const GetFeedPosts({this.page = 1, this.refresh = false});

  @override
  List<Object?> get props => [page, refresh];
}

// Refresh feed
class RefreshFeed extends FeedEvent {}

// Load more posts (pagination)
class LoadMoreFeedPosts extends FeedEvent {}

// Create a post
class CreateFeedPost extends FeedEvent {
  final String content;
  final List<Map<String, dynamic>>? attachments;

  const CreateFeedPost({
    required this.content,
    this.attachments,
  });

  @override
  List<Object?> get props => [content, attachments];
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

  const CreatePostComment({required this.postId, required this.content});

  @override
  List<Object?> get props => [postId, content];
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

// Clear errors
class ClearFeedError extends FeedEvent {}

// Reset feed state
class ResetFeedState extends FeedEvent {}
