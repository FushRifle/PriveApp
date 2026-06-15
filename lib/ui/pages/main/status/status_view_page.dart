import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/models/status_model.dart';
import 'package:clique/ui/pages/main/status/edit_status_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/ui/widgets/common/effect_text.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  late AnimationController _progressController;
  late int currentIndex;
  late PageController _pageController;
  late final TextEditingController _replyController;
  late final FocusNode _replyFocusNode;
  bool _isPaused = false;
  bool _pausedForReply = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
    _replyController = TextEditingController();
    _replyFocusNode = FocusNode()..addListener(_handleReplyFocusChanged);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _progressController.forward();
    _setupAutoAdvance();
  }

  void _setupAutoAdvance() {
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _nextStatus();
      }
    });
  }

  void _nextStatus() {
    final stories = _resolvedStories();
    if (currentIndex < stories.length - 1) {
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

  void _resumePlayback({bool fromReply = false}) {
    if (fromReply && !_pausedForReply) return;
    _pausedForReply = false;
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
    context.read<StoriesBloc>().add(MarkStorySeen(storyId: storyId));
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

    return BlocBuilder<StoriesBloc, StoriesState>(
      builder: (context, state) {
        final stories =
            state.stories.isNotEmpty ? state.stories : widget.stories;
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
                // Status Content
                PageView.builder(
                  controller: _pageController,
                  itemCount: stories.length,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                    _progressController.reset();
                    if (!_isPaused) {
                      _progressController.forward();
                    }
                    // Mark story as seen when viewed
                    _markStoryAsSeen(stories[index].id);
                  },
                  itemBuilder: (context, index) {
                    return _buildStatusContent(stories[index]);
                  },
                ),

                // Header
                _buildHeader(stories),

                // Progress Bars
                _buildProgressBars(stories),

                // Bottom Actions
                _buildBottomActions(stories),

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
      },
    );
  }

  Widget _buildStatusContent(Story story) {
    final hasImage =
        story.attachments.isNotEmpty && story.attachments.first.type == 'image';
    final hasVideo =
        story.attachments.isNotEmpty && story.attachments.first.type == 'video';
    final hasText = story.content != null && story.content!.isNotEmpty;

    final mediaUrl = hasImage || hasVideo ? story.attachments.first.url : null;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: mediaUrl != null
          ? AppColors.black
          : _getBackgroundColor(story.backgroundColor),
      child: Container(
        decoration: mediaUrl != null
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.black.withOpacity(0.3),
                    AppColors.transparent,
                    AppColors.black.withOpacity(0.5),
                  ],
                ),
              )
            : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (mediaUrl != null)
              Positioned.fill(
                child: Image(
                  image: _getImageProvider(mediaUrl),
                  fit: BoxFit.contain,
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: hasText
                    ? SingleChildScrollView(
                        child: _StoryHashtagText(
                          text: story.content!,
                          textAlign: _getTextAlign(story.textAlign),
                          style: _getTextStyle(story, hasMedia: mediaUrl != null),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
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
              Navigator.pushReplacementNamed(context, NamedRoutes.homeScreen);
            },
          ),
          if (story.isMe)
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
                color: AppColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.3),
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
                  if (value.isNotEmpty) {
                    _sendReply(value, story);
                    _replyController.clear();
                    _replyFocusNode.unfocus();
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
            icon: Icon(
              story.isReshared ? Icons.repeat_on_rounded : Icons.repeat_rounded,
              color: AppColors.white,
              size: 22,
            ),
            style: IconButton.styleFrom(
              backgroundColor: story.isReshared
                  ? AppColors.primary.withOpacity(0.82)
                  : AppColors.transparent,
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
              if (_replyController.text.isNotEmpty) {
                _sendReply(_replyController.text, story);
                _replyController.clear();
                _replyFocusNode.unfocus();
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(
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

  Widget _buildLikeButton(Story story) {
    final liked = story.isLiked;

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
              : AppColors.transparent,
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
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.65, end: 1).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              key: ValueKey<bool>(liked),
              color: liked ? AppColors.redColor : AppColors.white,
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

  List<Story> _resolvedStories() {
    final stories = context.read<StoriesBloc>().state.stories;
    return stories.isNotEmpty ? stories : widget.stories;
  }

  void _likeStory(Story story) {
    HapticFeedback.lightImpact();
    context.read<StoriesBloc>().add(
          story.isLiked
              ? UnlikeStoryEvent(storyId: story.id)
              : LikeStoryEvent(storyId: story.id),
        );
  }

  void _sendReply(String message, Story story) {
    context.read<StoriesBloc>().add(
          ReplyToStoryEvent(
            storyId: story.id,
            content: message.trim(),
          ),
        );
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
    context.read<StoriesBloc>().add(ReshareStoryEvent(storyId: story.id));
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
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Status'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<StoriesBloc>(),
                          child: EditStatusPage(story: story),
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete Status'),
                  textColor: AppColors.redColor,
                  iconColor: AppColors.redColor,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context
                        .read<StoriesBloc>()
                        .add(DeleteStoryEvent(storyId: story.id));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StoryHashtagText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final TextStyle style;

  const _StoryHashtagText({
    required this.text,
    required this.textAlign,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return EffectText(
      text: text,
      textAlign: textAlign,
      style: style,
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
