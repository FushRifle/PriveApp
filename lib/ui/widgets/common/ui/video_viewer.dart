import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';

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
  final Dio _dio = Dio();
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _hasError = false;
  bool _isSaving = false;
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
      backgroundColor: AppColors.black,
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
                            color: AppColors.white54,
                            size: 64,
                          ),
                        )
                      : widget.thumbnailUrl != null
                          ? AppNetworkImage(
                              imageUrl: widget.thumbnailUrl!,
                              fit: BoxFit.contain,
                              preset: AppNetworkImagePreset.fullscreen,
                              placeholder: (_) =>
                                  const ColoredBox(color: AppColors.black),
                              errorBuilder: (_) => const Center(
                                child: Icon(
                                  Icons.video_library,
                                  color: AppColors.white54,
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
                    color: AppColors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: _isSaving ? null : _saveVideo,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(
                          Icons.download_rounded,
                          color: AppColors.white,
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
                    color: AppColors.transparent,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: AppColors.white,
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
                        AppColors.black.withOpacity(0.8),
                        AppColors.transparent,
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
                              color: AppColors.white,
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
                              inactiveColor: AppColors.white30,
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
                              color: AppColors.white,
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
                              color: AppColors.white70,
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
                    color: AppColors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.caption!,
                    style: const TextStyle(
                      color: AppColors.white,
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

  Future<void> _saveVideo() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      if (kIsWeb) {
        _showSnackBar('Saving videos is not supported on web');
        return;
      }

      final permission = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          iosAccessLevel: IosAccessLevel.addOnly,
        ),
      );
      if (!permission.hasAccess) {
        _showSnackBar('Photo access is required to save videos');
        return;
      }

      final file = await _downloadVideo();
      await PhotoManager.editor.saveVideo(
        file,
        title: file.uri.pathSegments.last,
      );
      _showSnackBar('Saved to gallery');
    } catch (_) {
      _showSnackBar('Unable to save video');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<File> _downloadVideo() async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/clique_${DateTime.now().microsecondsSinceEpoch}.mp4',
    );

    await _dio.downloadUri(Uri.parse(widget.videoUrl), file.path);
    if (!await file.exists() || await file.length() == 0) {
      throw StateError('Video download failed');
    }
    return file;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
