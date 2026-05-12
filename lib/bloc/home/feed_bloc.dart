import 'package:Prive/data/models/feeds_models.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:Prive/data/services/home/feed_service.dart';

part 'feed_event.dart';
part 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedService _feedService = FeedService();

  // Keep track locally
  List<FeedPost> _posts = [];
  List<Story> _stories = [];
  int _currentPage = 1;
  final int _pageSize = 10;

  FeedBloc() : super(const FeedState()) {
    on<FetchFeedData>(_onFetchFeedData);
    on<RefreshFeed>(_onRefreshFeed);
    on<LoadMorePosts>(_onLoadMorePosts);
    on<LikePost>(_onLikePost);
    on<UnlikePost>(_onUnlikePost);
    on<CreatePost>(_onCreatePost);
    on<MarkStoryAsSeen>(_onMarkStoryAsSeen);
  }

  Future<void> _onFetchFeedData(
    FetchFeedData event,
    Emitter<FeedState> emit,
  ) async {
    if (state.posts.isEmpty) {
      emit(state.copyWith(status: FeedStatus.loading));
    }

    try {
      // Reset pagination
      _currentPage = 1;

      // Fetch posts and stories in parallel
      final results = await Future.wait([
        _feedService.getPosts(page: _currentPage),
        _feedService.getStories(),
      ]);

      final postsResponse = results[0] as PostsResponse;
      final storiesList = results[1] as List<Story>;

      _posts = postsResponse.posts;
      _stories = storiesList;

      emit(state.copyWith(
        posts: _posts.map((post) => post.toJson()).toList(),
        stories: _stories.map((story) => story.toJson()).toList(),
        hasMore: postsResponse.hasMore,
        status: FeedStatus.success,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FeedStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshFeed(
    RefreshFeed event,
    Emitter<FeedState> emit,
  ) async {
    _currentPage = 1;

    try {
      // Fetch fresh data
      final results = await Future.wait([
        _feedService.getPosts(page: _currentPage),
        _feedService.getStories(),
      ]);

      final postsResponse = results[0] as PostsResponse;
      final storiesList = results[1] as List<Story>;

      _posts = postsResponse.posts;
      _stories = storiesList;

      emit(state.copyWith(
        posts: _posts.map((post) => post.toJson()).toList(),
        stories: _stories.map((story) => story.toJson()).toList(),
        hasMore: postsResponse.hasMore,
        status: FeedStatus.success,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FeedStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMorePosts(
    LoadMorePosts event,
    Emitter<FeedState> emit,
  ) async {
    if (state.status == FeedStatus.loadingMore || !state.hasMore) return;

    emit(state.copyWith(status: FeedStatus.loadingMore));

    try {
      _currentPage++;
      final response = await _feedService.getPosts(page: _currentPage);

      _posts.addAll(response.posts);

      emit(state.copyWith(
        posts: _posts.map((post) => post.toJson()).toList(),
        hasMore: response.hasMore,
        status: FeedStatus.success,
      ));
    } catch (e) {
      // Rollback page on error
      _currentPage--;
      emit(state.copyWith(
        status: FeedStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLikePost(
    LikePost event,
    Emitter<FeedState> emit,
  ) async {
    // Find and update locally first (optimistic update)
    final postIndex = _posts.indexWhere((post) => post.id == event.postId);
    if (postIndex == -1) return;

    final oldPost = _posts[postIndex];
    final updatedPost = oldPost.copyWith(
      isLiked: true,
      likes: oldPost.likes + 1,
    );

    _posts[postIndex] = updatedPost;

    // Emit updated state
    emit(state.copyWith(
      posts: _posts.map((post) => post.toJson()).toList(),
    ));

    // Make API call
    try {
      await _feedService.likePost(event.postId);
    } catch (e) {
      // Rollback on error
      _posts[postIndex] = oldPost;
      emit(state.copyWith(
        posts: _posts.map((post) => post.toJson()).toList(),
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUnlikePost(
    UnlikePost event,
    Emitter<FeedState> emit,
  ) async {
    // Find and update locally first (optimistic update)
    final postIndex = _posts.indexWhere((post) => post.id == event.postId);
    if (postIndex == -1) return;

    final oldPost = _posts[postIndex];
    final updatedPost = oldPost.copyWith(
      isLiked: false,
      likes: (oldPost.likes - 1).clamp(0, 999999),
    );

    _posts[postIndex] = updatedPost;

    // Emit updated state
    emit(state.copyWith(
      posts: _posts.map((post) => post.toJson()).toList(),
    ));

    // Make API call
    try {
      await _feedService.unlikePost(event.postId);
    } catch (e) {
      // Rollback on error
      _posts[postIndex] = oldPost;
      emit(state.copyWith(
        posts: _posts.map((post) => post.toJson()).toList(),
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCreatePost(
    CreatePost event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _feedService.createPost(content: event.content);
      // Refresh the feed after creating post
      add(RefreshFeed());
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
      ));
    }
  }

  Future<void> _onMarkStoryAsSeen(
    MarkStoryAsSeen event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _feedService.markStoryAsSeen(event.storyId);

      // Update local story list
      final updatedStories = _stories.map((story) {
        if (story.id == event.storyId) {
          return story.copyWith(isSeen: true);
        }
        return story;
      }).toList();

      _stories = updatedStories;

      emit(state.copyWith(
        stories: _stories.map((story) => story.toJson()).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
      ));
    }
  }
}
