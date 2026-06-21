import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:clique/app/configs/colors.dart';

class VideoLoading extends StatelessWidget {
  const VideoLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class VideoUnavailable extends StatelessWidget {
  const VideoUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: AppColors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Video unavailable',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.55),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoProgress extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoProgress({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final duration = value.duration.inMilliseconds;
          final position = value.position.inMilliseconds;

          final progress =
              duration <= 0 ? 0.0 : (position / duration).clamp(0.0, 1.0);

          return LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            color: AppColors.white,
            backgroundColor: AppColors.white.withOpacity(0.18),
          );
        },
      ),
    );
  }
}