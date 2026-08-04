import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/ui/widgets/common/ui/video_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class PostVideo extends StatefulWidget {
  final FeedPost post;
  final Attachment attachment;
  final bool isActive;

  const PostVideo({
    super.key,
    required this.post,
    required this.attachment,
    this.isActive = true,
  });

  @override
  State<PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends State<PostVideo>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;

  bool _isInitialized = false;
  bool _hasError = false;
  bool _isMuted = true;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();

    if (widget.isActive) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(covariant PostVideo oldWidget) {
    super.didUpdateWidget(oldWidget);

    final urlChanged = oldWidget.attachment.url != widget.attachment.url;

    if (urlChanged) {
      _disposeController();
      if (widget.isActive) {
        _initializeVideo();
      }
    } else if (!oldWidget.isActive && widget.isActive) {
      _initializeVideo();
    } else if (oldWidget.isActive && !widget.isActive) {
      _disposeController();
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
    _isInitialized = false;

    await controller?.pause();
    await controller?.dispose();
  }

  Future<void> _initializeVideo() async {
    final url = widget.attachment.url;

    if (url.isEmpty) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
      });

      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
        ),
      );

      _controller = controller;

      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);

      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('PostVideo init error: $e');

      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
    }
  }

  void _openVideoViewer() {
    HapticFeedback.lightImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return VideoViewer(
            videoUrl: widget.attachment.url,
            thumbnailUrl: widget.attachment.thumbnail,
            caption: widget.post.content.trim().isNotEmpty
                ? widget.post.content
                : null,
          );
        },
      ),
    );
  }

  Future<void> _toggleMute() async {
    final controller = _controller;

    if (controller == null || !_isInitialized) return;

    HapticFeedback.selectionClick();

    if (!mounted) return;

    setState(() {
      _isMuted = !_isMuted;
    });

    await controller.setVolume(_isMuted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      onTap: _openVideoViewer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.black),
          _buildVideoPreview(),
          const _VideoGradient(),
          const Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: AppColors.white,
              size: 62,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: AppColors.white,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_hasError) {
      return _VideoFallback(
        thumbnail: widget.attachment.thumbnail,
      );
    }

    if (_isInitialized && _controller != null) {
      final size = _controller!.value.size;

      if (size.width <= 0 || size.height <= 0) {
        return _VideoFallback(
          thumbnail: widget.attachment.thumbnail,
        );
      }

      return FittedBox(
        fit: BoxFit.fitWidth,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }

    return _VideoFallback(
      thumbnail: widget.attachment.thumbnail,
      isLoading: true,
    );
  }
}

class _VideoFallback extends StatelessWidget {
  final String? thumbnail;
  final bool isLoading;

  const _VideoFallback({
    this.thumbnail,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = thumbnail;

    if (image != null && image.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        memCacheWidth: 1080,
        memCacheHeight: 1080,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.black,
      child: Center(
        child: isLoading
            ? const Icon(
                Icons.play_circle_outline_rounded,
                color: AppColors.white24,
                size: 48,
              )
            : Icon(
                Icons.video_library_outlined,
                color: AppColors.textHint,
                size: 48,
              ),
      ),
    );
  }
}

class _VideoGradient extends StatelessWidget {
  const _VideoGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.55, 1],
          colors: [
            Color.fromRGBO(0, 0, 0, 0.16),
            AppColors.transparent,
            Color.fromRGBO(0, 0, 0, 0.26),
          ],
        ),
      ),
    );
  }
}
