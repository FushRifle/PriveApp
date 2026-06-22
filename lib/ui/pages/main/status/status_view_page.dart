import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/models/status_model.dart';
import 'package:clique/core/services/status/status_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/ui/widgets/common/effect_text.dart';
import 'package:clique/ui/widgets/post/normal-post/post_reaction_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class StatusViewPage extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StatusViewPage({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StatusViewPage> createState() => _StatusViewPageState();
}

class _StatusViewPageState extends State<StatusViewPage>
    with TickerProviderStateMixin {
  static const _defaultStoryDuration = Duration(seconds: 5);
  static const _maximumVideoStoryDuration = Duration(minutes: 1);

  late AnimationController _progressController;
  late int currentIndex;
  late PageController _pageController;
  late final TextEditingController _replyController;
  late final FocusNode _replyFocusNode;
  final StatusService _statusService = StatusService();
  late List<Story> _stories;
  bool _isPaused = false;
  bool _pausedForReply = false;
  bool _pausedForInteraction = false;
  bool _shouldResumeAfterInteraction = false;
  bool _isSendingReply = false;
  bool _showReplySent = false;
  final Set<String> _expandedStoryTextIds = {};

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _stories = List<Story>.from(widget.stories);
    _pageController = PageController(initialPage: currentIndex);
    _replyController = TextEditingController();
    _replyFocusNode = FocusNode()..addListener(_handleReplyFocusChanged);

    _progressController = AnimationController(
      vsync: this,
      duration: _defaultStoryDuration,
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _setupAutoAdvance();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _stories.isEmpty) return;
      _startStoryProgress(_stories[currentIndex]);
      _markStoryAsSeen(_stories[currentIndex].id);
    });
  }

  @override
  void didUpdateWidget(covariant StatusViewPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stories != widget.stories) {
      _stories = List<Story>.from(widget.stories);
      if (_stories.isNotEmpty && currentIndex >= _stories.length) {
        currentIndex = _stories.length - 1;
      }
    }
  }

  void _setupAutoAdvance() {
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _nextStatus();
      }
    });
  }

  bool _isVideoStory(Story story) {
    return story.attachments.isNotEmpty &&
        story.attachments.first.type.toLowerCase() == 'video';
  }

  void _startStoryProgress(Story story) {
    _progressController.reset();

    if (_isVideoStory(story)) {
      // Wait for the player to report its real duration before starting.
      _progressController.duration = _maximumVideoStoryDuration;
      return;
    }

    _progressController.duration = _defaultStoryDuration;
    if (!_isPaused) {
      _progressController.forward();
    }
  }

  void _handleVideoDuration(String storyId, Duration duration) {
    if (!mounted || _stories.isEmpty) return;
    final currentStory = _stories[_safeStoryIndex(_stories)];
    if (currentStory.id != storyId || !_isVideoStory(currentStory)) return;

    final reportedDuration =
        duration > Duration.zero ? duration : _defaultStoryDuration;
    final durationMs = reportedDuration.inMilliseconds
        .clamp(1, _maximumVideoStoryDuration.inMilliseconds)
        .toInt();
    _progressController
      ..duration = Duration(milliseconds: durationMs)
      ..reset();
    if (!_isPaused) {
      _progressController.forward();
    }
  }

  void _nextStatus() {
    if (currentIndex < _stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _previousStatus() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        _progressController.forward();
      } else {
        _progressController.stop();
      }
      _isPaused = !_isPaused;
    });
  }

  void _pausePlayback({bool forReply = false}) {
    if (!_isPaused) {
      _progressController.stop();
      setState(() => _isPaused = true);
    }
    if (forReply) _pausedForReply = true;
  }

  void _pausePlaybackForInteraction() {
    _pausedForInteraction = true;
    _shouldResumeAfterInteraction = !_isPaused;
    if (_shouldResumeAfterInteraction) {
      _pausePlayback();
    }
  }

  void _resumePlayback({bool fromReply = false}) {
    if (fromReply && !_pausedForReply) return;
    _pausedForReply = false;
    if (_pausedForInteraction && fromReply) return;
    if (_isPaused) {
      _progressController.forward();
      setState(() => _isPaused = false);
    }
  }

  void _resumePlaybackAfterInteraction() {
    if (!_pausedForInteraction) return;
    final shouldResume = _shouldResumeAfterInteraction;
    _pausedForInteraction = false;
    _shouldResumeAfterInteraction = false;
    if (!shouldResume) return;
    if (_replyFocusNode.hasFocus) return;
    if (_isPaused) {
      _progressController.forward();
      setState(() => _isPaused = false);
    }
  }

  void _handleReplyFocusChanged() {
    if (_replyFocusNode.hasFocus) {
      _pausePlayback(forReply: true);
    } else {
      _resumePlayback(fromReply: true);
    }
  }

  void _markStoryAsSeen(String storyId) {
    _storiesBlocOrNull()?.add(MarkStorySeen(storyId: storyId));
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    _replyFocusNode.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final storiesBloc = _storiesBlocOrNull();
    if (storiesBloc == null) {
      return _buildViewer(_stories);
    }

    return BlocListener<StoriesBloc, StoriesState>(
      bloc: storiesBloc,
      listenWhen: (previous, current) {
        return previous.stories != current.stories;
      },
      listener: (context, state) {
        if (!mounted || state.stories.isEmpty) return;

        final nextStories = List<Story>.from(state.stories);
        if (nextStories.length == _stories.length &&
            nextStories.every((story) => _stories.any((item) =>
                item.id == story.id &&
                item.isLiked == story.isLiked &&
                item.isReshared == story.isReshared &&
                item.reaction == story.reaction &&
                item.likeCount == story.likeCount &&
                item.reshareCount == story.reshareCount))) {
          return;
        }

        setState(() {
          _stories = nextStories;
          if (currentIndex >= _stories.length) {
            currentIndex = _stories.length - 1;
          }
        });
      },
      child: _buildViewer(_stories),
    );
  }

  Widget _buildViewer(List<Story> stories) {
    final safeIndex = _safeStoryIndex(stories);

    if (stories.isNotEmpty && safeIndex != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            currentIndex = safeIndex;
          });
        }
      });
    }

    if (stories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });

      return const Scaffold(
        backgroundColor: AppColors.black,
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final size = MediaQuery.of(context).size;
          if (details.globalPosition.dy > size.height - 120) return;

          final screenWidth = size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _previousStatus();
          } else {
            _nextStatus();
          }
        },
        onLongPress: _togglePause,
        onLongPressUp: _togglePause,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: stories.length,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
                _startStoryProgress(stories[index]);
                _markStoryAsSeen(stories[index].id);
              },
              itemBuilder: (context, index) {
                return _buildStatusContent(stories[index]);
              },
            ),
            _buildHeader(stories),
            _buildProgressBars(stories),
            _buildBottomActions(stories),
            if (_showReplySent) _buildReplySentToast(),
            if (_isPaused && !_replyFocusNode.hasFocus)
              Positioned(
                top: MediaQuery.of(context).padding.top + 90,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.black.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      'Paused',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(Story story) {
    final hasImage =
        story.attachments.isNotEmpty && story.attachments.first.type == 'image';
    final hasVideo =
        story.attachments.isNotEmpty && story.attachments.first.type == 'video';
    final hasText = story.content != null && story.content!.isNotEmpty;

    final mediaUrl = hasImage || hasVideo ? story.attachments.first.url : null;

    if (mediaUrl != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.black,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: hasImage
                    ? Image(
                        image: _getImageProvider(mediaUrl),
                        fit: BoxFit.contain,
                        width: double.infinity,
                      )
                    : _StatusVideoPlayer(
                        url: mediaUrl,
                        isActive:
                            story.id == _stories[_safeStoryIndex(_stories)].id,
                        isPaused: _isPaused,
                        onDurationReady: (duration) {
                          _handleVideoDuration(story.id, duration);
                        },
                      ),
              ),
              if (hasText)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _StoryTextBubble(
                    story: story,
                    expanded: _expandedStoryTextIds.contains(story.id),
                    maxLines: 3,
                    onToggle: () => _toggleStoryText(story.id),
                    style: _getTextStyle(story, hasMedia: true).copyWith(
                      shadows: const [],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _getBackgroundColor(story.backgroundColor),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: hasText
                  ? _StoryTextBubble(
                      story: story,
                      expanded: _expandedStoryTextIds.contains(story.id),
                      maxLines: 8,
                      onToggle: () => _toggleStoryText(story.id),
                      textAlign: _getTextAlign(story.textAlign),
                      style: _getTextStyle(story, hasMedia: false),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleStoryText(String storyId) {
    _pausePlaybackForInteraction();
    setState(() {
      if (!_expandedStoryTextIds.add(storyId)) {
        _expandedStoryTextIds.remove(storyId);
      }
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _resumePlaybackAfterInteraction();
    });
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImageProvider(imageUrl);
    }
    return AssetImage(imageUrl);
  }

  TextAlign _getTextAlign(String? textAlign) {
    switch (textAlign?.toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  TextStyle _getTextStyle(Story story, {bool hasMedia = false}) {
    double fontSize = story.fontSize ?? 24;

    final contentLength = story.content?.length ?? 0;
    if (contentLength > 200) {
      fontSize = (fontSize * 0.8).clamp(16.0, 24.0);
    } else if (contentLength > 100) {
      fontSize = (fontSize * 0.9).clamp(18.0, 28.0);
    }

    return TextStyle(
      color: AppColors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 0.5,
      shadows: null,
    );
  }

  Color _getBackgroundColor(String? hexColor) {
    if (hexColor != null && hexColor.isNotEmpty) {
      try {
        String colorStr = hexColor;
        if (colorStr.startsWith('#')) {
          colorStr = colorStr.substring(1);
        }
        if (colorStr.startsWith('0x')) {
          colorStr = colorStr.substring(2);
        }

        if (colorStr.length == 6) {
          return Color(int.parse('FF$colorStr', radix: 16));
        } else if (colorStr.length == 8) {
          return Color(int.parse(colorStr, radix: 16));
        }
      } catch (e) {
        debugPrint('Error parsing color: $e');
      }
    }

    return AppColors.storyTextBackground;
  }

  Widget _buildHeader(List<Story> stories) {
    final story = stories[_safeStoryIndex(stories)];
    return Positioned(
      top: MediaQuery.of(context).padding.top + 30,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
            ),
            child: ClipOval(
              child: _buildAvatar(story.user.avatar),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.user.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  story.time,
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.white, size: 28),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  NamedRoutes.homeScreen,
                );
              }
            },
          ),
          if (_isOwnStory(story))
            IconButton(
              icon: const Icon(
                Icons.more_horiz,
                color: AppColors.white,
                size: 28,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                _showStoryOptions(story);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String avatarUrl) {
    if (avatarUrl.isEmpty) {
      return Container(
        color: AppColors.grey,
        child: const Icon(Icons.person, color: AppColors.white, size: 20),
      );
    }

    if (avatarUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: avatarUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          color: AppColors.grey,
          child: const Icon(Icons.person, color: AppColors.white, size: 20),
        ),
      );
    }

    return Image.asset(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.grey,
        child: const Icon(Icons.person, color: AppColors.white, size: 20),
      ),
    );
  }

  Widget _buildProgressBars(List<Story> stories) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 8,
      right: 8,
      child: Row(
        children: List.generate(
          stories.length,
          (index) => Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: index < currentIndex
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  : index == currentIndex
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progressController.value,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        )
                      : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(List<Story> stories) {
    final story = stories[_safeStoryIndex(stories)];

    return Positioned(
      bottom: 30,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _replyController,
                focusNode: _replyFocusNode,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Send message',
                  hintStyle: TextStyle(
                    color: AppColors.white.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _sendReply(value, story);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildLikeButton(story),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showRepostSheet(story),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.7, end: 1).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                story.isReshared
                    ? Icons.repeat_on_rounded
                    : Icons.repeat_rounded,
                key: ValueKey<bool>(story.isReshared),
                color: AppColors.white,
                size: 22,
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: story.isReshared
                  ? AppColors.primary.withOpacity(0.82)
                  : AppColors.card.withOpacity(0.7),
              foregroundColor: AppColors.white,
              shape: const CircleBorder(),
              side: BorderSide(
                color: AppColors.white.withOpacity(0.3),
                width: 1,
              ),
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_replyController.text.trim().isNotEmpty) {
                _sendReply(_replyController.text, story);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: _isSendingReply
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: AppColors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplySentToast() {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 96,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _showReplySent ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.72),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.4),
                ),
              ),
              child: const Text(
                'Reply sent',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLikeButton(Story story) {
    final liked = story.isLiked;
    final reaction = _reactionForStory(story);

    return AnimatedScale(
      scale: liked ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: liked
              ? AppColors.redColor.withOpacity(0.14)
              : AppColors.card.withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(
            color: liked
                ? AppColors.redColor.withOpacity(0.55)
                : AppColors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: IconButton(
          onPressed: () => _likeStory(story),
          onLongPress: () => _showStoryReactionPicker(story),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.65, end: 1).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              liked ? reaction.icon : Icons.favorite_border,
              key: ValueKey<bool>(liked),
              color: liked ? reaction.color : AppColors.white,
              size: 22,
            ),
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.transparent,
            foregroundColor: liked ? AppColors.redColor : AppColors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(10),
          ),
        ),
      ),
    );
  }

  int _safeStoryIndex(List<Story> stories) {
    if (stories.isEmpty) return 0;
    return currentIndex.clamp(0, stories.length - 1).toInt();
  }

  void _likeStory(Story story) {
    if (story.isLiked) {
      _toggleStoryReaction(story, null);
      return;
    }
    _toggleStoryReaction(story, postReactions.first);
  }

  void _showStoryReactionPicker(Story story) {
    showPostReactionPicker(
      context,
      onSelected: (reaction) => _toggleStoryReaction(story, reaction),
    );
  }

  void _toggleStoryReaction(Story story, PostReaction? reaction) {
    HapticFeedback.lightImpact();
    _pausePlaybackForInteraction();

    final nextLiked = reaction != null;
    _replaceCurrentStory(
      story.copyWith(
        isLiked: nextLiked,
        reaction: reaction?.label ?? '',
        likeCount: nextLiked
            ? story.likeCount + (story.isLiked ? 0 : 1)
            : (story.likeCount - 1).clamp(0, 2147483647).toInt(),
      ),
    );

    final bloc = _storiesBlocOrNull();
    if (bloc != null) {
      bloc.add(
        nextLiked
            ? LikeStoryEvent(storyId: story.id, reaction: reaction.label)
            : UnlikeStoryEvent(storyId: story.id),
      );
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _resumePlaybackAfterInteraction();
    });
  }

  PostReaction _reactionForStory(Story story) {
    final label = story.reaction;
    if (label == null || label.trim().isEmpty) {
      return postReactions[1];
    }
    return postReactions.firstWhere(
      (reaction) => reaction.label.toLowerCase() == label.toLowerCase(),
      orElse: () => postReactions[1],
    );
  }

  Future<void> _sendReply(String message, Story story) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _isSendingReply || story.userId <= 0) return;

    setState(() => _isSendingReply = true);
    _pausePlaybackForInteraction();

    try {
      await _statusService.replyToStory(
        storyId: story.id,
        content: trimmed,
        receiverId: story.userId,
      );
      _replaceCurrentStory(
        story.copyWith(replyCount: story.replyCount + 1),
      );

      if (!mounted) return;
      _replyController.clear();
      _replyFocusNode.unfocus();
      setState(() => _showReplySent = true);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _showReplySent = false);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send reply',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingReply = false);
      _resumePlaybackAfterInteraction();
    }
  }

  void _showRepostSheet(Story story) {
    if (story.isReshared) {
      return;
    }

    _pausePlayback(forReply: true);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.repeat_rounded),
                  title: const Text('Repost'),
                  subtitle: const Text('Share this status instantly'),
                  onTap: () {
                    Navigator.pop(context);
                    _repostStory(story);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded),
                  title: const Text('Repost with caption'),
                  subtitle: const Text(
                      'Caption support will attach when backend accepts it'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRepostCaptionDialog(story);
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => _resumePlayback(fromReply: true));
  }

  void _showRepostCaptionDialog(Story story) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Repost with caption'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a caption',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _repostStory(story, caption: controller.text.trim());
              },
              child: const Text('Repost'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _repostStory(Story story, {String caption = ''}) {
    if (story.isReshared) return;

    _pausePlaybackForInteraction();

    _replaceCurrentStory(
      story.copyWith(
        isReshared: true,
        reshareCount: story.reshareCount + 1,
      ),
    );

    _storiesBlocOrNull()?.add(ReshareStoryEvent(storyId: story.id));

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _resumePlaybackAfterInteraction();
    });
  }

  void _replaceCurrentStory(Story story) {
    if (!mounted || _stories.isEmpty) return;

    setState(() {
      _stories = List<Story>.from(_stories)..[currentIndex] = story;
    });
  }

  void _showStoryOptions(Story story) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete Status'),
                  textColor: AppColors.redColor,
                  iconColor: AppColors.redColor,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeleteStory(story);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteStory(Story story) {
    final bloc = _storiesBlocOrNull();
    if (bloc == null) return;

    bloc.add(DeleteStoryEvent(storyId: story.id));
  }

  void _confirmDeleteStory(Story story) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Delete story?'),
          content: const Text(
            'This will remove the story immediately and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteStory(story);
              },
              child: Text(
                'Delete',
                style: TextStyle(color: AppColors.redColor),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isOwnStory(Story story) {
    if (story.isMe) return true;

    try {
      final user = context.read<UserBloc>().state.currentUser;
      final currentUserId = user?['id'];
      final parsedUserId = currentUserId is int
          ? currentUserId
          : currentUserId is String
              ? int.tryParse(currentUserId)
              : null;
      return parsedUserId != null && parsedUserId == story.userId;
    } catch (_) {
      return false;
    }
  }

  StoriesBloc? _storiesBlocOrNull() {
    try {
      return context.read<StoriesBloc>();
    } catch (_) {
      return null;
    }
  }
}

class _StoryTextBubble extends StatelessWidget {
  final Story story;
  final bool expanded;
  final int maxLines;
  final VoidCallback onToggle;
  final TextStyle style;
  final TextAlign textAlign;

  const _StoryTextBubble({
    required this.story,
    required this.expanded,
    required this.maxLines,
    required this.onToggle,
    required this.style,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final text = story.content ?? '';
    final shouldOfferMore = text.length > (maxLines <= 3 ? 120 : 260);
    final lineLimit = expanded ? null : maxLines;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight =
            MediaQuery.sizeOf(context).height * (maxLines <= 3 ? 0.22 : 0.56);

        return Align(
          alignment: _alignmentFor(textAlign),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: maxHeight,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.10),
                ),
              ),
              child: SingleChildScrollView(
                physics: expanded
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: _crossAxisFor(textAlign),
                  children: [
                    _StoryHashtagText(
                      text: text,
                      textAlign: textAlign,
                      maxLines: lineLimit,
                      overflow: expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: style.copyWith(
                        fontSize: style.fontSize?.clamp(15.0, 28.0),
                        height: 1.35,
                        letterSpacing: 0,
                      ),
                    ),
                    if (shouldOfferMore) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onToggle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            expanded ? 'see less' : 'see more',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Alignment _alignmentFor(TextAlign align) {
    switch (align) {
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.left:
      case TextAlign.start:
        return Alignment.centerLeft;
      default:
        return Alignment.center;
    }
  }

  CrossAxisAlignment _crossAxisFor(TextAlign align) {
    switch (align) {
      case TextAlign.right:
        return CrossAxisAlignment.end;
      case TextAlign.left:
      case TextAlign.start:
        return CrossAxisAlignment.start;
      default:
        return CrossAxisAlignment.center;
    }
  }
}

class _StatusVideoPlayer extends StatefulWidget {
  final String url;
  final bool isActive;
  final bool isPaused;
  final ValueChanged<Duration> onDurationReady;

  const _StatusVideoPlayer({
    required this.url,
    required this.isActive,
    required this.isPaused,
    required this.onDurationReady,
  });

  @override
  State<_StatusVideoPlayer> createState() => _StatusVideoPlayerState();
}

class _StatusVideoPlayerState extends State<_StatusVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _StatusVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _initialize();
      return;
    }
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.isPaused != widget.isPaused) {
      if (!oldWidget.isActive && widget.isActive) {
        final duration = _controller?.value.duration;
        if (duration != null && duration > Duration.zero) {
          widget.onDurationReady(duration);
        }
      }
      _syncPlayback();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (widget.url.trim().isEmpty) return;

    final controller = widget.url.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.url))
        : VideoPlayerController.asset(widget.url);
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(0);
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      widget.onDurationReady(controller.value.duration);
      await _syncPlayback();
      setState(() {
        _isReady = true;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  Future<void> _syncPlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (widget.isActive && !widget.isPaused) {
      if (controller.value.position >= controller.value.duration) {
        await controller.seekTo(Duration.zero);
      }
      await controller.play();
    } else {
      await controller.pause();
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    _isReady = false;
    await controller?.pause();
    await controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_hasError) {
      return const Center(
        child: Icon(Icons.videocam_off_outlined, color: AppColors.white),
      );
    }
    if (!_isReady || controller == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.white,
          strokeWidth: 2,
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _StoryHashtagText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow overflow;

  const _StoryHashtagText({
    required this.text,
    required this.textAlign,
    required this.style,
    this.maxLines,
    this.overflow = TextOverflow.visible,
  });

  @override
  Widget build(BuildContext context) {
    return EffectText(
      text: text,
      textAlign: textAlign,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      hashtagColor: AppColors.storyYellow,
      mentionColor: AppColors.storyGreen,
      effectShadows: const [
        Shadow(
          blurRadius: 12,
          color: AppColors.black87,
          offset: Offset(1, 1),
        ),
      ],
    );
  }
}
