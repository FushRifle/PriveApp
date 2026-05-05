import 'package:flutter/foundation.dart';
import 'package:social_media_app/data/services/home/feed_service.dart';
import 'package:social_media_app/data/services/user/user_service.dart';

class FeedHook extends ChangeNotifier {
  final FeedService _feedService = FeedService();
  final UserService _userService = UserService();

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _stories = [];
  Map<String, dynamic>? _user;

  bool _loading = false;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;

  int _currentPage = 1;
  final int _pageSize = 10;

  String? _error;

  List<Map<String, dynamic>> get posts => _posts;
  List<Map<String, dynamic>> get stories => _stories;
  Map<String, dynamic>? get user => _user;

  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> initialize() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchUser(notify: false),
        fetchStories(notify: false),
        fetchPosts(refresh: true, notify: false),
      ]);
    } catch (e) {
      _error = _cleanError(e);
      debugPrint('Initialize error: $e');
    } finally {
      _loading = false;
      _refreshing = false;
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchUser({bool notify = true}) async {
    try {
      final result = await _userService.getCurrentUser();

      _user = result;
    } catch (e) {
      debugPrint('Error fetching user: $e');
      _error = _cleanError(e);
    } finally {
      if (notify) notifyListeners();
    }
  }

  Future<void> fetchStories({bool notify = true}) async {
    try {
      final result = await _feedService.getStories();
      _stories = _normalizeList(result);
    } catch (e) {
      debugPrint('Error fetching stories: $e');
      _error = _cleanError(e);
    } finally {
      if (notify) notifyListeners();
    }
  }

  Future<void> fetchPosts({
    bool refresh = false,
    bool notify = true,
  }) async {
    if (_loadingMore && !refresh) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _refreshing = true;
    } else if (_posts.isEmpty) {
      _loading = true;
    }

    _error = null;
    if (notify) notifyListeners();

    try {
      final response = await _feedService.getPosts(page: _currentPage);
      final newPosts = _extractPosts(response);

      if (refresh || _currentPage == 1) {
        _posts = newPosts;
      } else {
        _posts = [..._posts, ...newPosts];
      }

      _hasMore = newPosts.length >= _pageSize;
    } catch (e) {
      _error = _cleanError(e);

      if (!refresh && _currentPage > 1) {
        _currentPage--;
      }

      debugPrint('Error fetching posts: $e');
    } finally {
      _loading = false;
      _refreshing = false;
      if (notify) notifyListeners();
    }
  }

  Future<void> loadMorePosts() async {
    if (!_hasMore || _loadingMore || _loading || _refreshing) return;

    _loadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      await fetchPosts(notify: false);
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> likePost(int postId) async {
    final index = _findPostIndex(postId);
    if (index == -1) return;

    final oldPost = Map<String, dynamic>.from(_posts[index]);

    _updatePostAt(index, {
      ...oldPost,
      'isLiked': true,
      'likes': _toInt(oldPost['likes']) + 1,
    });

    try {
      await _feedService.likePost(postId);
    } catch (e) {
      _updatePostAt(index, oldPost);
      _error = _cleanError(e);
    }
  }

  Future<void> unlikePost(int postId) async {
    final index = _findPostIndex(postId);
    if (index == -1) return;

    final oldPost = Map<String, dynamic>.from(_posts[index]);

    _updatePostAt(index, {
      ...oldPost,
      'isLiked': false,
      'likes': (_toInt(oldPost['likes']) - 1).clamp(0, 999999),
    });

    try {
      await _feedService.unlikePost(postId);
    } catch (e) {
      _updatePostAt(index, oldPost);
      _error = _cleanError(e);
    }
  }

  Future<bool> createPost({
    required String content,
    String? imageUrl,
  }) async {
    try {
      _error = null;
      await _feedService.createPost(
        content: content,
        imageUrl: imageUrl,
      );

      await fetchPosts(refresh: true);
      return true;
    } catch (e) {
      _error = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() async {
    if (_refreshing) return;

    _refreshing = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchUser(notify: false),
        fetchStories(notify: false),
        fetchPosts(refresh: true, notify: false),
      ]);
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  int _findPostIndex(int postId) {
    return _posts.indexWhere((post) => _toInt(post['id']) == postId);
  }

  void _updatePostAt(int index, Map<String, dynamic> updatedPost) {
    final updatedPosts = List<Map<String, dynamic>>.from(_posts);
    updatedPosts[index] = updatedPost;
    _posts = updatedPosts;
    notifyListeners();
  }

  List<Map<String, dynamic>> _extractPosts(dynamic response) {
    if (response is List) {
      return _normalizeList(response);
    }

    if (response is Map<String, dynamic>) {
      final rawPosts = response['posts'] ?? response['data'] ?? [];

      if (rawPosts is List) {
        return _normalizeList(rawPosts);
      }

      throw Exception('Invalid posts format');
    }

    throw Exception('Invalid posts response');
  }

  List<Map<String, dynamic>> _normalizeList(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _cleanError(dynamic error) {
    final message = error.toString();
    return message.replaceFirst('Exception: ', '');
  }
}
