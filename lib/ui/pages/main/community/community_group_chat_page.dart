import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/community/community_bloc.dart';
import 'package:clique/core/models/community_model.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/ui/widgets/community/community_discussion_card.dart';

class CommunityGroupChatPage extends StatefulWidget {
  final CommunityGroupModel group;

  const CommunityGroupChatPage({
    super.key,
    required this.group,
  });

  @override
  State<CommunityGroupChatPage> createState() => _CommunityGroupChatPageState();
}

class _CommunityGroupChatPageState extends State<CommunityGroupChatPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<CommunityBloc>()
          .add(LoadCommunityGroupPosts(widget.group.id));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        final posts = state.posts
            .where((post) => post.groupId == widget.group.id)
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.card,
            elevation: 0,
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: AppTheme.bold,
                  ),
                ),
                Text(
                  '${widget.group.memberCount} members',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    NamedRoutes.communityGroupInfoScreen,
                    arguments: {
                      'group': widget.group,
                      'members': state.members,
                    },
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: posts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No group messages yet',
                            style: AppTheme.greyTextStyle,
                          ),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          return CommunityDiscussionCard(
                            post: posts[index],
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border(
                      top: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          style: AppTheme.blackTextStyle,
                          decoration: InputDecoration(
                            hintText: 'Message ${widget.group.name}',
                            hintStyle: AppTheme.greyTextStyle,
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<CommunityBloc>().add(
          CreateCommunityDiscussion(
            communityId: widget.group.communityId,
            content: text,
            groupId: widget.group.id,
          ),
        );
    _controller.clear();
  }
}
