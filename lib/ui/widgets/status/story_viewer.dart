import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/core/models/status_model.dart';
import 'package:clique/ui/widgets/status/story_progress.dart';
import 'package:clique/ui/widgets/status/story_reply_bar.dart';
import 'package:clique/ui/widgets/status/story_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

class StoryViewer extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final VoidCallback? onClose;

  const StoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.onClose,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late final PageController _pageController;
  late final TextEditingController _replyController;

  int _currentIndex = 0;
  late List<Story> _stories;
  bool _isPaused = false;
  bool _isReplying = false;

  Story get _currentStory => _stories[_currentIndex];

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.stories.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.stories.length - 1);
    _stories = List<Story>.from(widget.stories);

    _replyController = TextEditingController();
    _pageController = PageController(initialPage: _currentIndex);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener(_onProgressStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _stories.isEmpty) return;
      _markSeen(_currentStory);
      _startProgress();
    });
  }

  @override
  void didUpdateWidget(covariant StoryViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stories != widget.stories) {
      _stories = List<Story>.from(widget.stories);
      if (_stories.isNotEmpty && _currentIndex >= _stories.length) {
        _currentIndex = _stories.length - 1;
      }
    }
  }

  @override
  void dispose() {
    _progressController
      ..removeStatusListener(_onProgressStatus)
      ..dispose();

    _pageController.dispose();
    _replyController.dispose();

    super.dispose();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goNext();
    }
  }

  void _startProgress() {
    if (!mounted || _isPaused || _isReplying) return;

    _progressController
      ..reset()
      ..forward();
  }

  void _pause() {
    if (_isPaused) return;

    setState(() {
      _isPaused = true;
    });

    _progressController.stop();
  }

  void _resume() {
    if (!_isPaused) return;

    setState(() {
      _isPaused = false;
    });

    if (!_isReplying) {
      _progressController.forward();
    }
  }

  void _goNext() {
    if (_currentIndex < _stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _close();
  }

  void _goPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _progressController
      ..reset()
      ..forward();
  }

  void _onTapDown(TapDownDetails details) {
    if (_isReplying) return;

    final width = MediaQuery.sizeOf(context).width;
    final x = details.globalPosition.dx;

    if (x < width * 0.35) {
      _goPrevious();
    } else {
      _goNext();
    }
  }

  void _onPageChanged(int index) {
    if (!mounted) return;

    setState(() {
      _currentIndex = index;
      _isPaused = false;
    });

    _markSeen(_stories[index]);
    _startProgress();
  }

  void _markSeen(Story story) {
    if (!mounted) return;

    context.read<StoriesBloc>().add(
          MarkStorySeen(storyId: story.id),
        );
  }

  void _sendReply(String text) {
    final value = text.trim();

    if (value.isEmpty) return;

    HapticFeedback.lightImpact();

    _replyController.clear();
    context.read<StoriesBloc>().add(
          ReplyToStoryEvent(
            storyId: _currentStory.id,
            content: value,
          ),
        );
    _replaceCurrentStory(
      _currentStory.copyWith(replyCount: _currentStory.replyCount + 1),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reply sent to ${_currentStory.user.name}'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );

    FocusScope.of(context).unfocus();

    if (!mounted) return;

    setState(() {
      _isReplying = false;
      _isPaused = false;
    });

    _progressController.forward();
  }

  void _likeStory() {
    HapticFeedback.mediumImpact();
    final story = _currentStory;
    final nextLiked = !story.isLiked;

    context.read<StoriesBloc>().add(
          nextLiked
              ? LikeStoryEvent(storyId: story.id)
              : UnlikeStoryEvent(storyId: story.id),
        );

    _replaceCurrentStory(
      story.copyWith(
        isLiked: nextLiked,
        likeCount: nextLiked
            ? story.likeCount + 1
            : (story.likeCount - 1).clamp(0, 2147483647).toInt(),
      ),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nextLiked
              ? 'Liked ${story.user.name}\'s story'
              : 'Removed like from ${story.user.name}\'s story',
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _reshareStory() {
    final story = _currentStory;
    if (story.isReshared) return;

    HapticFeedback.mediumImpact();

    context.read<StoriesBloc>().add(ReshareStoryEvent(storyId: story.id));
    _replaceCurrentStory(
      story.copyWith(
        isReshared: true,
        reshareCount: story.reshareCount + 1,
      ),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reshared ${story.user.name}\'s story'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _replaceCurrentStory(Story story) {
    if (!mounted || _stories.isEmpty) return;

    setState(() {
      _stories = List<Story>.from(_stories)..[_currentIndex] = story;
    });
  }

  void _close() {
    widget.onClose?.call();

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: Text(
            'No stories available',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.black,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onTapDown,
          onLongPressStart: (_) => _pause(),
          onLongPressEnd: (_) => _resume(),
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 550) {
              _close();
            }
          },
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _stories.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _StoryContent(
                    story: _stories[index],
                    isActive: index == _currentIndex,
                  );
                },
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 8,
                right: 8,
                child: StoryProgress(
                  count: _stories.length,
                  currentIndex: _currentIndex,
                  animation: _progressController,
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 28,
                left: 14,
                right: 14,
                child: StoryHeader(
                  story: _currentStory,
                  onClose: _close,
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.paddingOf(context).bottom + 14,
                child: StoryReplyBar(
                  controller: _replyController,
                  isReplying: _isReplying,
                  onFocusChanged: (focused) {
                    if (!mounted) return;
                    setState(() {
                      _isReplying = focused;
                      _isPaused = focused;
                    });

                    if (focused) {
                      _progressController.stop();
                    } else {
                      _progressController.forward();
                    }
                  },
                  onSend: _sendReply,
                  onLike: _likeStory,
                  onReshare: _reshareStory,
                  isLiked: _currentStory.isLiked,
                  isReshared: _currentStory.isReshared,
                ),
              ),
              if (_isPaused && !_isReplying)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Color.fromRGBO(0, 0, 0, 0.42),
                      child: Center(
                        child: Icon(
                          Icons.pause_circle_filled_rounded,
                          color: AppColors.white,
                          size: 66,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryContent extends StatelessWidget {
  final Story story;
  final bool isActive;

  const _StoryContent({
    required this.story,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final attachment =
        story.attachments.isNotEmpty ? story.attachments.first : null;
    final hasText = story.content != null && story.content!.trim().isNotEmpty;
    final type = attachment?.type.toLowerCase();
    final url = attachment?.url;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (type == 'image' && url != null && url.isNotEmpty)
          _StoryImage(url: url)
        else if (type == 'video' && url != null && url.isNotEmpty)
          _StoryVideo(url: url, isActive: isActive)
        else
          ColoredBox(
            color: _backgroundColor(story.backgroundColor),
          ),
        const _StoryGradient(),
        if (hasText)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SingleChildScrollView(
                child: Text(
                  story.content!,
                  textAlign: _textAlign(story.textAlign),
                  style: _textStyle(story, hasMedia: attachment != null),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _backgroundColor(String? value) {
    if (value == null || value.isEmpty) {
      return AppColors.storyTextBackground;
    }

    try {
      var hex = value.replaceAll('#', '').replaceAll('0x', '');

      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return AppColors.storyTextBackground;
    }
  }

  TextAlign _textAlign(String? value) {
    switch (value?.toLowerCase()) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }

  TextStyle _textStyle(Story story, {required bool hasMedia}) {
    final length = story.content?.length ?? 0;

    double size = story.fontSize ?? 28;

    if (length > 220) {
      size = size.clamp(17, 22);
    } else if (length > 120) {
      size = size.clamp(20, 26);
    }

    return TextStyle(
      color: AppColors.white,
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: 1.35,
      letterSpacing: 0.2,
      shadows: hasMedia
          ? const [
              Shadow(
                blurRadius: 12,
                color: AppColors.black87,
                offset: Offset(0, 2),
              ),
            ]
          : null,
    );
  }
}

class _StoryImage extends StatelessWidget {
  final String url;

  const _StoryImage({
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 1200,
        placeholder: (_, __) => const ColoredBox(
          color: AppColors.black,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.white,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => const ColoredBox(
          color: AppColors.black,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.white70,
              size: 48,
            ),
          ),
        ),
      );
    }

    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return const ColoredBox(
          color: AppColors.black,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.white70,
              size: 48,
            ),
          ),
        );
      },
    );
  }
}

class _StoryVideo extends StatefulWidget {
  final String url;
  final bool isActive;

  const _StoryVideo({
    required this.url,
    required this.isActive,
  });

  @override
  State<_StoryVideo> createState() => _StoryVideoState();
}

class _StoryVideoState extends State<_StoryVideo> {
  VideoPlayerController? _controller;

  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  @override
  void didUpdateWidget(covariant _StoryVideo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      _disposeController();
      _initialize();
      return;
    }

    if (oldWidget.isActive != widget.isActive) {
      widget.isActive ? _controller?.play() : _controller?.pause();
    }
  }

  @override
  void dispose() {
    _disposeController();

    super.dispose();
  }

  Future<void> _disposeController() async {
    final controller = _controller;

    _controller = null;
    _ready = false;

    await controller?.pause();
    await controller?.dispose();
  }

  Future<void> _initialize() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );

      _controller = controller;

      await controller.initialize();
      await controller.setLooping(true);

      if (widget.isActive) {
        await controller.play();
      }

      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }

      setState(() {
        _ready = true;
        _error = false;
      });
    } catch (e) {
      debugPrint('Story video error: $e');

      if (!mounted) return;

      setState(() {
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const ColoredBox(
        color: AppColors.black,
        child: Center(
          child: Icon(
            Icons.video_library_outlined,
            color: AppColors.white70,
            size: 56,
          ),
        ),
      );
    }

    if (!_ready || _controller == null) {
      return const ColoredBox(
        color: AppColors.black,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final size = _controller!.value.size;

    if (size.width <= 0 || size.height <= 0) {
      return const ColoredBox(
        color: AppColors.black,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}

class _StoryGradient extends StatelessWidget {
  const _StoryGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.28, 0.72, 1],
          colors: [
            Color.fromRGBO(0, 0, 0, 0.55),
            AppColors.transparent,
            AppColors.transparent,
            Color.fromRGBO(0, 0, 0, 0.70),
          ],
        ),
      ),
    );
  }
}
