import 'package:flutter/foundation.dart';
import 'package:social_media_app/data/services/home/feed_service.dart';

class StoryGroup {
  final int userId;
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> stories;
  final bool hasUnseen;
  final String latestStoryTime;
  final int totalSegments;

  StoryGroup({
    required this.userId,
    required this.user,
    required this.stories,
    this.hasUnseen = false,
    this.latestStoryTime = '',
    this.totalSegments = 0,
  });
}

class StoryHook extends ChangeNotifier {
  final FeedService _feedService = FeedService();

  List<Map<String, dynamic>> _stories = [];
  List<StoryGroup> _storyGroups = [];
  StoryGroup? _ownStoryGroup;
  List<StoryGroup> _otherStoryGroups = [];

  bool _loading = false;
  bool _isCreating = false;
  bool _disposed = false;

  String? _error;

  List<Map<String, dynamic>> get stories => _stories;
  List<StoryGroup> get storyGroups => _storyGroups;
  StoryGroup? get ownStoryGroup => _ownStoryGroup;
  List<StoryGroup> get otherStoryGroups => _otherStoryGroups;
  bool get loading => _loading;
  bool get isCreating => _isCreating;
  bool get hasUnseenStories => _otherStoryGroups.any((g) => g.hasUnseen);
  int get unseenStoriesCount =>
      _otherStoryGroups.where((g) => g.hasUnseen).length;
  String? get error => _error;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> fetchStories() async {
    if (_disposed) return;

    _loading = true;
    _error = null;
    _safeNotify();

    try {
      final result = await _feedService.getStories();

      if (_disposed) return;

      _stories = _normalizeStories(result);
      _groupStories();

      _loading = false;
      _safeNotify();
    } catch (e) {
      if (_disposed) return;

      _error = _cleanError(e);
      _loading = false;
      _safeNotify();
    }
  }

  void _groupStories() {
    final Map<int, List<Map<String, dynamic>>> storiesByUser = {};

    for (final story in _stories) {
      final userId =
          _toInt(story['userId'] ?? story['user_id'] ?? story['user']?['id']);

      if (userId == 0) continue;

      storiesByUser.putIfAbsent(userId, () => []);
      storiesByUser[userId]!.add(story);
    }

    final groups = storiesByUser.entries.map((entry) {
      final userStories = entry.value;

      userStories.sort((a, b) {
        final aTime =
            (a['createdAt'] ?? a['created_at'] ?? a['time'] ?? '').toString();
        final bTime =
            (b['createdAt'] ?? b['created_at'] ?? b['time'] ?? '').toString();
        return bTime.compareTo(aTime);
      });

      final firstStory = userStories.first;
      final hasUnseen = userStories
          .any((story) => story['isSeen'] != true && story['is_seen'] != true);

      final totalSegments = userStories.fold<int>(0, (total, story) {
        final attachments = story['attachments'];
        if (attachments is List && attachments.isNotEmpty) {
          return total + attachments.length;
        }
        return total + 1;
      });

      return StoryGroup(
        userId: entry.key,
        user: _asMap(firstStory['user']),
        stories: userStories,
        hasUnseen: hasUnseen,
        latestStoryTime: (firstStory['createdAt'] ??
                firstStory['created_at'] ??
                firstStory['time'] ??
                '')
            .toString(),
        totalSegments: totalSegments,
      );
    }).toList();

    groups.sort((a, b) => b.latestStoryTime.compareTo(a.latestStoryTime));

    _storyGroups = groups;
    _ownStoryGroup = _storyGroups.isNotEmpty ? _storyGroups.first : null;
    _otherStoryGroups = _storyGroups.length > 1 ? _storyGroups.sublist(1) : [];
  }

  Future<bool> createStory({
    String? content,
    List<Map<String, dynamic>>? attachments,
  }) async {
    if (content == null && (attachments == null || attachments.isEmpty)) {
      _error = 'Please add content or media to your story';
      _safeNotify();
      return false;
    }

    _isCreating = true;
    _error = null;
    _safeNotify();

    try {
      await _feedService.createPost(
        content: content ?? '',
        imageUrl: attachments?.isNotEmpty == true
            ? attachments!.first['uri']?.toString()
            : null,
      );

      if (_disposed) return false;

      await fetchStories();

      if (_disposed) return false;

      _isCreating = false;
      _safeNotify();
      return true;
    } catch (e) {
      if (_disposed) return false;

      _error = _cleanError(e);
      _isCreating = false;
      _safeNotify();
      return false;
    }
  }

  Future<bool> deleteStory(String storyId) async {
    try {
      await _feedService.unlikePost(int.tryParse(storyId) ?? 0);

      if (_disposed) return false;

      _stories.removeWhere((s) => s['id'].toString() == storyId);
      _groupStories();
      _safeNotify();

      return true;
    } catch (e) {
      if (!_disposed) {
        _error = _cleanError(e);
        _safeNotify();
      }
      return false;
    }
  }

  Future<void> markAsSeen(String storyId) async {
    for (final story in _stories) {
      if (story['id'].toString() == storyId) {
        story['isSeen'] = true;
        story['is_seen'] = true;
        break;
      }
    }

    _groupStories();
    _safeNotify();
  }

  Future<void> refresh() async {
    await fetchStories();
  }

  List<Map<String, dynamic>> _normalizeStories(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (value is Map) {
      final data = value['stories'] ?? value['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return [];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _cleanError(dynamic error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
