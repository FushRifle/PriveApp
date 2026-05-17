part of 'feed_bloc.dart';

enum FeedStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

enum CommentsStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

enum MediaStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

class FeedState extends Equatable {
  // Posts
  final FeedStatus postsStatus;
  final List<FeedPost> posts;
  final bool hasMorePosts;
  final int currentPage;
  final String? postsError;

  // Comments
  final Map<int, CommentsStatus> commentsStatus;
  final Map<int, List<Comment>> comments;
  final Map<int, bool> hasMoreComments;
  final Map<int, int> commentsPage;
  final String? commentsError;

  // User Media
  final MediaStatus mediaStatus;
  final List<UserMedia> media;
  final bool hasMoreMedia;
  final int mediaPage;
  final String? mediaError;

  // General
  final bool isCreatingPost;
  final bool isCreatingComment;
  final String? generalError;

  const FeedState({
    this.postsStatus = FeedStatus.initial,
    this.posts = const [],
    this.hasMorePosts = false,
    this.currentPage = 1,
    this.postsError,
    this.commentsStatus = const {},
    this.comments = const {},
    this.hasMoreComments = const {},
    this.commentsPage = const {},
    this.commentsError,
    this.mediaStatus = MediaStatus.initial,
    this.media = const [],
    this.hasMoreMedia = false,
    this.mediaPage = 1,
    this.mediaError,
    this.isCreatingPost = false,
    this.isCreatingComment = false,
    this.generalError,
  });

  FeedState copyWith({
    FeedStatus? postsStatus,
    List<FeedPost>? posts,
    bool? hasMorePosts,
    int? currentPage,
    String? postsError,
    Map<int, CommentsStatus>? commentsStatus,
    Map<int, List<Comment>>? comments,
    Map<int, bool>? hasMoreComments,
    Map<int, int>? commentsPage,
    String? commentsError,
    MediaStatus? mediaStatus,
    List<UserMedia>? media,
    bool? hasMoreMedia,
    int? mediaPage,
    String? mediaError,
    bool? isCreatingPost,
    bool? isCreatingComment,
    String? generalError,
  }) {
    return FeedState(
      postsStatus: postsStatus ?? this.postsStatus,
      posts: posts ?? this.posts,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      currentPage: currentPage ?? this.currentPage,
      postsError: postsError ?? this.postsError,
      commentsStatus: commentsStatus ?? this.commentsStatus,
      comments: comments ?? this.comments,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      commentsPage: commentsPage ?? this.commentsPage,
      commentsError: commentsError ?? this.commentsError,
      mediaStatus: mediaStatus ?? this.mediaStatus,
      media: media ?? this.media,
      hasMoreMedia: hasMoreMedia ?? this.hasMoreMedia,
      mediaPage: mediaPage ?? this.mediaPage,
      mediaError: mediaError ?? this.mediaError,
      isCreatingPost: isCreatingPost ?? this.isCreatingPost,
      isCreatingComment: isCreatingComment ?? this.isCreatingComment,
      generalError: generalError ?? this.generalError,
    );
  }

  // Helper methods
  bool get hasPosts => posts.isNotEmpty;
  bool get isLoading => postsStatus == FeedStatus.loading;
  bool get isLoadingMore => postsStatus == FeedStatus.loadingMore;
  bool get hasPostsError => postsError != null;

  List<Comment> getCommentsForPost(int postId) {
    return comments[postId] ?? [];
  }

  bool isLoadingComments(int postId) {
    return commentsStatus[postId] == CommentsStatus.loading ||
        commentsStatus[postId] == CommentsStatus.loadingMore;
  }

  bool hasMoreCommentsForPost(int postId) {
    return hasMoreComments[postId] ?? false;
  }

  @override
  List<Object?> get props => [
        postsStatus,
        posts,
        hasMorePosts,
        currentPage,
        postsError,
        commentsStatus,
        comments,
        hasMoreComments,
        commentsPage,
        commentsError,
        mediaStatus,
        media,
        hasMoreMedia,
        mediaPage,
        mediaError,
        isCreatingPost,
        isCreatingComment,
        generalError,
      ];
}
