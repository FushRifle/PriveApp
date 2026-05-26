import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';

class VideoViewer extends StatefulWidget {
  final String videoUrl;
  final String? caption;
  final String? thumbnailUrl;

  const VideoViewer({
    super.key,
    required this.videoUrl,
    this.caption,
    this.thumbnailUrl,
  });

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _hasError = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  void _initVideoPlayer() {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    _controller.addListener(() {
      if (mounted && _controller.value.isInitialized) {
        setState(() {
          _position = _controller.value.position;
          _isPlaying = _controller.value.isPlaying;
        });
      }
    });

    _controller.setLooping(false);
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _duration = _controller.value.duration;
        });
        _controller.play();
      }
    }).catchError((error) {
      debugPrint('Error initializing video: $error');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _hasError = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;

    if (_isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            // Video Player
            Center(
              child: _isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : _hasError
                      ? const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.white54,
                            size: 64,
                          ),
                        )
                      : widget.thumbnailUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.thumbnailUrl!,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                child: Icon(
                                  Icons.video_library,
                                  color: Colors.white54,
                                  size: 64,
                                ),
                              ),
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
            ),

            // Close Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Play/Pause Overlay Button
            if (_isInitialized && !_isPlaying)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Video Controls (Bottom)
            if (_isInitialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress Bar
                      Row(
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _position.inSeconds.toDouble(),
                              min: 0,
                              max: _duration.inSeconds > 0
                                  ? _duration.inSeconds.toDouble()
                                  : 1.0,
                              activeColor: AppColors.primary,
                              inactiveColor: Colors.white30,
                              onChanged: (value) {
                                final newPosition =
                                    Duration(seconds: value.toInt());
                                _controller.seekTo(newPosition);
                              },
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // Caption if provided
                      if (widget.caption != null && widget.caption!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            widget.caption!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Caption only (if video not initialized)
            if (!_isInitialized &&
                widget.caption != null &&
                widget.caption!.isNotEmpty)
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
