import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/community_model.dart';
import 'package:clique/ui/widgets/community/community_avatar.dart';
import 'package:clique/ui/widgets/community/community_metric.dart';

class CommunityDetailHero extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const CommunityDetailHero({
    super.key,
    required this.community,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommunityAvatar(
                name: community.name,
                imageUrl: community.imageUrl,
                size: 68,
                accentColor: AppColors.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            community.name,
                            style: AppTheme.blackTextStyle.copyWith(
                              fontSize: 21,
                              fontWeight: AppTheme.extraBold,
                            ),
                          ),
                        ),
                        if (community.isPrivate)
                          Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CommunityMetric(
                            icon: Icons.people_alt_outlined,
                            label: '${community.memberCount} members',
                          ),
                        ),
                        Expanded(
                          child: CommunityMetric(
                            icon: Icons.forum_outlined,
                            label: '${community.groupCount} groups',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (community.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              community.description,
              style: AppTheme.greyTextStyle.copyWith(height: 1.45),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: community.isMember ? onLeave : onJoin,
              icon: Icon(
                community.isMember ? Icons.logout : Icons.login,
                size: 18,
              ),
              label: Text(
                community.isMember ? 'Leave community' : 'Join community',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: community.isMember
                    ? AppColors.textSecondary
                    : AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
