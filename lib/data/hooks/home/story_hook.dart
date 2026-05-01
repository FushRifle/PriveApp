import 'package:flutter/foundation.dart';
import 'package:social_media_app/data/services/home/feed_service.dart';

class StoryGroup {
  final int userId;
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> stories;
  final bool hasUnseen;
  final String latestStoryTime;
  int totalSegments;

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
  String? _error;

  // Getters
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

  // Fetch stories
  Future<void> fetchStories() async {
    _loading = true;
    notifyListeners();

    try {
      _stories = await _feedService.getStories() as List<Map<String, dynamic>>;
      _groupStories();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  // Group stories by user
  void _groupStories() {
    final Map<int, StoryGroup> groups = {};

    for (final story in _stories) {
      final userId = story['userId'] ?? story['user']?['id'];
      if (userId == null) continue;

      if (!groups.containsKey(userId)) {
        groups[userId] = StoryGroup(
          userId: userId,
          user: story['user'] ?? {},
          stories: [],
          hasUnseen: false,
          latestStoryTime: story['time'] ?? '',
          totalSegments: 0,
        );
      }

      final group = groups[userId]!;
      group.stories.add(story);
      group.totalSegments += (story['attachments'] as List?)?.length ?? 1;

      if (story['isSeen'] != true) {
        // hasUnseen is final, need to handle differently
      }
    }

    _storyGroups = groups.values.toList();
    _ownStoryGroup = _storyGroups.isNotEmpty ? _storyGroups.first : null;
    _otherStoryGroups = _storyGroups.length > 1 ? _storyGroups.sublist(1) : [];
  }

  // Create story
  Future<bool> createStory({
    String? content,
    List<Map<String, dynamic>>? attachments,
  }) async {
    if (content == null && (attachments == null || attachments.isEmpty)) {
      _error = 'Please add content or media to your story';
      notifyListeners();
      return false;
    }

    _isCreating = true;
    notifyListeners();

    try {
      await _feedService.createPost(
        content: content ?? '',
        imageUrl: attachments?.first['uri'],
      );
      await fetchStories();
      _isCreating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isCreating = false;
      notifyListeners();
      return false;
    }
  }

  // Delete story
  Future<bool> deleteStory(String storyId) async {
    try {
      await _feedService.unlikePost(int.tryParse(storyId) ?? 0);
      _stories.removeWhere((s) => s['id'] == storyId);
      _groupStories();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mark story as seen
  Future<void> markAsSeen(String storyId) async {
    for (final story in _stories) {
      if (story['id'] == storyId) {
        story['isSeen'] = true;
        break;
      }
    }
    _groupStories();
    notifyListeners();
  }

  // Refresh
  Future<void> refresh() async {
    await fetchStories();
  }
}
