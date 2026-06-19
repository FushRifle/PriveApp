import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewWidget extends StatelessWidget {
  final File? selectedMediaFile;
  final String? selectedMediaType;
  final bool isPreviewVideoReady;
  final VideoPlayerController? previewVideoController;
  final VoidCallback onRemoveMedia;

  const MediaPreviewWidget({
    super.key,
    required this.selectedMediaFile,
    required this.selectedMediaType,
    required this.isPreviewVideoReady,
    required this.previewVideoController,
    required this.onRemoveMedia,
  });

  @override
  Widget build(BuildContext context) {
    final file = selectedMediaFile;
    if (file == null) return const SizedBox.shrink();

    final isVideo = selectedMediaType == 'video';

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 200,
        maxHeight: 300,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: isVideo
                  ? (isPreviewVideoReady && previewVideoController != null
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: previewVideoController!.value.size.width,
                            height: previewVideoController!.value.size.height,
                            child: VideoPlayer(previewVideoController!),
                          ),
                        )
                      : Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ))
                  : Image.file(
                      file,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isVideo ? 'Video' : 'Image',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.red.withOpacity(0.8),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onRemoveMedia();
                      },
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}