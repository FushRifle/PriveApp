import 'dart:async';

import 'package:clique/core/services/home/feed_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/core/models/feeds_models.dart';

part 'feed_event.dart';
part 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedService _feedService;

  bool _isFetchingPosts = false;
  bool _isFetchingMorePosts = false;
  final Set<int> _prefetchingPages = {};
  final Set<int> _fetchingComments = {};
  final Set<int> _creatingComments = {};
  final Set<String> _updatingCommentReactions = {};
  final Set<String> _fetchingMedia = {};

  bool _disposed = false;

  FeedBloc({FeedService? feedService})
      : _feedService = feedService ?? FeedService(),
        super(const FeedState()) {
    on<GetFeedPosts>(_onGetFeedPosts);
    on<RefreshFeed>(_onRefreshFeed);
    on<SilentRefreshFeed>(_onSilentRefreshFeed);
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
    on<LikePostComment>(_onLikePostComment);
    on<DislikePostComment>(_onDislikePostComment);
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

    if (_isFetchingPosts || _isFetchingMorePosts) return;

    _isFetchingPosts = true;

    try {
      final cachedResponse =
          event.page == 1 && state.posts.isEmpty && !event.refresh
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
      } else if (!event.silent && state.posts.isEmpty) {
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

      final updatedPosts = event.page == 1 || event.refresh
          ? _mergePosts(response.posts, state.posts)
          : [
              ...state.posts,
              ..._dedupePosts(response.posts, state.posts),
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

      if (response.hasMore) {
        _prefetchFeedPage(response.page + 1);
      }
    } catch (e) {
      if (event.silent && state.posts.isNotEmpty) {
        return;
      }

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
    _prefetchingPages.clear();
    await _onGetFeedPosts(
      const GetFeedPosts(
        page: 1,
        refresh: true,
      ),
      emit,
    );
  }

  Future<void> _onSilentRefreshFeed(
    SilentRefreshFeed event,
    Emitter<FeedState> emit,
  ) async {
    _prefetchingPages.clear();
    await _onGetFeedPosts(
      const GetFeedPosts(
        page: 1,
        refresh: true,
        silent: true,
      ),
      emit,
    );
  }

  Future<void> _onLoadMoreFeedPosts(
    LoadMoreFeedPosts event,
    Emitter<FeedState> emit,
  ) async {
    if (_disposed) return;

    if (_isFetchingMorePosts || _isFetchingPosts) return;

    if (!state.hasMorePosts) return;

    _isFetchingMorePosts = true;

    try {
      final nextPage = state.currentPage + 1;

      final response = await _feedService.getPosts(
        page: nextPage,
      );

      emit(
        state.copyWith(
          postsStatus: FeedStatus.loaded,
          posts: [
            ...state.posts,
            ..._dedupePosts(response.posts, state.posts),
          ],
          currentPage: nextPage,
          hasMorePosts: response.hasMore,
          clearPostsError: true,
        ),
      );

      if (response.hasMore) {
        _prefetchFeedPage(response.page + 1);
      }
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
      final createdPost = await _feedService.createPost(
        content: event.content,
        attachments: event.attachments,
        postType: event.postType,
        isAnonymous: event.isAnonymous,
        anonymousCategory: event.anonymousCategory,
        pollOptions: event.pollOptions,
        pollExpirationHours: event.pollExpirationHours,
      );

      emit(
        state.copyWith(
          isCreatingPost: false,
          posts: [
            createdPost,
            ...state.posts.where((post) => post.id != createdPost.id),
          ],
          postsStatus:
              state.posts.isEmpty ? FeedStatus.loaded : state.postsStatus,
        ),
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
      await _cachePosts(state.posts);
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
      await _cachePosts(state.posts);
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

    emit(
      state.copyWith(
        posts: updatedPosts,
        isReposting: true,
        clearGeneralError: true,
      ),
    );

    try {
      await _feedService.savePost(event.postId);
      await _cachePosts(updatedPosts);
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
      await _cachePosts(updatedPosts);
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
      await _cachePosts(updatedPosts);
    } catch (e) {
      emit(state.copyWith(posts: originalPosts, generalError: e.toString()));
    }
  }

  Future<void> _onRepostFeedPost(
    RepostFeedPost event,
    Emitter<FeedState> emit,
  ) async {
    final originalPosts = state.posts;
    final sourcePost = state.posts.cast<FeedPost?>().firstWhere(
          (post) => post?.id == event.postId,
          orElse: () => null,
        );

    if (sourcePost == null) return;

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
      final repostedPost = await _feedService.repost(
        postId: event.postId,
        content: event.content,
        postType: event.postType,
        isAnonymous: event.isAnonymous,
        anonymousCategory: event.anonymousCategory,
        pollOptions: event.pollOptions,
        pollExpirationHours: event.pollExpirationHours,
      );

      emit(
        state.copyWith(
          posts: [
            repostedPost,
            ...state.posts.where((post) => post.id != repostedPost.id),
          ],
          isReposting: false,
          clearGeneralError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          posts: originalPosts,
          generalError: e.toString(),
          isReposting: false,
        ),
      );
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

  void _prefetchFeedPage(int page) {
    if (_disposed || page <= 1 || _prefetchingPages.contains(page)) return;

    _prefetchingPages.add(page);

    unawaited(
      () async {
        try {
          await _feedService.getPosts(page: page);
        } catch (_) {
          // Background prefetch should never surface errors to the UI.
        } finally {
          _prefetchingPages.remove(page);
        }
      }(),
    );
  }

  List<FeedPost> _dedupePosts(
    List<FeedPost> incoming,
    List<FeedPost> existing,
  ) {
    if (incoming.isEmpty) return const [];

    final existingIds = existing.map((post) => post.id).toSet();
    return incoming.where((post) => existingIds.add(post.id)).toList();
  }

  List<FeedPost> _mergePosts(
    List<FeedPost> primary,
    List<FeedPost> secondary,
  ) {
    final combined = <FeedPost>[
      ...primary,
      ...secondary.where(
        (post) => !primary.any((candidate) => candidate.id == post.id),
      ),
    ];

    combined.sort(
      (a, b) {
        final byDate = b.createdAt.compareTo(a.createdAt);
        if (byDate != 0) return byDate;
        return b.id.compareTo(a.id);
      },
    );

    return combined;
  }

  Future<void> _onCreatePostComment(
    CreatePostComment event,
    Emitter<FeedState> emit,
  ) async {
    if (_creatingComments.contains(event.postId)) return;

    _creatingComments.add(event.postId);

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
        audioUrl: event.audioUrl,
        duration: event.duration,
        replyToCommentId: event.replyToCommentId,
      );

      final existingComments = state.comments[event.postId] ?? [];
      final replyToCommentId = event.replyToCommentId;

      final updatedComments = Map<int, List<Comment>>.from(
        state.comments,
      );

      if (replyToCommentId != null) {
        final parentIndex = existingComments.indexWhere(
          (item) => item.id == replyToCommentId,
        );

        if (parentIndex >= 0) {
          final updatedList = List<Comment>.from(existingComments);
          updatedList[parentIndex] = updatedList[parentIndex].copyWith(
            replyCount: updatedList[parentIndex].replyCount + 1,
          );
          updatedList.insert(parentIndex + 1, comment);
          updatedComments[event.postId] = updatedList;
        } else {
          updatedComments[event.postId] = [
            comment,
            ...existingComments,
          ];
        }
      } else {
        updatedComments[event.postId] = [
          comment,
          ...existingComments,
        ];
      }

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
          isCreatingComment: _creatingComments.length > 1,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isCreatingComment: _creatingComments.length > 1,
          generalError: e.toString(),
        ),
      );
    } finally {
      _creatingComments.remove(event.postId);
      if (_creatingComments.isEmpty && !isClosed) {
        emit(state.copyWith(isCreatingComment: false));
      }
    }
  }

  Future<void> _onLikePostComment(
    LikePostComment event,
    Emitter<FeedState> emit,
  ) async {
    final reactionKey = '${event.postId}:${event.commentId}:like';
    if (_updatingCommentReactions.contains(reactionKey)) return;

    _updatingCommentReactions.add(reactionKey);
    final originalComments = state.comments[event.postId] ?? [];

    final updatedComments = _updateCommentReaction(
      comments: originalComments,
      commentId: event.commentId,
      markLiked: true,
    );

    emit(
      state.copyWith(
        comments: {
          ...state.comments,
          event.postId: updatedComments,
        },
      ),
    );

    try {
      final updatedComment = await _feedService.likeComment(
        postId: event.postId,
        commentId: event.commentId,
      );
      _replaceComment(
        postId: event.postId,
        comment: updatedComment,
        emit: emit,
      );
    } catch (e) {
      emit(
        state.copyWith(
          comments: {
            ...state.comments,
            event.postId: originalComments,
          },
          generalError: e.toString(),
        ),
      );
    } finally {
      _updatingCommentReactions.remove(reactionKey);
    }
  }

  Future<void> _onDislikePostComment(
    DislikePostComment event,
    Emitter<FeedState> emit,
  ) async {
    final reactionKey = '${event.postId}:${event.commentId}:dislike';
    if (_updatingCommentReactions.contains(reactionKey)) return;

    _updatingCommentReactions.add(reactionKey);
    final originalComments = state.comments[event.postId] ?? [];

    final updatedComments = _updateCommentReaction(
      comments: originalComments,
      commentId: event.commentId,
      markDisliked: true,
    );

    emit(
      state.copyWith(
        comments: {
          ...state.comments,
          event.postId: updatedComments,
        },
      ),
    );

    try {
      final updatedComment = await _feedService.dislikeComment(
        postId: event.postId,
        commentId: event.commentId,
      );
      _replaceComment(
        postId: event.postId,
        comment: updatedComment,
        emit: emit,
      );
    } catch (e) {
      emit(
        state.copyWith(
          comments: {
            ...state.comments,
            event.postId: originalComments,
          },
          generalError: e.toString(),
        ),
      );
    } finally {
      _updatingCommentReactions.remove(reactionKey);
    }
  }

  List<Comment> _updateCommentReaction({
    required List<Comment> comments,
    required int commentId,
    bool markLiked = false,
    bool markDisliked = false,
  }) {
    return comments.map((comment) {
      if (comment.id != commentId) return comment;

      if (markLiked) {
        final wasLiked = comment.isLiked;
        final wasDisliked = comment.isDisliked;
        return comment.copyWith(
          isLiked: !wasLiked,
          isDisliked: false,
          likes: wasLiked
              ? (comment.likes - 1).clamp(0, 2147483647).toInt()
              : comment.likes + 1,
          dislikes: wasDisliked
              ? (comment.dislikes - 1).clamp(0, 2147483647).toInt()
              : comment.dislikes,
        );
      }

      if (markDisliked) {
        final wasLiked = comment.isLiked;
        final wasDisliked = comment.isDisliked;
        return comment.copyWith(
          isLiked: false,
          isDisliked: !wasDisliked,
          likes: wasLiked
              ? (comment.likes - 1).clamp(0, 2147483647).toInt()
              : comment.likes,
          dislikes: wasDisliked
              ? (comment.dislikes - 1).clamp(0, 2147483647).toInt()
              : comment.dislikes + 1,
        );
      }

      return comment;
    }).toList();
  }

  void _replaceComment({
    required int postId,
    required Comment comment,
    required Emitter<FeedState> emit,
  }) {
    final comments = List<Comment>.from(state.comments[postId] ?? []);
    final index = comments.indexWhere((item) => item.id == comment.id);
    if (index >= 0) {
      comments[index] = comment;
    } else {
      comments.insert(0, comment);
    }

    emit(
      state.copyWith(
        comments: {
          ...state.comments,
          postId: comments,
        },
      ),
    );
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
    _prefetchingPages.clear();
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
      await _feedService.removeCachedPost(event.postId);
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
    final editWindow = DateTime.now().difference(event.createdAt);
    if (editWindow > const Duration(hours: 2)) {
      emit(
        state.copyWith(
          generalError: 'You can only edit a post within 2 hours of posting.',
          isUpdatingPost: false,
        ),
      );
      return;
    }

    final hasSourcePost = state.posts.any((post) => post.id == event.postId);
    if (hasSourcePost) {
      final sourcePost = state.posts.firstWhere((post) => post.id == event.postId);
      if (sourcePost.user.id != event.ownerId) {
        emit(
          state.copyWith(
            generalError: 'You can only edit your own posts.',
            isUpdatingPost: false,
          ),
        );
        return;
      }
    }

    final updatedPosts = hasSourcePost
        ? state.posts.map((post) {
            if (post.id != event.postId) return post;
            return post.copyWith(content: event.content);
          }).toList()
        : state.posts;

    emit(state.copyWith(
      posts: updatedPosts,
      clearGeneralError: true,
      isUpdatingPost: true,
    ));

    try {
      final updatedPost = await _feedService.updatePost(
        postId: event.postId,
        content: event.content,
      );

      final nextPosts = hasSourcePost
          ? state.posts.map((post) {
              return post.id == event.postId ? updatedPost : post;
            }).toList()
          : state.posts;

      emit(
        state.copyWith(
          posts: nextPosts,
          clearGeneralError: true,
          isUpdatingPost: false,
        ),
      );
      await _feedService.cachePost(updatedPost);
    } catch (e) {
      emit(
        state.copyWith(
          posts: originalPosts,
          generalError: e.toString(),
          isUpdatingPost: false,
        ),
      );
    }
  }

  Future<void> _cachePosts(List<FeedPost> posts) async {
    final seen = <int>{};
    for (final post in posts) {
      if (!seen.add(post.id)) continue;
      await _feedService.cachePost(post);
    }
  }

  @override
  Future<void> close() {
    _disposed = true;

    return super.close();
  }
}
