import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/profile/gallery_profile_cubit.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/models/gallery_model.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:clique/ui/widgets/post/normal-post/repost_card.dart';

enum ProfileGalleryTabType {
  posts,
  media,
}

class ProfileGalleryTab extends StatelessWidget {
  final int userId;
  final ProfileGalleryTabType type;
  final VoidCallback onLoadMore;

  const ProfileGalleryTab({
    super.key,
    required this.userId,
    required this.type,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GalleryProfileCubit, GalleryProfileState>(
      builder: (context, state) {
        if (state is GalleryProfileLoading) {
          return const ProfileLoadingState();
        }

        if (state is GalleryProfileLoaded) {
          final items = state.galleryProfiles;
          return type == ProfileGalleryTabType.posts
              ? ProfilePostsTab(
                  items: items,
                  hasMore: state.hasMore,
                  isLoadingMore: state.isLoadingMore,
                  onLoadMore: onLoadMore,
                )
              : ProfileMediaGrid(
                  items: items,
                  hasMore: state.hasMore,
                  isLoadingMore: state.isLoadingMore,
                  onLoadMore: onLoadMore,
                );
        }

        if (state is GalleryProfileLoadingMore) {
          final items = state.currentProfiles;
          return type == ProfileGalleryTabType.posts
              ? ProfilePostsTab(
                  items: items,
                  hasMore: true,
                  isLoadingMore: true,
                  onLoadMore: onLoadMore,
                )
              : ProfileMediaGrid(
                  items: items,
                  hasMore: true,
                  isLoadingMore: true,
                  onLoadMore: onLoadMore,
                );
        }

        if (state is GalleryProfileError) {
          return ProfileErrorState(
            message: state.message,
            onRetry: () {
              context.read<GalleryProfileCubit>().getUserMedia(
                    userId: userId,
                    type: null,
                    page: 1,
                  );
            },
          );
        }

        return const ProfileLoadingState();
      },
    );
  }
}

class ProfileSavedPostsTab extends StatefulWidget {
  const ProfileSavedPostsTab({super.key});

  @override
  State<ProfileSavedPostsTab> createState() => _ProfileSavedPostsTabState();
}

class _ProfileSavedPostsTabState extends State<ProfileSavedPostsTab> {
  final FeedService _feedService = FeedService();
  List<FeedPost> _savedPosts = const [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedPosts());
  }

  Future<void> _loadSavedPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isRefreshing = true;
        _error = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await _feedService.getSavedPosts(
        page: 1,
        forceRefresh: refresh,
      );

      if (!mounted) return;

      setState(() {
        _savedPosts = response.posts;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _savedPosts.isEmpty) {
      return const ProfileLoadingState();
    }

    if (_error != null && _savedPosts.isEmpty) {
      return ProfileEmptyState(
        icon: Icons.bookmark_border_rounded,
        message: 'Could not load saved posts',
        subtitle: _error!,
      );
    }

    if (_savedPosts.isEmpty) {
      return ProfileEmptyState(
        icon: Icons.bookmark_border_rounded,
        message: 'No saved posts yet',
        subtitle: 'Tap bookmark on a post to keep it here.',
        actionText: 'Refresh',
        onAction: () => _loadSavedPosts(refresh: true),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadSavedPosts(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: _savedPosts.length + (_isRefreshing ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _savedPosts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          }

          return RepostCard(
            post: _savedPosts[index],
            isDetailView: false,
          );
        },
      ),
    );
  }
}

class ProfileInsightsTab extends StatelessWidget {
  final VoidCallback? onOpenInsights;

  const ProfileInsightsTab({
    super.key,
    this.onOpenInsights,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.18),
                      AppColors.secondary.withOpacity(0.16),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Profile insights',
                style: AppTheme.blackTextStyle.copyWith(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track how your profile performs, see engagement trends, and review audience activity.',
                style: AppTheme.greyTextStyle.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (onOpenInsights != null) {
                    onOpenInsights!();
                    return;
                  }
                  Navigator.pushNamed(context, NamedRoutes.insightsScreen);
                },
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text('Open insights'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InsightHint(
          icon: Icons.show_chart_rounded,
          title: 'Engagement trends',
          subtitle: 'See how views, reach, and interactions move over time.',
        ),
        const SizedBox(height: 12),
        _InsightHint(
          icon: Icons.people_alt_rounded,
          title: 'Audience breakdown',
          subtitle:
              'Review the profile visitors and follower mix behind the numbers.',
        ),
      ],
    );
  }
}

class _InsightHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InsightHint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.blackTextStyle.copyWith(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.greyTextStyle.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePostsTab extends StatelessWidget {
  final List<GalleryModel> items;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const ProfilePostsTab({
    super.key,
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !isLoadingMore) {
      return const ProfileEmptyState(
        icon: Icons.article_outlined,
        message: 'No posts yet',
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!hasMore || isLoadingMore) return false;
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 350) {
          onLoadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.78,
        ),
        itemCount: items.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            );
          }
          return ProfileGalleryTile(
              gallery: items[index], isVideo: items[index].type == 'video');
        },
      ),
    );
  }
}

class ProfileMediaGrid extends StatelessWidget {
  final List<GalleryModel> items;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const ProfileMediaGrid({
    super.key,
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !isLoadingMore) {
      return const ProfileEmptyState(
        icon: Icons.perm_media_outlined,
        message: 'No media yet',
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!hasMore || isLoadingMore) return false;
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 350) {
          onLoadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        physics: const BouncingScrollPhysics(),
        cacheExtent: 800,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.84,
        ),
        itemCount: items.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            );
          }
          return ProfileGalleryTile(
            gallery: items[index],
            isVideo: items[index].type == 'video',
          );
        },
      ),
    );
  }
}

class ProfileGalleryTile extends StatelessWidget {
  final GalleryModel gallery;
  final bool isVideo;

  const ProfileGalleryTile({
    super.key,
    required this.gallery,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: gallery.image,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(color: AppColors.greyColor.withOpacity(0.12)),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.greyColor.withOpacity(0.12),
              child:
                  Icon(Icons.broken_image_outlined, color: AppColors.greyColor),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x55000000)],
              ),
            ),
          ),
          if (isVideo)
            const Positioned(
              top: 10,
              right: 10,
              child: ProfileBadge(icon: Icons.play_arrow),
            ),
          Positioned(
            bottom: 10,
            left: 10,
            child: ProfileBadge(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: AppColors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    gallery.like,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (gallery.caption?.isNotEmpty == true)
            Positioned(
              left: 10,
              right: isVideo ? 48 : 10,
              bottom: 30,
              child: ProfileBadge(
                child: Text(
                  gallery.caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileLoadingState extends StatelessWidget {
  const ProfileLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2,
      ),
    );
  }
}

class ProfileEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const ProfileEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.greyColor.withOpacity(0.55)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProfileErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ProfileErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.greyColor),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTheme.greyTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileBadge extends StatelessWidget {
  final IconData? icon;
  final Widget? child;

  const ProfileBadge({
    super.key,
    this.icon,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.48),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child ??
          Icon(
            icon,
            color: AppColors.white,
            size: 16,
          ),
    );
  }
}
