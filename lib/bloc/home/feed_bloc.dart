import 'package:cirqle/data/services/home/feed_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cirqle/data/models/feeds_models.dart';

part 'feed_event.dart';
part 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedService _feedService = FeedService();

  FeedBloc() : super(const FeedState()) {
    on<GetFeedPosts>(_onGetFeedPosts);
    on<RefreshFeed>(_onRefreshFeed);
    on<LoadMoreFeedPosts>(_onLoadMoreFeedPosts);
    on<CreateFeedPost>(_onCreateFeedPost);
    on<LikeFeedPost>(_onLikeFeedPost);
    on<UnlikeFeedPost>(_onUnlikeFeedPost);
    on<GetPostComments>(_onGetPostComments);
    on<LoadMoreComments>(_onLoadMoreComments);
    on<CreatePostComment>(_onCreatePostComment);
    on<GetUserMedia>(_onGetUserMedia);
    on<LoadMoreUserMedia>(_onLoadMoreUserMedia);
    on<ClearFeedError>(_onClearFeedError);
    on<ResetFeedState>(_onResetFeedState);
    on<DeleteFeedPost>(_onDeleteFeedPost);
  }

  void setAuthToken(String token) {
    _feedService.setAuthToken(token);
  }

  void clearAuthToken() {
    _feedService.clearAuthToken();
  }

  Future<void> _onGetFeedPosts(
    GetFeedPosts event,
    Emitter<FeedState> emit,
  ) async {
    if (event.refresh) {
      emit(state.copyWith(
        postsStatus: FeedStatus.loading,
        currentPage: 1,
        postsError: null,
      ));
    } else if (state.posts.isEmpty) {
      emit(state.copyWith(
        postsStatus: FeedStatus.loading,
        postsError: null,
      ));
    }

    try {
      final response = await _feedService.getPosts(page: event.page);

      final newPosts = event.refresh || event.page == 1
          ? response.posts
          : [...state.posts, ...response.posts];

      emit(state.copyWith(
        postsStatus: FeedStatus.loaded,
        posts: newPosts,
        hasMorePosts: response.hasMore,
        currentPage: event.page,
        postsError: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        postsStatus: FeedStatus.error,
        postsError: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshFeed(
    RefreshFeed event,
    Emitter<FeedState> emit,
  ) async {
    add(GetFeedPosts(page: 1, refresh: true));
  }

  Future<void> _onLoadMoreFeedPosts(
    LoadMoreFeedPosts event,
    Emitter<FeedState> emit,
  ) async {
    if (!state.hasMorePosts || state.isLoadingMore) return;

    emit(state.copyWith(postsStatus: FeedStatus.loadingMore));

    final nextPage = state.currentPage + 1;
    add(GetFeedPosts(page: nextPage));
  }

  Future<void> _onCreateFeedPost(
    CreateFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.copyWith(isCreatingPost: true, generalError: null));

    try {
      await _feedService.createPost(
        content: event.content,
        attachments: event.attachments,
      );

      emit(state.copyWith(isCreatingPost: false));
      add(RefreshFeed());
    } catch (e) {
      emit(state.copyWith(
        isCreatingPost: false,
        generalError: e.toString(),
      ));
    }
  }

  Future<void> _onLikeFeedPost(
    LikeFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    // Optimistic update
    final updatedPosts = state.posts.map((post) {
      if (post.id == event.postId && !post.isLiked) {
        return post.copyWith(isLiked: true, likes: post.likes + 1);
      }
      return post;
    }).toList();

    emit(state.copyWith(posts: updatedPosts));

    try {
      await _feedService.likePost(event.postId);
    } catch (e) {
      // Revert on error
      final revertedPosts = state.posts.map((post) {
        if (post.id == event.postId && post.isLiked) {
          return post.copyWith(isLiked: false, likes: post.likes - 1);
        }
        return post;
      }).toList();
      emit(state.copyWith(posts: revertedPosts, generalError: e.toString()));
    }
  }

  Future<void> _onUnlikeFeedPost(
    UnlikeFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    // Optimistic update
    final updatedPosts = state.posts.map((post) {
      if (post.id == event.postId && post.isLiked) {
        return post.copyWith(isLiked: false, likes: post.likes - 1);
      }
      return post;
    }).toList();

    emit(state.copyWith(posts: updatedPosts));

    try {
      await _feedService.unlikePost(event.postId);
    } catch (e) {
      // Revert on error
      final revertedPosts = state.posts.map((post) {
        if (post.id == event.postId && !post.isLiked) {
          return post.copyWith(isLiked: true, likes: post.likes + 1);
        }
        return post;
      }).toList();
      emit(state.copyWith(posts: revertedPosts, generalError: e.toString()));
    }
  }

  Future<void> _onGetPostComments(
    GetPostComments event,
    Emitter<FeedState> emit,
  ) async {
    final isFirstPage = event.page == 1;

    final updatedStatus = Map<int, CommentsStatus>.from(state.commentsStatus);
    updatedStatus[event.postId] = CommentsStatus.loading;

    emit(state.copyWith(
      commentsStatus: updatedStatus,
      commentsError: null,
    ));

    try {
      final response =
          await _feedService.getComments(event.postId, page: event.page);

      final existingComments = state.comments[event.postId] ?? [];
      final newComments = isFirstPage
          ? response.comments
          : [...existingComments, ...response.comments];

      final updatedComments = Map<int, List<Comment>>.from(state.comments);
      updatedComments[event.postId] = newComments;

      final updatedHasMore = Map<int, bool>.from(state.hasMoreComments);
      updatedHasMore[event.postId] = response.hasMore;

      final updatedPage = Map<int, int>.from(state.commentsPage);
      updatedPage[event.postId] = event.page;

      final updatedStatusDone =
          Map<int, CommentsStatus>.from(state.commentsStatus);
      updatedStatusDone[event.postId] = CommentsStatus.loaded;

      emit(state.copyWith(
        comments: updatedComments,
        commentsStatus: updatedStatusDone,
        hasMoreComments: updatedHasMore,
        commentsPage: updatedPage,
      ));
    } catch (e) {
      final updatedStatusError =
          Map<int, CommentsStatus>.from(state.commentsStatus);
      updatedStatusError[event.postId] = CommentsStatus.error;

      emit(state.copyWith(
        commentsStatus: updatedStatusError,
        commentsError: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreComments(
    LoadMoreComments event,
    Emitter<FeedState> emit,
  ) async {
    final currentStatus = state.commentsStatus[event.postId];
    final hasMore = state.hasMoreComments[event.postId] ?? false;
    final currentPage = state.commentsPage[event.postId] ?? 1;

    if (currentStatus == CommentsStatus.loadingMore || !hasMore) return;

    final updatedStatus = Map<int, CommentsStatus>.from(state.commentsStatus);
    updatedStatus[event.postId] = CommentsStatus.loadingMore;

    emit(state.copyWith(commentsStatus: updatedStatus));

    add(GetPostComments(postId: event.postId, page: currentPage + 1));
  }

  Future<void> _onCreatePostComment(
    CreatePostComment event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.copyWith(isCreatingComment: true, generalError: null));

    try {
      final newComment = await _feedService.addComment(
        postId: event.postId,
        content: event.content,
      );

      final existingComments = state.comments[event.postId] ?? [];
      final updatedComments = Map<int, List<Comment>>.from(state.comments);
      updatedComments[event.postId] = [newComment, ...existingComments];

      emit(state.copyWith(
        comments: updatedComments,
        isCreatingComment: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isCreatingComment: false,
        generalError: e.toString(),
      ));
    }
  }

  Future<void> _onGetUserMedia(
    GetUserMedia event,
    Emitter<FeedState> emit,
  ) async {
    if (event.page == 1) {
      emit(state.copyWith(
        mediaStatus: MediaStatus.loading,
        mediaError: null,
      ));
    }

    try {
      final response = await _feedService.getUserMedia(
        userId: event.userId,
        page: event.page,
        type: event.type,
      );

      final newMedia = event.page == 1
          ? response.media
          : [...state.media, ...response.media];

      emit(state.copyWith(
        mediaStatus: MediaStatus.loaded,
        media: newMedia,
        hasMoreMedia: response.hasMore,
        mediaPage: event.page,
        mediaError: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        mediaStatus: MediaStatus.error,
        mediaError: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreUserMedia(
    LoadMoreUserMedia event,
    Emitter<FeedState> emit,
  ) async {
    if (!state.hasMoreMedia || state.mediaStatus == MediaStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(mediaStatus: MediaStatus.loadingMore));

    add(GetUserMedia(
      userId: event.userId,
      page: state.mediaPage + 1,
      type: event.type,
    ));
  }

  void _onClearFeedError(
    ClearFeedError event,
    Emitter<FeedState> emit,
  ) {
    emit(state.copyWith(
      postsError: null,
      commentsError: null,
      mediaError: null,
      generalError: null,
    ));
  }

  void _onResetFeedState(
    ResetFeedState event,
    Emitter<FeedState> emit,
  ) {
    emit(const FeedState());
  }

  Future<void> _onDeleteFeedPost(
    DeleteFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _feedService.deletePost(event.postId);

      // Remove post from state
      final updatedPosts = List<FeedPost>.from(state.posts)
        ..removeWhere((post) => post.id == event.postId);

      emit(state.copyWith(
        posts: updatedPosts,
        hasMorePosts: updatedPosts.length >= 10,
      ));
    } catch (e) {
      emit(state.copyWith(generalError: e.toString()));
    }
  }
}
