import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/community_model.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';

class CommunityGroupInfoPage extends StatelessWidget {
  final CommunityGroupModel group;
  final List<CommunityMemberModel> members;

  const CommunityGroupInfoPage({
    super.key,
    required this.group,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: const Text('Group info'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.secondary.withOpacity(0.13),
              backgroundImage: group.imageUrl.isNotEmpty
                  ? appNetworkImageProvider(
                      context,
                      group.imageUrl,
                      logicalWidth: 72,
                    )
                  : null,
              child: group.imageUrl.isEmpty
                  ? const Icon(
                      Icons.groups_2_outlined,
                      size: 38,
                      color: AppColors.secondary,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            group.name,
            textAlign: TextAlign.center,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 22,
              fontWeight: AppTheme.extraBold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${group.memberCount} members',
            textAlign: TextAlign.center,
            style: AppTheme.greyTextStyle,
          ),
          if (group.description.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              group.description,
              style: AppTheme.blackTextStyle.copyWith(height: 1.45),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Members',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 16,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (members.isEmpty)
            Text(
              'Members are not loaded yet.',
              style: AppTheme.greyTextStyle,
            )
          else
            ...members.map((member) => _MemberTile(member: member)),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final CommunityMemberModel member;

  const _MemberTile({
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    final user = member.user;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.12),
        backgroundImage: user.avatar.isNotEmpty
            ? appNetworkImageProvider(
                context,
                user.avatar,
                logicalWidth: 40,
              )
            : null,
        child: user.avatar.isEmpty
            ? Text(
                user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary),
              )
            : null,
      ),
      title: Text(
        user.name,
        style: AppTheme.blackTextStyle.copyWith(
          fontWeight: AppTheme.semiBold,
        ),
      ),
      subtitle: Text(
        member.role,
        style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
      ),
    );
  }
}
