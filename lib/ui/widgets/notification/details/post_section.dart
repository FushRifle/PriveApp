import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/feeds_models.dart';

class PostSection extends StatelessWidget {
  final bool isLoading;
  final FeedPost? post;
  final int postId;
  final String postImage;
  final VoidCallback onOpenPost;

  const PostSection({
    super.key,
    required this.isLoading,
    required this.post,
    required this.postId,
    required this.postImage,
    required this.onOpenPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Related Post',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (post != null)
            _RelatedPost(
              post: post!,
              postImage: postImage,
              onOpenPost: onOpenPost,
            )
          else
            _UnavailablePost(postId: postId),
        ],
      ),
    );
  }
}

class _RelatedPost extends StatelessWidget {
  final FeedPost post;
  final String postImage;
  final VoidCallback onOpenPost;

  const _RelatedPost({
    required this.post,
    required this.postImage,
    required this.onOpenPost,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = postImage.isNotEmpty
        ? postImage
        : (post.attachments.isNotEmpty ? post.attachments.first.url : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  post.user.name.isNotEmpty ? post.user.name[0] : 'U',
                  style: AppTheme.blackTextStyle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                post.user.name,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (post.content.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            post.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
        if (imageUrl.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.greyColor.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 120,
                color: AppColors.greyColor.withOpacity(0.1),
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onOpenPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('View Post'),
          ),
        ),
      ],
    );
  }
}

class _UnavailablePost extends StatelessWidget {
  final int postId;

  const _UnavailablePost({required this.postId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            Icons.visibility_off_outlined,
            color: AppColors.textSecondary.withOpacity(0.5),
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            postId > 0 ? 'Post #$postId unavailable' : 'No post attached',
            style: AppTheme.greyTextStyle.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}