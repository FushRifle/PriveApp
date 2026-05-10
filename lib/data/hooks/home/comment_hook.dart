import 'package:flutter/foundation.dart';
import 'package:Prive/data/services/home/feed_service.dart';

class CommentsHook extends ChangeNotifier {
  final FeedService _feedService = FeedService();

  final int postId;
  List<Map<String, dynamic>> _comments = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _posting = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  CommentsHook({required this.postId});

  // Getters
  List<Map<String, dynamic>> get comments => _comments;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get posting => _posting;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // Fetch comments
  Future<void> fetchComments({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final newComments =
          await _feedService.getComments(postId, page: _currentPage);

      if (refresh || _currentPage == 1) {
        _comments = List.from(newComments as Iterable<dynamic>);
      } else {
        _comments.addAll(newComments as Iterable<Map<String, dynamic>>);
      }

      _hasMore = newComments.length >= 20;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  // Load more comments
  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;

    _loadingMore = true;
    _currentPage++;
    notifyListeners();

    await fetchComments();
    _loadingMore = false;
    notifyListeners();
  }

  // Add comment (optimistic)
  Future<bool> addComment(String content) async {
    _posting = true;
    notifyListeners();

    // Optimistic insert
    final tempComment = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'postId': postId,
      'user': {'name': 'You', 'avatar': ''},
      'content': content,
      'createdAt': DateTime.now().toIso8601String(),
      'isTemp': true,
    };
    _comments.insert(0, tempComment);
    notifyListeners();

    try {
      await _feedService.addComment(postId: postId, content: content);
      await fetchComments(refresh: true);
      _posting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _comments.removeWhere((c) => c['isTemp'] == true);
      _error = e.toString();
      _posting = false;
      notifyListeners();
      return false;
    }
  }
}
