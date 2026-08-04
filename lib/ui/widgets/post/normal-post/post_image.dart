import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/ui/widgets/common/ui/image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostImage extends StatelessWidget {
  final FeedPost post;
  final Attachment attachment;

  const PostImage({
    super.key,
    required this.post,
    required this.attachment,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = attachment.url;

    if (imageUrl.trim().isEmpty) {
      return ColoredBox(
        color: AppColors.black,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 42,
            color: AppColors.textHint,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) {
              return ImageViewer(
                imageUrl: imageUrl,
                caption: post.content.trim().isNotEmpty ? post.content : null,
              );
            },
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.black),
          LayoutBuilder(
            builder: (context, constraints) {
              final pixelRatio = MediaQuery.devicePixelRatioOf(context);
              final logicalWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              final logicalHeight = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : logicalWidth;
              final cacheWidth =
                  (logicalWidth * pixelRatio).round().clamp(240, 1080);
              final cacheHeight =
                  (logicalHeight * pixelRatio).round().clamp(240, 1080);

              return CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                memCacheWidth: cacheWidth,
                memCacheHeight: cacheHeight,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (_, __) => const ColoredBox(
                  color: AppColors.black,
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 34,
                      color: AppColors.white24,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) {
                  return ColoredBox(
                    color: AppColors.black,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 42,
                        color: AppColors.textHint,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const _ImageGradient(),
        ],
      ),
    );
  }
}

class _ImageGradient extends StatelessWidget {
  const _ImageGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.55, 1],
          colors: [
            Color.fromRGBO(0, 0, 0, 0.10),
            AppColors.transparent,
            Color.fromRGBO(0, 0, 0, 0.16),
          ],
        ),
      ),
    );
  }
}
