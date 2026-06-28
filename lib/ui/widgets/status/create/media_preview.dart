import 'dart:io';
import 'package:clique/app/configs/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewWidget extends StatelessWidget {
  final File? selectedMediaFile;
  final String? selectedMediaType;
  final bool isPreviewVideoReady;
  final VideoPlayerController? previewVideoController;
  final VoidCallback onRemoveMedia;
  final TextEditingController? captionController;
  final TextAlign captionTextAlign;

  const MediaPreviewWidget({
    super.key,
    required this.selectedMediaFile,
    required this.selectedMediaType,
    required this.isPreviewVideoReady,
    required this.previewVideoController,
    required this.onRemoveMedia,
    this.captionController,
    this.captionTextAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final file = selectedMediaFile;
    if (file == null) return const SizedBox.shrink();

    final isVideo = selectedMediaType == 'video';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 300,
            maxHeight: 400,
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
                // Media Content
                Positioned.fill(
                  child: isVideo
                      ? (isPreviewVideoReady && previewVideoController != null
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: previewVideoController!.value.size.width,
                                height:
                                    previewVideoController!.value.size.height,
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
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVideo
                                  ? Icons.videocam_rounded
                                  : Icons.image_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isVideo ? 'Video' : 'Photo',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Remove button
                      Material(
                        color: Colors.black.withOpacity(0.5),
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
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isVideo && isPreviewVideoReady)
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (captionController != null) ...[
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: captionController,
                  minLines: 1,
                  maxLines: 6,
                  textAlign: captionTextAlign,
                  cursorColor: AppColors.primary,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a caption...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.35)
                          : Colors.black.withOpacity(0.35),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: false,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.35)
                            : Colors.black.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.only(
                      left: 0,
                      right: 0,
                      bottom: 10,
                      top: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Enhanced emoji button
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.08),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // Add emoji picker functionality here
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.emoji_emotions_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
