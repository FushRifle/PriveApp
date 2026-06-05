import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

import 'package:clique/bloc/status/stories_bloc.dart';

import 'package:clique/core/models/status_model.dart';

import './create_status_page.dart';
import './status_view_page.dart';

class StatusPage extends StatefulWidget {
  final List<dynamic>? stories;

  const StatusPage({
    super.key,
    this.stories,
  });

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStories();
    });
  }

  void _loadStories() {
    if (_initialized) return;

    _initialized = true;

    context.read<StoriesBloc>().add(GetStories());
  }

  Future<void> _refresh() async {
    context.read<StoriesBloc>().add(GetStories());

    await Future<void>.delayed(
      const Duration(milliseconds: 450),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Stories',
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton.filled(
                onPressed: () {
                  HapticFeedback.lightImpact();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<StoriesBloc>(),
                        child: const CreateStatusPage(),
                      ),
                    ),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<StoriesBloc, StoriesState>(
          buildWhen: (previous, current) {
            return previous.status != current.status ||
                previous.stories != current.stories ||
                previous.error != current.error;
          },
          builder: (context, state) {
            return _StatusBody(
              state: state,
              onRefresh: _refresh,
            );
          },
        ),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  final StoriesState state;
  final Future<void> Function() onRefresh;

  const _StatusBody({
    required this.state,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final stories = state.stories;
    final isLoading = state.status == StoriesStatus.loading;
    final error = state.error;

    if (isLoading && stories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (error != null && stories.isEmpty) {
      return _StatusError(
        error: error,
        onRetry: () {
          context.read<StoriesBloc>().add(GetStories());
        },
      );
    }

    if (stories.isEmpty) {
      return const _EmptyStories();
    }

    final groupedStories = _groupStoriesByUser(stories);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _CreateStoryBanner(
              onTap: () {
                HapticFeedback.lightImpact();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<StoriesBloc>(),
                      child: const CreateStatusPage(),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            sliver: SliverList.separated(
              itemCount: groupedStories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final group = groupedStories[index];

                return _StoryListItem(
                  group: group,
                  onTap: () {
                    HapticFeedback.lightImpact();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) {
                          return StatusViewPage(
                            stories: group.stories,
                            initialIndex: 0,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_StoryGroup> _groupStoriesByUser(List<Story> stories) {
    final grouped = <int, List<Story>>{};

    for (final story in stories) {
      grouped.putIfAbsent(story.userId, () => []);
      grouped[story.userId]!.add(story);
    }

    final groups = grouped.entries.map((entry) {
      final userStories = [...entry.value];

      userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final firstStory = userStories.first;

      return _StoryGroup(
        userId: entry.key,
        user: firstStory.user,
        stories: userStories,
        hasUnseen: userStories.any((story) => !story.isSeen),
        latestStory: firstStory.createdAt,
      );
    }).toList();

    groups.sort((a, b) {
      if (a.hasUnseen && !b.hasUnseen) return -1;
      if (!a.hasUnseen && b.hasUnseen) return 1;

      return b.latestStory.compareTo(a.latestStory);
    });

    return groups;
  }
}

class _CreateStoryBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateStoryBanner({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Material(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorderColor),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowElevated,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create a story',
                        style: AppTheme.blackTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share a moment with your Clique',
                        style: AppTheme.greyTextStyle.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryListItem extends StatelessWidget {
  final _StoryGroup group;
  final VoidCallback onTap;

  const _StoryListItem({
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowElevated,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _StoryAvatar(
                avatar: group.user.avatar,
                name: group.user.name,
                hasUnseen: group.hasUnseen,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StoryInfo(group: group),
              ),
              if (group.stories.length > 1)
                _StoryCount(count: group.stories.length),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary.withOpacity(0.65),
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String avatar;
  final String name;
  final bool hasUnseen;

  const _StoryAvatar({
    required this.avatar,
    required this.name,
    required this.hasUnseen,
  });

  @override
  Widget build(BuildContext context) {
    final fallback =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasUnseen
            ? const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.purple,
                ],
              )
            : null,
        border: hasUnseen
            ? null
            : Border.all(
                color: AppColors.cardBorderColor,
                width: 1.3,
              ),
      ),
      padding: const EdgeInsets.all(2.6),
      child: ClipOval(
        child: avatar.isNotEmpty && avatar.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: avatar,
                fit: BoxFit.cover,
                placeholder: (_, __) => _fallback(fallback),
                errorWidget: (_, __, ___) => _fallback(fallback),
              )
            : avatar.isNotEmpty
                ? Image.asset(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(fallback),
                  )
                : _fallback(fallback),
      ),
    );
  }

  Widget _fallback(String text) {
    return Container(
      color: AppColors.primary.withOpacity(0.12),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _StoryInfo extends StatelessWidget {
  final _StoryGroup group;

  const _StoryInfo({
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: group.hasUnseen ? FontWeight.w900 : FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          group.hasUnseen
              ? 'Tap to view'
              : 'Viewed ${_formatTimeAgo(group.latestStory)}',
          style: AppTheme.greyTextStyle.copyWith(
            color:
                group.hasUnseen ? AppColors.primary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: group.hasUnseen ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) return '${difference.inDays ~/ 7}w ago';
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';

    return 'just now';
  }
}

class _StoryCount extends StatelessWidget {
  final int count;

  const _StoryCount({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 28,
        minHeight: 28,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _StatusError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 66,
              color: AppColors.greyColor.withOpacity(0.55),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load stories',
              style: AppTheme.blackTextStyle.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(130, 48),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStories extends StatelessWidget {
  const _EmptyStories();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 70,
              color: AppColors.greyColor.withOpacity(0.55),
            ),
            const SizedBox(height: 16),
            Text(
              'No stories yet',
              style: AppTheme.blackTextStyle.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When friends add stories, they’ll appear here.',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<StoriesBloc>(),
                      child: const CreateStatusPage(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 48),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Create Story'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryGroup {
  final int userId;
  final StoryUser user;
  final List<Story> stories;
  final bool hasUnseen;
  final DateTime latestStory;

  const _StoryGroup({
    required this.userId,
    required this.user,
    required this.stories,
    required this.hasUnseen,
    required this.latestStory,
  });
}
