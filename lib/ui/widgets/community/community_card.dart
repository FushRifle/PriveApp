import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/community_model.dart';
import 'package:clique/ui/widgets/community/community_avatar.dart';
import 'package:clique/ui/widgets/community/community_metric.dart';

class CommunityCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const CommunityCard({
    super.key,
    required this.community,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                community.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.blackTextStyle.copyWith(
                                  fontSize: 16,
                                  fontWeight: AppTheme.bold,
                                ),
                              ),
                            ),
                            if (community.isPrivate) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.lock_outline,
                                size: 15,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (community.category.isNotEmpty)
                              _Pill(
                                text: community.category,
                                color: AppColors.secondary,
                              ),
                            if (community.isMember)
                              _Pill(
                                text: 'Member',
                                color: AppColors.success,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _JoinButton(
                    isMember: community.isMember,
                    onPressed: community.isMember ? onTap : onJoin,
                  ),
                ],
              ),
              if (community.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  community.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.greyTextStyle.copyWith(
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  CommunityMetric(
                    icon: Icons.people_alt_outlined,
                    label: '${community.memberCount} members',
                  ),
                  CommunityMetric(
                    icon: Icons.forum_outlined,
                    label: '${community.groupCount} groups',
                  ),
                  if (community.owner?.name.isNotEmpty == true)
                    CommunityMetric(
                      icon: Icons.admin_panel_settings_outlined,
                      label: community.owner!.name,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final bool isMember;
  final VoidCallback onPressed;

  const _JoinButton({
    required this.isMember,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isMember ? AppColors.card : AppColors.primary,
          foregroundColor: isMember ? AppColors.primary : AppColors.white,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(isMember ? 'Open' : 'Join'),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: AppTheme.blackTextStyle.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: AppTheme.bold,
        ),
      ),
    );
  }
}
