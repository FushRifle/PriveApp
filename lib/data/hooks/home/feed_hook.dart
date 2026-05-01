import 'package:flutter/foundation.dart';
import 'package:social_media_app/data/services/home/feed_service.dart';
import 'package:social_media_app/data/services/user/user_service.dart';

class FeedHook extends ChangeNotifier {
  final FeedService _feedService = FeedService();
  final UserService _userService = UserService();

  List<dynamic> _posts = [];
  List<dynamic> _stories = [];
  Map<String, dynamic>? _user;
  bool _loading = false;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  // Getters
  List<dynamic> get posts => _posts;
  List<dynamic> get stories => _stories;
  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // Initialize - fetch everything
  Future<void> initialize() async {
    await Future.wait([
      fetchUser(),
      fetchStories(),
      fetchPosts(),
    ]);
  }

  // Fetch current user
  Future<void> fetchUser() async {
    try {
      _user = await _userService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
  }

  // Fetch stories
  Future<void> fetchStories() async {
    try {
      _stories = await _feedService.getStories();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching stories: $e');
    }
  }

  // Fetch posts (with pagination)
  Future<void> fetchPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    notifyListeners();

    try {
      final response = await _feedService.getPosts(page: _currentPage);
      final newPosts = response['posts'] ?? response['data'] ?? [];

      if (refresh || _currentPage == 1) {
        _posts = List.from(newPosts);
      } else {
        _posts.addAll(newPosts);
      }

      _hasMore = newPosts.length >= 10;
      _refreshing = false;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _refreshing = false;
      _loading = false;
      notifyListeners();
    }
  }

  // Load more posts
  Future<void> loadMorePosts() async {
    if (!_hasMore || _loadingMore) return;

    _loadingMore = true;
    _currentPage++;
    notifyListeners();

    await fetchPosts();
    _loadingMore = false;
    notifyListeners();
  }

  // Like post (optimistic update)
  Future<void> likePost(int postId) async {
    // Optimistic update
    _updatePostLocally(postId, (post) {
      post['isLiked'] = true;
      post['likes'] = (post['likes'] ?? 0) + 1;
    });

    try {
      await _feedService.likePost(postId);
    } catch (e) {
      // Revert on failure
      _updatePostLocally(postId, (post) {
        post['isLiked'] = false;
        post['likes'] = (post['likes'] ?? 1) - 1;
      });
    }
  }

  // Unlike post (optimistic update)
  Future<void> unlikePost(int postId) async {
    _updatePostLocally(postId, (post) {
      post['isLiked'] = false;
      post['likes'] = ((post['likes'] ?? 0) - 1).clamp(0, 999999);
    });

    try {
      await _feedService.unlikePost(postId);
    } catch (e) {
      _updatePostLocally(postId, (post) {
        post['isLiked'] = true;
        post['likes'] = (post['likes'] ?? 0) + 1;
      });
    }
  }

  // Create post
  Future<bool> createPost({
    required String content,
    String? imageUrl,
  }) async {
    try {
      await _feedService.createPost(content: content, imageUrl: imageUrl);
      await fetchPosts(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Helper: Update post locally
  void _updatePostLocally(
      int postId, void Function(Map<String, dynamic> post) updateFn) {
    for (int i = 0; i < _posts.length; i++) {
      final post = _posts[i] as Map<String, dynamic>;
      if (post['id'] == postId) {
        updateFn(post);
        break;
      }
    }
    notifyListeners();
  }

  // Refresh all
  Future<void> refresh() async {
    await Future.wait([
      fetchStories(),
      fetchPosts(refresh: true),
    ]);
  }
}
