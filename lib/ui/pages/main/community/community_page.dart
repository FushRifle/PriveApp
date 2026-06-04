import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/community/community_bloc.dart';
import 'package:clique/data/models/community_model.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _initialized = false;
  String _category = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialized || !mounted) return;
      _initialized = true;
      context.read<CommunityBloc>().add(const LoadCommunities());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocConsumer<CommunityBloc, CommunityState>(
      listenWhen: (previous, current) => previous.error != current.error,
      listener: (context, state) {
        final error = state.error;
        if (error == null || error.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<CommunityBloc>().add(const ClearCommunityError());
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context.read<CommunityBloc>().add(const LoadCommunities());
                await Future<void>.delayed(const Duration(milliseconds: 350));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      searchController: _searchController,
                      category: _category,
                      invitationCount: state.invitations.length,
                      onCategoryChanged: (category) {
                        setState(() => _category = category);
                        context.read<CommunityBloc>().add(SearchCommunities(
                              query: _searchController.text.trim(),
                              category: category,
                            ));
                      },
                      onSearch: () {
                        context.read<CommunityBloc>().add(SearchCommunities(
                              query: _searchController.text.trim(),
                              category: _category,
                            ));
                      },
                      onCreate: () => _openCreateCommunity(context),
                    ),
                  ),
                  if (state.status == CommunityStatus.loading &&
                      state.communities.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.communities.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyCommunities(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                      sliver: SliverList.separated(
                        itemBuilder: (context, index) {
                          final community = state.communities[index];
                          return _CommunityCard(
                            community: community,
                            onTap: () => _openCommunity(context, community.id),
                            onJoin: () {
                              HapticFeedback.lightImpact();
                              context
                                  .read<CommunityBloc>()
                                  .add(JoinCommunity(community.id));
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: state.communities.length,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreateCommunity(BuildContext context) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CommunityBloc>(),
        child: const _CreateCommunitySheet(),
      ),
    );
  }

  void _openCommunity(BuildContext context, int communityId) {
    HapticFeedback.selectionClick();
    context.read<CommunityBloc>().add(SelectCommunity(communityId));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CommunityBloc>(),
          child: const CommunityDetailPage(),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TextEditingController searchController;
  final String category;
  final int invitationCount;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSearch;
  final VoidCallback onCreate;

  const _Header({
    required this.searchController,
    required this.category,
    required this.invitationCount,
    required this.onCategoryChanged,
    required this.onSearch,
    required this.onCreate,
  });

  static const _categories = [
    '',
    'Creators',
    'Dating',
    'Lifestyle',
    'Music',
    'Tech',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Communities',
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 28,
                        fontWeight: AppTheme.extraBold,
                      ),
                    ),
                    Text(
                      invitationCount == 0
                          ? 'Discover spaces and focused groups'
                          : '$invitationCount group invitation${invitationCount == 1 ? '' : 's'} waiting',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: onCreate,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                icon: const Icon(Icons.add),
                tooltip: 'Create community',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Search communities',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune),
                onPressed: onSearch,
                tooltip: 'Search',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final item = _categories[index];
                final selected = item == category;
                return ChoiceChip(
                  selected: selected,
                  label: Text(item.isEmpty ? 'All' : item),
                  onSelected: (_) => onCategoryChanged(item),
                  selectedColor: AppColors.primary.withOpacity(0.18),
                  backgroundColor: AppColors.card,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.text,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _categories.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const _CommunityCard({
    required this.community,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CommunityMark(
                      name: community.name, imageUrl: community.imageUrl),
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
                            if (community.isPrivate)
                              const Icon(Icons.lock, size: 16),
                          ],
                        ),
                        if (community.category.isNotEmpty)
                          Text(
                            community.category,
                            style: AppTheme.greyTextStyle.copyWith(
                              fontSize: 12,
                              fontWeight: AppTheme.semiBold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
              const SizedBox(height: 14),
              Row(
                children: [
                  _Metric(
                    icon: Icons.people_alt_outlined,
                    label: '${community.memberCount} members',
                  ),
                  const SizedBox(width: 14),
                  _Metric(
                    icon: Icons.forum_outlined,
                    label: '${community.groupCount} groups',
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
    return BlocBuilder<CommunityBloc, CommunityState>(
      builder: (context, state) {
        final community = state.selectedCommunity;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(community?.name ?? 'Community'),
            actions: [
              if (community?.isMember == true)
                IconButton(
                  onPressed: () => _openCreateGroup(context, community!.id),
                  icon: const Icon(Icons.group_add_outlined),
                  tooltip: 'Create group',
                ),
            ],
          ),
          body: community == null ||
                  state.detailStatus == CommunityStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _DetailHero(
                      community: community,
                      onJoin: () => context
                          .read<CommunityBloc>()
                          .add(JoinCommunity(community.id)),
                      onLeave: () => context
                          .read<CommunityBloc>()
                          .add(LeaveCommunity(community.id)),
                    ),
                    const SizedBox(height: 16),
                    if (community.isMember) ...[
                      _SectionTitle(
                        title: 'Groups',
                        actionLabel: 'Create',
                        onAction: () => _openCreateGroup(context, community.id),
                      ),
                      const SizedBox(height: 8),
                      if (state.groups.isEmpty)
                        const _InlineEmpty(
                          icon: Icons.groups_2_outlined,
                          title: 'No groups yet',
                          message: 'Create the first focused space.',
                        )
                      else
                        ...state.groups.map(
                          (group) => _GroupRow(
                            group: group,
                            onJoin: () => context
                                .read<CommunityBloc>()
                                .add(JoinCommunityGroup(group.id)),
                          ),
                        ),
                      const SizedBox(height: 18),
                      _SectionTitle(title: 'Discussions'),
                      const SizedBox(height: 8),
                      _Composer(
                        controller: _postController,
                        onPost: () {
                          final content = _postController.text.trim();
                          if (content.isEmpty) return;
                          context.read<CommunityBloc>().add(
                                CreateCommunityDiscussion(
                                  communityId: community.id,
                                  content: content,
                                ),
                              );
                          _postController.clear();
                        },
                      ),
                      const SizedBox(height: 12),
                      if (state.posts.isEmpty)
                        const _InlineEmpty(
                          icon: Icons.chat_bubble_outline,
                          title: 'No discussions yet',
                          message: 'Start a useful conversation.',
                        )
                      else
                        ...state.posts
                            .map((post) => _DiscussionCard(post: post)),
                    ] else
                      const _InlineEmpty(
                        icon: Icons.lock_open_outlined,
                        title: 'Join to participate',
                        message:
                            'Members can view groups and join discussions.',
                      ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _openCreateGroup(BuildContext context, int communityId) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CommunityBloc>(),
        child: _CreateGroupSheet(communityId: communityId),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const _DetailHero({
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CommunityMark(
                name: community.name,
                imageUrl: community.imageUrl,
                size: 64,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 20,
                        fontWeight: AppTheme.extraBold,
                      ),
                    ),
                    Text(
                      '${community.memberCount} members • ${community.groupCount} groups',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
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
              style: AppTheme.greyTextStyle.copyWith(height: 1.4),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: community.isMember ? onLeave : onJoin,
              icon: Icon(community.isMember ? Icons.logout : Icons.login),
              label: Text(
                  community.isMember ? 'Leave community' : 'Join community'),
              style: FilledButton.styleFrom(
                backgroundColor: community.isMember
                    ? AppColors.textSecondary
                    : AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final CommunityGroupModel group;
  final VoidCallback onJoin;

  const _GroupRow({
    required this.group,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.secondary.withOpacity(0.18),
            child:
                const Icon(Icons.groups_2_outlined, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                  ),
                ),
                Text(
                  '${group.memberCount} members',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: group.isMember ? null : onJoin,
            child: Text(group.isMember ? 'Joined' : 'Join'),
          ),
        ],
      ),
    );
  }
}

class _DiscussionCard extends StatelessWidget {
  final DiscussionPostModel post;

  const _DiscussionCard({required this.post});

  @override
  Widget build(BuildContext context) {
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
            backgroundImage: post.author?.avatar.isNotEmpty == true
                ? CachedNetworkImageProvider(post.author!.avatar)
                : null,
            child: post.author?.avatar.isNotEmpty == true
                ? null
                : Text((post.author?.name.isNotEmpty == true
                    ? post.author!.name[0]
                    : 'U')),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author?.name ?? 'Member',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.semiBold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post.content,
                  style: AppTheme.blackTextStyle.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPost;

  const _Composer({
    required this.controller,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Start a discussion',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          IconButton.filled(
            onPressed: onPost,
            icon: const Icon(Icons.send),
            tooltip: 'Post',
          ),
        ],
      ),
    );
  }
}

class _CreateCommunitySheet extends StatefulWidget {
  const _CreateCommunitySheet();

  @override
  State<_CreateCommunitySheet> createState() => _CreateCommunitySheetState();
}

class _CreateCommunitySheetState extends State<_CreateCommunitySheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _isPrivate = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Create community',
      actionLabel: 'Create',
      onAction: () {
        final name = _nameController.text.trim();
        if (name.length < 3) return;
        context.read<CommunityBloc>().add(CreateCommunity(
              name: name,
              description: _descriptionController.text.trim(),
              category: _categoryController.text.trim(),
              isPrivate: _isPrivate,
            ));
        Navigator.pop(context);
      },
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Private community'),
            value: _isPrivate,
            onChanged: (value) => setState(() => _isPrivate = value),
          ),
        ],
      ),
    );
  }
}

class _CreateGroupSheet extends StatefulWidget {
  final int communityId;

  const _CreateGroupSheet({required this.communityId});

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPrivate = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Create group',
      actionLabel: 'Create',
      onAction: () {
        final name = _nameController.text.trim();
        if (name.length < 3) return;
        context.read<CommunityBloc>().add(CreateCommunityGroup(
              communityId: widget.communityId,
              name: name,
              description: _descriptionController.text.trim(),
              isPrivate: _isPrivate,
            ));
        Navigator.pop(context);
      },
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Private group'),
            value: _isPrivate,
            onChanged: (value) => setState(() => _isPrivate = value),
          ),
        ],
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  const _SheetFrame({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.blackTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: AppTheme.bold,
                    ),
                  ),
                ),
                TextButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _CommunityMark extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double size;

  const _CommunityMark({
    required this.name,
    required this.imageUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.16),
        borderRadius: BorderRadius.circular(8),
        image: imageUrl.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl.isNotEmpty
          ? null
          : Center(
              child: Text(
                name.isEmpty ? 'C' : name.characters.first.toUpperCase(),
                style: AppTheme.blackTextStyle.copyWith(
                  color: AppColors.secondary,
                  fontWeight: AppTheme.extraBold,
                  fontSize: size * 0.42,
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
          side: BorderSide(
              color: isMember ? AppColors.primary : AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(isMember ? 'Open' : 'Join'),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Metric({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 17,
              fontWeight: AppTheme.bold,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: AppTheme.bold,
            ),
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyCommunities extends StatelessWidget {
  const _EmptyCommunities();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.diversity_3_outlined,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'No communities yet',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 18,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a space for shared interests, groups, and discussions.',
            textAlign: TextAlign.center,
            style: AppTheme.greyTextStyle,
          ),
        ],
      ),
    );
  }
}
