import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:flutter/material.dart';

class AnonymousPostBody extends StatelessWidget {
  final FeedPost post;
  final bool isDetailView;

  const AnonymousPostBody({
    super.key,
    required this.post,
    required this.isDetailView,
  });

  @override
  Widget build(BuildContext context) {
    final category = post.anonymousCategory?.trim().isNotEmpty == true
        ? post.anonymousCategory!.trim()
        : 'confession';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor.withOpacity(0.82),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.primary.withOpacity(0.12),
                  ),
                  child: const Icon(
                    Icons.visibility_off_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anonymous',
                      style: AppTheme.blackTextStyle.copyWith(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      category[0].toUpperCase() + category.substring(1),
                      style: AppTheme.greyTextStyle.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your identity stays hidden on this post.',
              style: AppTheme.greyTextStyle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
