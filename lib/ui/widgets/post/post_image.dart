import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/data/models/feeds_models.dart';
import 'package:clique/ui/widgets/ui/image_viewer.dart';
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
        color: AppColors.backgroundColor,
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
      child: Hero(
        tag: 'post_image_${post.id}',
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 1080,
              placeholder: (_, __) {
                return ColoredBox(
                  color: AppColors.backgroundColor,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorWidget: (_, __, ___) {
                return ColoredBox(
                  color: AppColors.backgroundColor,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 42,
                      color: AppColors.textHint,
                    ),
                  ),
                );
              },
            ),
            const _ImageGradient(),
          ],
        ),
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
