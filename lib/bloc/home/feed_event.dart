part of 'feed_bloc.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

class FetchFeedData extends FeedEvent {}

class RefreshFeed extends FeedEvent {}

class LoadMorePosts extends FeedEvent {}

class FetchStories extends FeedEvent {}

class MarkStoryAsSeen extends FeedEvent {
  final String storyId;

  const MarkStoryAsSeen(this.storyId);

  @override
  List<Object?> get props => [storyId];
}

class LikePost extends FeedEvent {
  final int postId;

  const LikePost(this.postId);

  @override
  List<Object?> get props => [postId];
}

class UnlikePost extends FeedEvent {
  final int postId;

  const UnlikePost(this.postId);

  @override
  List<Object?> get props => [postId];
}

class CreatePost extends FeedEvent {
  final String content;
  final String? imageUrl;

  const CreatePost({
    required this.content,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [content, imageUrl];
}

class CreateStory extends FeedEvent {
  final String? text;
  final String? imageUrl;
  final String? videoUrl;
  final String? backgroundColor;
  final String? textAlign;
  final double? fontSize;

  const CreateStory({
    this.text,
    this.imageUrl,
    this.videoUrl,
    this.backgroundColor,
    this.textAlign,
    this.fontSize,
  });

  @override
  List<Object?> get props => [
        text,
        imageUrl,
        videoUrl,
        backgroundColor,
        textAlign,
        fontSize,
      ];
}
