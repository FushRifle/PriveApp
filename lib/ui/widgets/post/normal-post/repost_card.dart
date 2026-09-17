import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/ui/widgets/post/normal-post/post_card.dart';

class RepostCard extends StatelessWidget {
  final FeedPost post;
  final bool isDetailView;

  const RepostCard({
    super.key,
    required this.post,
    this.isDetailView = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF121B25) : const Color(0xFFFCFDFE);

    if (!post.isReposted) {
      return CardPost(
        post: post,
        isDetailView: isDetailView,
      );
    }

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.45)),
          bottom: BorderSide(color: AppColors.border.withOpacity(0.45)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(isDark ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.repeat_rounded,
                  color: AppColors.secondary,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  'Reposted',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          CardPost(
            post: post,
            isDetailView: isDetailView,
            showOuterDividers: false,
          ),
        ],
      ),
    );
  }
}
