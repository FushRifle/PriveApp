import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_media_app/data/services/cached_feed_service.dart';
import 'package:social_media_app/data/hooks/home/feed_hook.dart';
import 'package:social_media_app/data/hooks/home/story_hook.dart';

class CachedFeedData {
  final List<dynamic> posts;
  final List<dynamic> stories;
  final Map<String, dynamic> user;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final bool fromCache;

  CachedFeedData({
    required this.posts,
    required this.stories,
    required this.user,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.fromCache = false,
  });

  CachedFeedData copyWith({
    List<dynamic>? posts,
    List<dynamic>? stories,
    Map<String, dynamic>? user,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? fromCache,
  }) {
    return CachedFeedData(
      posts: posts ?? this.posts,
      stories: stories ?? this.stories,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

class FeedNotifier extends StateNotifier<CachedFeedData> {
  final FeedHook _feedHook = FeedHook();
  final StoryHook _storyHook = StoryHook();
  final CachedFeedService _cacheService = CachedFeedService();

  int _currentPage = 1;

  FeedNotifier() : super(CachedFeedData(posts: [], stories: [], user: {})) {
    fetchData();
  }

  Future<void> fetchData() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Try to get cached data first
      final cachedPosts = await _cacheService.getCachedPosts();
      final cachedStories = await _cacheService.getCachedStories();

      if (cachedPosts.isNotEmpty) {
        state = state.copyWith(
          posts: cachedPosts,
          stories: cachedStories,
          fromCache: true,
        );
      }

      // Check if we need to refetch
      final shouldRefetch = await _cacheService.shouldRefetch();

      if (shouldRefetch || cachedPosts.isEmpty) {
        await _fetchFreshData();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _fetchFreshData() async {
    try {
      await Future.wait([
        _feedHook.fetchPosts(),
        _storyHook.fetchStories(),
      ]);

      final freshPosts = _feedHook.posts;
      final freshStories = _storyHook.stories;
      final user = _feedHook.user ?? {};

      // Cache the fresh data
      await _cacheService.cachePosts(freshPosts);
      await _cacheService.cacheStories(freshStories);

      state = state.copyWith(
        posts: freshPosts,
        stories: freshStories,
        user: user,
        hasMore: _feedHook.hasMore,
        isLoading: false,
        fromCache: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    _currentPage = 1;
    await _cacheService.clearCache();
    await _fetchFreshData();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      await _feedHook.loadMorePosts();
      _currentPage++;

      state = state.copyWith(
        posts: [...state.posts, ..._feedHook.posts],
        hasMore: _feedHook.hasMore,
        isLoadingMore: false,
      );

      // Update cache with new posts
      await _cacheService.cachePosts(state.posts);
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, CachedFeedData>((ref) {
  return FeedNotifier();
});
