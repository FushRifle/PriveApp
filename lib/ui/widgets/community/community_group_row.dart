import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/community_model.dart';

class CommunityGroupRow extends StatelessWidget {
  final CommunityGroupModel group;
  final VoidCallback onJoin;
  final VoidCallback? onOpen;

  const CommunityGroupRow({
    super.key,
    required this.group,
    required this.onJoin,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: group.isMember ? onOpen : onJoin,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: AppColors.secondary,
                ),
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
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.blackTextStyle.copyWith(
                              fontWeight: AppTheme.bold,
                            ),
                          ),
                        ),
                        if (group.isPrivate)
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${group.memberCount} members',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: group.isMember ? onOpen : onJoin,
                child: Text(group.isMember ? 'Open' : 'Join'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
