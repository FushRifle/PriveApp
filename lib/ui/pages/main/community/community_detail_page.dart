import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/community/community_bloc.dart';
import 'package:clique/core/models/community_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/ui/widgets/community/community_composer.dart';
import 'package:clique/ui/widgets/community/community_detail_hero.dart';
import 'package:clique/ui/widgets/community/community_discussion_card.dart';
import 'package:clique/ui/widgets/community/community_empty_state.dart';
import 'package:clique/ui/widgets/community/community_group_row.dart';
import 'package:clique/ui/widgets/community/community_section_title.dart';
import 'package:clique/ui/widgets/community/create_group_sheet.dart';

class CommunityDetailPage extends StatefulWidget {
  const CommunityDetailPage({super.key});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  final TextEditingController _postController = TextEditingController();

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommunityBloc, CommunityState>(
      listenWhen: (previous, current) => previous.error != current.error,
      listener: _showError,
      builder: (context, state) {
        final community = state.selectedCommunity;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: Text(community?.name ?? 'Community'),
            actions: [
              if (community?.isMember == true)
                IconButton(
                  onPressed: () => _openCreateGroup(community!.id),
                  icon: const Icon(Icons.group_add_outlined),
                  tooltip: 'Create group',
                ),
            ],
          ),
          body: community == null ||
                  state.detailStatus == CommunityStatus.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context
                        .read<CommunityBloc>()
                        .add(SelectCommunity(community.id));
                    await Future<void>.delayed(
                      const Duration(milliseconds: 350),
                    );
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      CommunityDetailHero(
                        community: community,
                        onJoin: () => context
                            .read<CommunityBloc>()
                            .add(JoinCommunity(community.id)),
                        onLeave: () => context
                            .read<CommunityBloc>()
                            .add(LeaveCommunity(community.id)),
                      ),
                      const SizedBox(height: 18),
                      if (community.isMember)
                        _MemberContent(
                          communityId: community.id,
                          postController: _postController,
                          state: state,
                          onCreateGroup: () => _openCreateGroup(community.id),
                          onPost: _postDiscussion,
                        )
                      else
                        const CommunityInlineEmpty(
                          icon: Icons.lock_open_outlined,
                          title: 'Join to participate',
                          message:
                              'Members can view groups and take part in discussions.',
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  void _showError(BuildContext context, CommunityState state) {
    final error = state.error;
    if (error == null || error.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
    context.read<CommunityBloc>().add(const ClearCommunityError());
  }

  Future<void> _openCreateGroup(int communityId) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CommunityBloc>(),
        child: CreateGroupSheet(communityId: communityId),
      ),
    );
  }

  void _postDiscussion(int communityId) {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    context.read<CommunityBloc>().add(
          CreateCommunityDiscussion(
            communityId: communityId,
            content: content,
          ),
        );
    _postController.clear();
  }
}

class _MemberContent extends StatelessWidget {
  final int communityId;
  final TextEditingController postController;
  final CommunityState state;
  final VoidCallback onCreateGroup;
  final ValueChanged<int> onPost;

  const _MemberContent({
    required this.communityId,
    required this.postController,
    required this.state,
    required this.onCreateGroup,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunitySectionTitle(
          title: 'Groups',
          actionLabel: 'Create',
          onAction: onCreateGroup,
        ),
        const SizedBox(height: 8),
        if (state.groups.isEmpty)
          const CommunityInlineEmpty(
            icon: Icons.groups_2_outlined,
            title: 'No groups yet',
            message: 'Create the first focused room in this community.',
          )
        else
          ...state.groups.map(
            (group) => CommunityGroupRow(
              group: group,
              onJoin: () => context
                  .read<CommunityBloc>()
                  .add(JoinCommunityGroup(group.id)),
            ),
          ),
        const SizedBox(height: 18),
        const CommunitySectionTitle(title: 'Members'),
        const SizedBox(height: 8),
        if (state.members.isEmpty)
          const CommunityInlineEmpty(
            icon: Icons.people_alt_outlined,
            title: 'No members loaded',
            message: 'Pull to refresh this community.',
          )
        else
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.members.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final member = state.members[index];
                return _MemberChip(member: member);
              },
            ),
          ),
        const SizedBox(height: 18),
        const CommunitySectionTitle(title: 'Discussions'),
        const SizedBox(height: 8),
        CommunityComposer(
          controller: postController,
          onPost: () => onPost(communityId),
        ),
        const SizedBox(height: 12),
        if (state.posts.isEmpty)
          const CommunityInlineEmpty(
            icon: Icons.chat_bubble_outline,
            title: 'No discussions yet',
            message: 'Start a useful conversation for the group.',
          )
        else
          ...state.posts.map(
            (post) => CommunityDiscussionCard(post: post),
          ),
      ],
    );
  }
}

class _MemberChip extends StatelessWidget {
  final CommunityMemberModel member;

  const _MemberChip({
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    final user = member.user;
    final initials = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return SizedBox(
      width: 82,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: user.avatar.isNotEmpty
                ? CachedNetworkImageProvider(user.avatar)
                : null,
            child: user.avatar.isEmpty
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            member.role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
