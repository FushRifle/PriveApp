import 'package:flutter/foundation.dart';
import 'package:Prive/data/models/feeds_models.dart';
import 'package:Prive/data/services/home/feed_service.dart';

class StoryGroup {
  final int userId;
  final StoryUser user;
  final List<Story> stories;
  final bool hasUnseen;
  final DateTime latestStoryTime;
  final int totalSegments;

  StoryGroup({
    required this.userId,
    required this.user,
    required this.stories,
    required this.hasUnseen,
    required this.latestStoryTime,
    required this.totalSegments,
  });
}

class StoryHook extends ChangeNotifier {
  final FeedService _feedService = FeedService();

  List<Story> _stories = [];
  List<StoryGroup> _storyGroups = [];
  StoryGroup? _ownStoryGroup;
  List<StoryGroup> _otherStoryGroups = [];

  bool _loading = false;
  bool _isCreating = false;
  bool _disposed = false;

  String? _error;

  List<Story> get stories => _stories;
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

      _stories = result;
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
    final Map<int, List<Story>> storiesByUser = {};

    for (final story in _stories) {
      if (!storiesByUser.containsKey(story.userId)) {
        storiesByUser[story.userId] = [];
      }
      storiesByUser[story.userId]!.add(story);
    }

    final groups = storiesByUser.entries.map((entry) {
      final userStories = entry.value;

      // Sort by createdAt, newest first
      userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final firstStory = userStories.first;
      final hasUnseen = userStories.any((story) => !story.isSeen);

      final totalSegments = userStories.fold<int>(0, (total, story) {
        if (story.attachments.isNotEmpty) {
          return total + story.attachments.length;
        }
        return total + 1;
      });

      return StoryGroup(
        userId: entry.key,
        user: firstStory.user,
        stories: userStories,
        hasUnseen: hasUnseen,
        latestStoryTime: firstStory.createdAt,
        totalSegments: totalSegments,
      );
    }).toList();

    // Sort groups: unviewed first, then by latest story time
    groups.sort((a, b) {
      if (a.hasUnseen && !b.hasUnseen) return -1;
      if (!a.hasUnseen && b.hasUnseen) return 1;
      return b.latestStoryTime.compareTo(a.latestStoryTime);
    });

    _storyGroups = groups;

    // Separate own story (current user) from others
    // You'll need to pass the current user ID or get it from somewhere
    // For now, we'll assume the first group is the user's own if isMe is true
    if (groups.isNotEmpty && groups.first.stories.any((s) => s.isMe)) {
      _ownStoryGroup = groups.first;
      _otherStoryGroups = groups.skip(1).toList();
    } else {
      _ownStoryGroup = null;
      _otherStoryGroups = groups;
    }
  }

  Future<bool> createStory({
    String? content,
    List<Map<String, dynamic>>? attachments,
    String? backgroundColor,
    String? textAlign,
    double? fontSize,
  }) async {
    if ((content == null || content.isEmpty) &&
        (attachments == null || attachments.isEmpty)) {
      _error = 'Please add content or media to your story';
      _safeNotify();
      return false;
    }

    _isCreating = true;
    _error = null;
    _safeNotify();

    try {
      await _feedService.createStory(
        content: content,
        attachments: attachments,
        backgroundColor: backgroundColor,
        textAlign: textAlign,
        fontSize: fontSize,
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
      await _feedService.deleteStory(storyId);

      if (_disposed) return false;

      _stories.removeWhere((s) => s.id == storyId);
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
    // Optimistic update
    bool updated = false;
    for (int i = 0; i < _stories.length; i++) {
      if (_stories[i].id == storyId && !_stories[i].isSeen) {
        final oldStory = _stories[i];
        _stories[i] = Story(
          id: oldStory.id,
          userId: oldStory.userId,
          user: oldStory.user,
          content: oldStory.content,
          attachments: oldStory.attachments,
          time: oldStory.time,
          isMe: oldStory.isMe,
          isSeen: true,
          viewCount: oldStory.viewCount,
          backgroundColor: oldStory.backgroundColor,
          textAlign: oldStory.textAlign,
          fontSize: oldStory.fontSize,
          createdAt: oldStory.createdAt,
          expiresAt: oldStory.expiresAt,
        );
        updated = true;
        break;
      }
    }

    if (updated) {
      _groupStories();
      _safeNotify();
    }

    // Actually mark as seen on backend
    try {
      await _feedService.markStoryAsSeen(storyId);
    } catch (e) {
      // Revert on error
      await fetchStories();
      _error = _cleanError(e);
      _safeNotify();
      rethrow;
    }
  }

  Future<void> refresh() async {
    await fetchStories();
  }

  String _cleanError(dynamic error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
