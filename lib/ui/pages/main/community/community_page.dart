import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/community/community_bloc.dart';
import 'package:clique/core/models/community_model.dart';
import 'package:clique/ui/pages/main/community/community_detail_page.dart';
import 'package:clique/ui/pages/main/community/create_community_page.dart';
import 'package:clique/ui/widgets/community/community_card.dart';
import 'package:clique/ui/widgets/community/community_empty_state.dart';
import 'package:clique/ui/widgets/community/community_list_header.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';

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
      listenWhen: (previous, current) =>
          previous.error != current.error ||
          previous.actionStatus != current.actionStatus,
      listener: _handleStateChange,
      builder: (context, state) {
        final communities = _filteredCommunities(state.communities);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              AppPageHeader(
                title: 'Spaces',
                subtitle: state.invitations.isEmpty
                    ? 'Find focused groups'
                    : '${state.invitations.length} invitation${state.invitations.length == 1 ? '' : 's'} waiting',
                leadingIcon: Icons.diversity_3_outlined,
                actionIcon: Icons.add_rounded,
                onActionTap: _openCreateCommunity,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<CommunityBloc>().add(const LoadCommunities());
                    await Future<void>.delayed(
                      const Duration(milliseconds: 350),
                    );
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: CommunityListHeader(
                          searchController: _searchController,
                          category: _category,
                          communityCount: communities.length,
                          memberCount: communities.fold<int>(
                            0,
                            (total, community) => total + community.memberCount,
                          ),
                          onCategoryChanged: _changeCategory,
                          onSearch: _search,
                        ),
                      ),
                      if (state.status == CommunityStatus.loading &&
                          state.communities.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (communities.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: CommunityEmptyState(
                            icon: Icons.diversity_3_outlined,
                            title: 'No spaces found',
                            message:
                                'Create a space for shared interests, focused groups, and useful discussions.',
                            actionLabel: 'Create space',
                            onAction: _openCreateCommunity,
                          ),
                        )
                      else
                        _CommunityList(
                          communities: communities,
                          onOpen: _openCommunity,
                          onJoin: _joinCommunity,
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

  void _handleStateChange(BuildContext context, CommunityState state) {
    final error = state.error;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.read<CommunityBloc>().add(const ClearCommunityError());
      return;
    }

    if (state.actionStatus == CommunityActionStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Community updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _changeCategory(String category) {
    setState(() => _category = category);
    context.read<CommunityBloc>().add(
          SearchCommunities(
            query: _searchController.text.trim(),
            category: category,
          ),
        );
  }

  void _search() {
    context.read<CommunityBloc>().add(
          SearchCommunities(
            query: _searchController.text.trim(),
            category: _category,
          ),
        );
  }

  List<CommunityModel> _filteredCommunities(List<CommunityModel> communities) {
    final query = _searchController.text.trim().toLowerCase();
    final category = _category.trim().toLowerCase();

    return communities.where((community) {
      final matchesCategory =
          category.isEmpty || community.category.toLowerCase() == category;
      final matchesQuery = query.isEmpty ||
          community.name.toLowerCase().contains(query) ||
          community.description.toLowerCase().contains(query) ||
          community.category.toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _openCreateCommunity() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CommunityBloc>(),
          child: const CreateCommunityPage(),
        ),
      ),
    );
  }

  void _openCommunity(CommunityModel community) {
    HapticFeedback.selectionClick();
    context.read<CommunityBloc>().add(SelectCommunity(community.id));
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

  void _joinCommunity(CommunityModel community) {
    HapticFeedback.lightImpact();
    context.read<CommunityBloc>().add(JoinCommunity(community.id));
  }
}

class _CommunityList extends StatelessWidget {
  final List<CommunityModel> communities;
  final ValueChanged<CommunityModel> onOpen;
  final ValueChanged<CommunityModel> onJoin;

  const _CommunityList({
    required this.communities,
    required this.onOpen,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
      sliver: SliverList.separated(
        itemBuilder: (context, index) {
          final community = communities[index];
          return CommunityCard(
            community: community,
            onTap: () => onOpen(community),
            onJoin: () => onJoin(community),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: communities.length,
      ),
    );
  }
}
