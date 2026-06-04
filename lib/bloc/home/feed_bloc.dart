import 'package:clique/data/services/home/feed_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/data/models/feeds_models.dart';

part 'feed_event.dart';
part 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedService _feedService = FeedService();

  DateTime? _lastFeedRequest;

  bool _isFetchingPosts = false;
  bool _isFetchingMorePosts = false;
  final Set<int> _fetchingComments = {};
  final Set<String> _fetchingMedia = {};

  bool _disposed = false;

  FeedBloc() : super(const FeedState()) {
    on<GetFeedPosts>(_onGetFeedPosts);
    on<RefreshFeed>(_onRefreshFeed);
    on<LoadMoreFeedPosts>(_onLoadMoreFeedPosts);
    on<CreateFeedPost>(_onCreateFeedPost);
    on<LikeFeedPost>(_onLikeFeedPost);
    on<UnlikeFeedPost>(_onUnlikeFeedPost);
    on<SaveFeedPost>(_onSaveFeedPost);
    on<UnsaveFeedPost>(_onUnsaveFeedPost);
    on<ShareFeedPost>(_onShareFeedPost);
    on<RepostFeedPost>(_onRepostFeedPost);
    on<GetPostComments>(_onGetPostComments);
    on<LoadMoreComments>(_onLoadMoreComments);
    on<CreatePostComment>(_onCreatePostComment);
    on<GetUserMedia>(_onGetUserMedia);
    on<LoadMoreUserMedia>(_onLoadMoreUserMedia);
    on<ClearFeedError>(_onClearFeedError);
    on<ResetFeedState>(_onResetFeedState);
    on<DeleteFeedPost>(_onDeleteFeedPost);
    on<UpdateFeedPost>(_onUpdateFeedPost);
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
    if (_disposed) return;

    if (_isFetchingPosts) return;

    final now = DateTime.now();

    if (_lastFeedRequest != null &&
        now.difference(_lastFeedRequest!) < const Duration(seconds: 2) &&
        !event.refresh) {
      return;
    }

    _isFetchingPosts = true;

    _lastFeedRequest = now;

    try {
      if (event.refresh || state.posts.isEmpty) {
        final cachedResponse = event.page == 1 && state.posts.isEmpty
            ? _feedService.getCachedPosts()
            : null;

        if (cachedResponse != null && cachedResponse.posts.isNotEmpty) {
          emit(
            state.copyWith(
              postsStatus: FeedStatus.loaded,
              posts: cachedResponse.posts,
              hasMorePosts: cachedResponse.hasMore,
              currentPage: cachedResponse.page,
              clearPostsError: true,
            ),
          );
        }

        emit(
          state.copyWith(
            postsStatus: FeedStatus.loading,
            clearPostsError: true,
          ),
        );
      }

      final response = await _feedService.getPosts(
        page: event.page,
        forceRefresh: event.refresh,
      );

      final existingIds = state.posts.map((e) => e.id).toSet();

      final filteredPosts = response.posts.where(
        (post) {
          if (event.page == 1 || event.refresh) {
            return true;
          }

          return !existingIds.contains(post.id);
        },
      ).toList();

      final updatedPosts = event.page == 1 || event.refresh
          ? filteredPosts
          : [
              ...state.posts,
              ...filteredPosts,
            ];

      emit(
        state.copyWith(
          postsStatus: FeedStatus.loaded,
          posts: updatedPosts,
          hasMorePosts: response.hasMore,
          currentPage: event.page,
          clearPostsError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          postsStatus: FeedStatus.error,
          postsError: e.toString(),
        ),
      );
    } finally {
      _isFetchingPosts = false;
    }
  }

  Future<void> _onRefreshFeed(
    RefreshFeed event,
    Emitter<FeedState> emit,
  ) async {
    await _onGetFeedPosts(
      const GetFeedPosts(
        page: 1,
        refresh: true,
      ),
      emit,
    );
  }

  Future<void> _onLoadMoreFeedPosts(
    LoadMoreFeedPosts event,
    Emitter<FeedState> emit,
  ) async {
    if (_disposed) return;

    if (_isFetchingMorePosts) return;

    if (!state.hasMorePosts) return;

    if (state.postsStatus == FeedStatus.loadingMore) {
      return;
    }

    _isFetchingMorePosts = true;

    try {
      emit(
        state.copyWith(
          postsStatus: FeedStatus.loadingMore,
        ),
      );

      final nextPage = state.currentPage + 1;

      final response = await _feedService.getPosts(
        page: nextPage,
      );

      final existingIds = state.posts.map((e) => e.id).toSet();

      final filteredPosts = response.posts
          .where(
            (post) => !existingIds.contains(post.id),
          )
          .toList();

      emit(
        state.copyWith(
          postsStatus: FeedStatus.loaded,
          posts: [
            ...state.posts,
            ...filteredPosts,
          ],
          currentPage: nextPage,
          hasMorePosts: response.hasMore,
          clearPostsError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          postsStatus: FeedStatus.error,
          postsError: e.toString(),
        ),
      );
    } finally {
      _isFetchingMorePosts = false;
    }
  }

  Future<void> _onCreateFeedPost(
    CreateFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    if (state.isCreatingPost) return;

    emit(
      state.copyWith(
        isCreatingPost: true,
        clearGeneralError: true,
      ),
    );

    try {
      await _feedService.createPost(
        content: event.content,
        attachments: event.attachments,
      );

      emit(
        state.copyWith(
          isCreatingPost: false,
        ),
      );

      await _onRefreshFeed(
        RefreshFeed(),
        emit,
      );
    } catch (e) {
      emit(
        state.copyWith(
          isCreatingPost: false,
          generalError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLikeFeedPost(
    LikeFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    final originalPosts = state.posts;

    final updatedPosts = state.posts.map((post) {
      if (post.id == event.postId && !post.isLiked) {
        return post.copyWith(
          isLiked: true,
          likes: post.likes + 1,
        );
      }

      return post;
    }).toList();

    emit(
      state.copyWith(
        posts: updatedPosts,
      ),
    );

    try {
      await _feedService.likePost(
        event.postId,
      );
    } catch (e) {
      emit(
        state.copyWith(
          posts: originalPosts,
          generalError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUnlikeFeedPost(
    UnlikeFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    final originalPosts = state.posts;

    final updatedPosts = state.posts.map((post) {
      if (post.id == event.postId && post.isLiked) {
        return post.copyWith(
          isLiked: false,
          likes: post.likes > 0 ? post.likes - 1 : 0,
        );
      }

      return post;
    }).toList();

    emit(
      state.copyWith(
        posts: updatedPosts,
      ),
    );

    try {
      await _feedService.unlikePost(
        event.postId,
      );
    } catch (e) {
      emit(
        state.copyWith(
          posts: originalPosts,
          generalError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSaveFeedPost(
    SaveFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    final originalPosts = state.posts;

    final updatedPosts = state.posts.map((post) {
      if (post.id == event.postId && !post.isSaved) {
        return post.copyWith(
          isSaved: true,
          saves: post.saves + 1,
        );
      }

      return post;
    }).toList();

    emit(state.copyWith(posts: updatedPosts));

    try {
      await _feedService.savePost(event.postId);
    } catch (e) {
      emit(state.copyWith(posts: originalPosts, generalError: e.toString()));
    }
  }

  Future<void> _onUnsaveFeedPost(
    UnsaveFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    final originalPosts = state.posts;

    final updatedPosts = state.posts.map((post) {
      if (post.id == event.postId && post.isSaved) {
        return post.copyWith(
          isSaved: false,
          saves: post.saves > 0 ? post.saves - 1 : 0,
        );
      }

      return post;
    }).toList();

    emit(state.copyWith(posts: updatedPosts));

    try {
      await _feedService.unsavePost(event.postId);
    } catch (e) {
      emit(state.copyWith(posts: originalPosts, generalError: e.toString()));
    }
  }

  Future<void> _onShareFeedPost(
    ShareFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    final originalPosts = state.posts;
    final updatedPosts = state.posts.map((post) {
      if (post.id == event.postId) {
        return post.copyWith(shares: post.shares + 1);
      }

      return post;
    }).toList();

    emit(state.copyWith(posts: updatedPosts));

    try {
      await _feedService.sharePost(event.postId);
    } catch (e) {
      emit(state.copyWith(posts: originalPosts, generalError: e.toString()));
    }
  }

  Future<void> _onRepostFeedPost(
    RepostFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    final originalPosts = state.posts;
    final updatedPosts = state.posts.map((post) {
      if (post.id == event.postId && !post.isReposted) {
        return post.copyWith(
          isReposted: true,
          reposts: post.reposts + 1,
        );
      }

      return post;
    }).toList();

    emit(state.copyWith(posts: updatedPosts));

    try {
      await _feedService.repost(
        postId: event.postId,
        content: event.content,
      );
    } catch (e) {
      emit(state.copyWith(posts: originalPosts, generalError: e.toString()));
    }
  }

  Future<void> _onGetPostComments(
    GetPostComments event,
    Emitter<FeedState> emit,
  ) async {
    if (_disposed) return;

    if (_fetchingComments.contains(event.postId)) return;

    _fetchingComments.add(event.postId);

    try {
      final updatedStatus = Map<int, CommentsStatus>.from(
        state.commentsStatus,
      );

      updatedStatus[event.postId] =
          event.page == 1 ? CommentsStatus.loading : CommentsStatus.loadingMore;

      emit(
        state.copyWith(
          commentsStatus: updatedStatus,
          clearCommentsError: true,
        ),
      );

      final response = await _feedService.getComments(
        event.postId,
        page: event.page,
        forceRefresh: event.page == 1,
      );

      final existingComments = state.comments[event.postId] ?? [];

      final existingIds = existingComments.map((e) => e.id).toSet();

      final filteredComments = response.comments
          .where(
            (comment) => !existingIds.contains(
              comment.id,
            ),
          )
          .toList();

      final updatedComments = Map<int, List<Comment>>.from(
        state.comments,
      );

      updatedComments[event.postId] = event.page == 1
          ? response.comments
          : [
              ...existingComments,
              ...filteredComments,
            ];

      final updatedHasMore = Map<int, bool>.from(
        state.hasMoreComments,
      );

      updatedHasMore[event.postId] = response.hasMore;

      final updatedPages = Map<int, int>.from(
        state.commentsPage,
      );

      updatedPages[event.postId] = event.page;

      updatedStatus[event.postId] = CommentsStatus.loaded;

      emit(
        state.copyWith(
          comments: updatedComments,
          commentsStatus: updatedStatus,
          hasMoreComments: updatedHasMore,
          commentsPage: updatedPages,
          clearCommentsError: true,
        ),
      );
    } catch (e) {
      final updatedStatus = Map<int, CommentsStatus>.from(
        state.commentsStatus,
      );

      updatedStatus[event.postId] = CommentsStatus.error;

      emit(
        state.copyWith(
          commentsStatus: updatedStatus,
          commentsError: e.toString(),
        ),
      );
    } finally {
      _fetchingComments.remove(event.postId);
    }
  }

  Future<void> _onLoadMoreComments(
    LoadMoreComments event,
    Emitter<FeedState> emit,
  ) async {
    final hasMore = state.hasMoreComments[event.postId] ?? false;

    if (!hasMore) return;

    final currentPage = state.commentsPage[event.postId] ?? 1;

    await _onGetPostComments(
      GetPostComments(
        postId: event.postId,
        page: currentPage + 1,
      ),
      emit,
    );
  }

  Future<void> _onCreatePostComment(
    CreatePostComment event,
    Emitter<FeedState> emit,
  ) async {
    if (state.isCreatingComment) return;

    emit(
      state.copyWith(
        isCreatingComment: true,
        clearGeneralError: true,
      ),
    );

    try {
      final comment = await _feedService.addComment(
        postId: event.postId,
        content: event.content,
      );

      final existingComments = state.comments[event.postId] ?? [];

      final updatedComments = Map<int, List<Comment>>.from(
        state.comments,
      );

      updatedComments[event.postId] = [
        comment,
        ...existingComments,
      ];

      final updatedPosts = state.posts.map((post) {
        if (post.id == event.postId) {
          return post.copyWith(comments: post.comments + 1);
        }

        return post;
      }).toList();

      emit(
        state.copyWith(
          comments: updatedComments,
          posts: updatedPosts,
          isCreatingComment: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isCreatingComment: false,
          generalError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGetUserMedia(
    GetUserMedia event,
    Emitter<FeedState> emit,
  ) async {
    if (_disposed) return;

    final mediaKey = '${event.userId}:${event.type ?? 'all'}';

    if (_fetchingMedia.contains(mediaKey)) return;

    _fetchingMedia.add(mediaKey);

    try {
      emit(
        state.copyWith(
          mediaStatus:
              event.page == 1 ? MediaStatus.loading : MediaStatus.loadingMore,
          clearMediaError: true,
        ),
      );

      final response = await _feedService.getUserMedia(
        userId: event.userId,
        page: event.page,
        type: event.type,
        forceRefresh: event.page == 1,
      );

      final existingIds = state.media.map((e) => e.id).toSet();

      final filteredMedia = response.media
          .where(
            (media) => !existingIds.contains(media.id),
          )
          .toList();

      emit(
        state.copyWith(
          mediaStatus: MediaStatus.loaded,
          media: event.page == 1
              ? response.media
              : [
                  ...state.media,
                  ...filteredMedia,
                ],
          hasMoreMedia: response.hasMore,
          mediaPage: event.page,
          clearMediaError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          mediaStatus: MediaStatus.error,
          mediaError: e.toString(),
        ),
      );
    } finally {
      _fetchingMedia.remove(mediaKey);
    }
  }

  Future<void> _onLoadMoreUserMedia(
    LoadMoreUserMedia event,
    Emitter<FeedState> emit,
  ) async {
    if (!state.hasMoreMedia) return;

    await _onGetUserMedia(
      GetUserMedia(
        userId: event.userId,
        page: state.mediaPage + 1,
        type: event.type,
      ),
      emit,
    );
  }

  void _onClearFeedError(
    ClearFeedError event,
    Emitter<FeedState> emit,
  ) {
    emit(
      state.copyWith(
        clearPostsError: true,
        clearCommentsError: true,
        clearMediaError: true,
        clearGeneralError: true,
      ),
    );
  }

  void _onResetFeedState(
    ResetFeedState event,
    Emitter<FeedState> emit,
  ) {
    emit(
      const FeedState(),
    );
  }

  Future<void> _onDeleteFeedPost(
    DeleteFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    final originalPosts = state.posts;

    final updatedPosts = List<FeedPost>.from(state.posts)
      ..removeWhere(
        (post) => post.id == event.postId,
      );

    emit(
      state.copyWith(
        posts: updatedPosts,
      ),
    );

    try {
      await _feedService.deletePost(
        event.postId,
      );
    } catch (e) {
      emit(
        state.copyWith(
          posts: originalPosts,
          generalError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateFeedPost(
    UpdateFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    final originalPosts = state.posts;

    final updatedPosts = state.posts.map((post) {
      if (post.id != event.postId) return post;

      return post.copyWith(content: event.content);
    }).toList();

    emit(
      state.copyWith(
        posts: updatedPosts,
        clearGeneralError: true,
      ),
    );

    try {
      final updatedPost = await _feedService.updatePost(
        postId: event.postId,
        content: event.content,
      );

      emit(
        state.copyWith(
          posts: state.posts.map((post) {
            return post.id == event.postId ? updatedPost : post;
          }).toList(),
          clearGeneralError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          posts: originalPosts,
          generalError: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _disposed = true;

    return super.close();
  }
}
