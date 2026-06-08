import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/community_model.dart';
import 'package:clique/ui/widgets/common/effect_text.dart';

class CommunityDiscussionCard extends StatelessWidget {
  final DiscussionPostModel post;

  const CommunityDiscussionCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = post.author?.avatar ?? '';
    final name = post.author?.name ?? 'Member';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            backgroundImage:
                avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
            child: avatar.isNotEmpty
                ? null
                : Text(
                    name.isEmpty ? 'M' : name.characters.first.toUpperCase(),
                    style: AppTheme.blackTextStyle.copyWith(
                      color: AppColors.primary,
                      fontWeight: AppTheme.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.semiBold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                EffectText(
                  text: post.content,
                  style: AppTheme.blackTextStyle.copyWith(height: 1.38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
