import 'package:Prive/data/services/cached_feed_service.dart';
import 'package:Prive/data/hooks/home/feed_hook.dart';
import 'package:Prive/data/hooks/home/story_hook.dart';
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

  // Add this method to fetch stories independently
  Future<void> fetchStories() async {
    try {
      await _storyHook.fetchStories();
      final freshStories = _storyHook.stories;

      state = state.copyWith(
        stories: freshStories,
        error: null,
      );

      // Update cache with fresh stories
      await _cacheService.cacheStories(freshStories);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
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
    await _cacheService.clearCache();
    await _fetchFreshData();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      await _feedHook.loadMorePosts();

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

  Future<void> markStoryAsSeen(String storyId) async {
    try {
      await _storyHook.markAsSeen(storyId);
      final updatedStories = state.stories.map((story) {
        if (story['id'].toString() == storyId) {
          return {...story, 'isSeen': true, 'is_seen': true};
        }
        return story;
      }).toList();

      state = state.copyWith(stories: updatedStories);

      await _cacheService.cacheStories(updatedStories);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> likePost(int postId) async {
    try {
      await _feedHook.likePost(postId);

      final updatedPosts = state.posts.map((post) {
        if (post['id'] == postId) {
          return {
            ...post,
            'isLiked': true,
            'likes': (post['likes'] ?? 0) + 1,
          };
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);
      await _cacheService.cachePosts(updatedPosts);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> unlikePost(int postId) async {
    try {
      await _feedHook.unlikePost(postId);

      final updatedPosts = state.posts.map((post) {
        if (post['id'] == postId) {
          return {
            ...post,
            'isLiked': false,
            'likes': ((post['likes'] ?? 0) - 1).clamp(0, 999999),
          };
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);
      await _cacheService.cachePosts(updatedPosts);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> createPost({
    required String content,
    String? imageUrl,
  }) async {
    try {
      await _feedHook.createPost(content: content, imageUrl: imageUrl);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> createStory({
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? backgroundColor,
    String? textAlign,
    double? fontSize,
  }) async {
    try {
      await _storyHook.createStory(
        content: text,
        attachments: imageUrl != null
            ? [
                {'type': 'image', 'url': imageUrl}
              ]
            : null,
        backgroundColor: backgroundColor,
        textAlign: textAlign,
        fontSize: fontSize,
      );
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, CachedFeedData>((ref) {
  return FeedNotifier();
});
