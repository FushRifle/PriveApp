import 'package:cirqle/app/resources/constant/named_routes.dart';
import 'package:cirqle/bloc/status/stories_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cirqle/app/configs/colors.dart';
import 'package:cirqle/app/configs/theme.dart';
import 'package:cirqle/data/models/status_model.dart';
import './status_view_page.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key, required List<dynamic> stories});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StoriesBloc>().add(GetStories());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Stories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, NamedRoutes.createStatusScreen);
            },
            child: const Text('Create'),
          ),
        ],
      ),
      body: BlocBuilder<StoriesBloc, StoriesState>(
        builder: (context, state) {
          return _buildBody(state);
        },
      ),
    );
  }

  Widget _buildBody(StoriesState state) {
    final stories = state.stories;
    final isLoading = state.status == StoriesStatus.loading;
    final error = state.error;

    if (isLoading && stories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (error != null && stories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.greyColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load stories',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<StoriesBloc>().add(GetStories());
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 48),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (stories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store,
              size: 64,
              color: AppColors.greyColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No stories yet',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'When friends add stories, they\'ll appear here',
              style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, NamedRoutes.createStatusScreen);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 48),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Create Your First Story'),
            ),
          ],
        ),
      );
    }

    final groupedStories = _groupStoriesByUser(stories);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<StoriesBloc>().add(GetStories());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: groupedStories.length,
        itemBuilder: (context, index) {
          final group = groupedStories[index];
          return _buildStoryListItem(group);
        },
      ),
    );
  }

  List<_StoryGroup> _groupStoriesByUser(List<Story> stories) {
    final Map<int, List<Story>> grouped = {};

    for (final story in stories) {
      if (!grouped.containsKey(story.userId)) {
        grouped[story.userId] = [];
      }
      grouped[story.userId]!.add(story);
    }

    final List<_StoryGroup> groups = [];

    grouped.forEach((userId, userStories) {
      userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final firstStory = userStories.first;

      groups.add(_StoryGroup(
        userId: userId,
        user: firstStory.user,
        stories: userStories,
        hasUnseen: userStories.any((s) => !s.isSeen),
        latestStory: firstStory.createdAt,
      ));
    });

    // Sort: unviewed first, then by latest story
    groups.sort((a, b) {
      if (a.hasUnseen && !b.hasUnseen) return -1;
      if (!a.hasUnseen && b.hasUnseen) return 1;
      return b.latestStory.compareTo(a.latestStory);
    });

    return groups;
  }

  Widget _buildStoryListItem(_StoryGroup group) {
    return ListTile(
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: group.hasUnseen
              ? LinearGradient(
                  colors: [AppColors.primary, Colors.purple.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: !group.hasUnseen
              ? Border.all(color: Colors.grey.shade300, width: 1)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: _buildAvatar(group.user.avatar),
          ),
        ),
      ),
      title: Text(
        group.user.name,
        style: TextStyle(
          fontWeight: group.hasUnseen ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        group.hasUnseen
            ? 'Tap to view'
            : 'Viewed ${_formatTimeAgo(group.latestStory)}',
        style: TextStyle(
          color: group.hasUnseen ? AppColors.primary : Colors.grey.shade600,
          fontWeight: group.hasUnseen ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: group.stories.length > 1
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${group.stories.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
      onTap: () {
        HapticFeedback.lightImpact();
        // Mark stories as seen when tapped
        for (final story in group.stories) {
          if (!story.isSeen && mounted) {
            context.read<StoriesBloc>().add(MarkStorySeen(storyId: story.id));
          }
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatusViewPage(
              stories: group.stories,
              initialIndex: 0,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String avatarUrl) {
    if (avatarUrl.isEmpty) {
      return Container(
        color: Colors.grey,
        child: const Icon(Icons.person, color: Colors.white, size: 30),
      );
    }

    if (avatarUrl.startsWith('http')) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey,
          child: const Icon(Icons.person, color: Colors.white, size: 30),
        ),
      );
    }

    return Image.asset(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey,
        child: const Icon(Icons.person, color: Colors.white, size: 30),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

class _StoryGroup {
  final int userId;
  final StoryUser user;
  final List<Story> stories;
  final bool hasUnseen;
  final DateTime latestStory;

  _StoryGroup({
    required this.userId,
    required this.user,
    required this.stories,
    required this.hasUnseen,
    required this.latestStory,
  });
}
