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
    if (!post.isReposted) {
      return CardPost(
        post: post,
        isDetailView: isDetailView,
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: isDetailView ? 0 : 18, top: 10),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.22),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.repeat_rounded,
                  color: AppColors.text,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  'Reposted',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10,),
          CardPost(
            post: post,
            isDetailView: isDetailView,
          ),
        ],
      ),
    );
  }
}
