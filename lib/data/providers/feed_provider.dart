import 'package:Prive/data/services/cached_feed_service.dart';
import 'package:Prive/data/hooks/home/feed_hook.dart';
import 'package:Prive/data/hooks/home/story_hook.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

class CachedFeedData {
  final List<dynamic> posts;
  final List<dynamic> stories;
  final Map<String, dynamic> user;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final bool fromCache;
  final int totalPosts;

  const CachedFeedData({
    required this.posts,
    required this.stories,
    required this.user,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.fromCache = false,
    this.totalPosts = 0,
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
    int? totalPosts,
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
      totalPosts: totalPosts ?? this.totalPosts,
    );
  }
}

class FeedNotifier extends StateNotifier<CachedFeedData> {
  final FeedHook _feedHook = FeedHook();
  final StoryHook _storyHook = StoryHook();
  final CachedFeedService _cacheService = CachedFeedService();

  int _currentPage = 1;
  Timer? _debounceTimer;
  bool _isRefreshing = false;

  FeedNotifier()
      : super(const CachedFeedData(posts: [], stories: [], user: {})) {
    _init();
  }

  Future<void> _init() async {
    await fetchData();
  }

  Future<void> fetchData() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Parallel cache loading
      final results = await Future.wait([
        _cacheService.getCachedPosts(),
        _cacheService.getCachedStories(),
        _cacheService.shouldRefetch(),
      ]);

      final cachedPosts = results[0] as List<dynamic>;
      final cachedStories = results[1] as List<dynamic>;
      final shouldRefetch = results[2] as bool;

      // Show cached data immediately if available
      if (cachedPosts.isNotEmpty) {
        state = state.copyWith(
          posts: cachedPosts,
          stories: cachedStories,
          fromCache: true,
          isLoading: false,
        );
      }

      // Fetch fresh data if needed
      if (shouldRefetch || cachedPosts.isEmpty) {
        // Add small delay to prevent UI jank
        await Future.delayed(const Duration(milliseconds: 100));
        await _fetchFreshData();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _fetchFreshData() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      // Parallel fetching for better performance
      await Future.wait([
        _feedHook.fetchPosts(),
        _storyHook.fetchStories(),
      ]);

      final freshPosts = _feedHook.posts;
      final freshStories = _storyHook.stories;
      final user = _feedHook.user ?? {};

      // Cache in background (don't await)
      unawaited(_cacheService.cachePosts(freshPosts));
      unawaited(_cacheService.cacheStories(freshStories));

      state = state.copyWith(
        posts: freshPosts,
        stories: freshStories,
        user: user,
        hasMore: _feedHook.hasMore,
        isLoading: false,
        fromCache: false,
        error: null,
        totalPosts: freshPosts.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;

    // Reset state
    _currentPage = 1;

    // Clear cache in background
    unawaited(_cacheService.clearCache());

    await _fetchFreshData();
  }

  Future<void> loadMore() async {
    // Prevent multiple simultaneous load more calls
    if (state.isLoadingMore || !state.hasMore || _isRefreshing) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      await _feedHook.loadMorePosts();
      _currentPage++;

      final newPosts = _feedHook.posts;

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        hasMore: _feedHook.hasMore,
        isLoadingMore: false,
        totalPosts: state.posts.length + newPosts.length,
      );

      // Update cache in background with debounce
      _debounceCacheUpdate();
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void _debounceCacheUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(_cacheService.cachePosts(state.posts));
    });
  }

  // Helper method to check if feed is empty
  bool get isEmpty =>
      state.posts.isEmpty && !state.isLoading && !state.fromCache;

  // Helper method to get story count
  int get storyCount => state.stories.length;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, CachedFeedData>((ref) {
  return FeedNotifier();
});

// Selectors for better performance
final feedPostsProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(feedProvider).posts;
});

final feedStoriesProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(feedProvider).stories;
});

final feedIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(feedProvider).isLoading;
});

final feedHasMoreProvider = Provider<bool>((ref) {
  return ref.watch(feedProvider).hasMore;
});
