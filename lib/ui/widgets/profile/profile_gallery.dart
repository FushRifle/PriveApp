import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/profile/gallery_profile_cubit.dart';
import 'package:clique/core/models/gallery_model.dart';
import 'package:clique/ui/widgets/post/normal-post/post_card.dart';

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
  int _lastRequestedPostCount = -1;

  FeedBloc? _feedBlocOrNull(BuildContext context) {
    try {
      return context.read<FeedBloc>();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFeedLoaded());
  }

  void _ensureFeedLoaded() {
    if (!mounted) return;
    final feedBloc = _feedBlocOrNull(context);
    if (feedBloc == null) return;

    final state = feedBloc.state;
    if (state.posts.isEmpty && state.postsStatus == FeedStatus.initial) {
      feedBloc.add(const GetFeedPosts(page: 1, refresh: true, silent: true));
    }
  }

  void _maybeLoadMore(FeedState state) {
    if (!mounted) return;
    if (!state.hasMorePosts || state.isLoadingMore) return;
    if (state.posts.length == _lastRequestedPostCount) return;
    if (state.posts.any((post) => post.isSaved)) return;

    _lastRequestedPostCount = state.posts.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final feedBloc = _feedBlocOrNull(context);
      feedBloc?.add(LoadMoreFeedPosts());
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedBloc = _feedBlocOrNull(context);
    if (feedBloc == null) {
      return const ProfileEmptyState(
        icon: Icons.bookmark_border_rounded,
        message: 'Saved posts need feed access',
        subtitle: 'This tab will appear once the feed bloc is available.',
      );
    }

    return BlocBuilder<FeedBloc, FeedState>(
      bloc: feedBloc,
      buildWhen: (previous, current) {
        return previous.posts != current.posts ||
            previous.postsStatus != current.postsStatus ||
            previous.hasMorePosts != current.hasMorePosts ||
            previous.currentPage != current.currentPage;
      },
      builder: (context, state) {
        _maybeLoadMore(state);
        final savedPosts = state.posts.where((post) => post.isSaved).toList();

        if (state.postsStatus == FeedStatus.loading && savedPosts.isEmpty) {
          return const ProfileLoadingState();
        }

        if (savedPosts.isEmpty) {
          return const ProfileEmptyState(
            icon: Icons.bookmark_border_rounded,
            message: 'No saved posts yet',
            subtitle: 'Tap bookmark on a post to keep it here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          physics: const BouncingScrollPhysics(),
          itemCount: savedPosts.length +
              (state.hasMorePosts && state.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index >= savedPosts.length) {
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

            return CardPost(
              post: savedPosts[index],
              isDetailView: false,
            );
          },
        );
      },
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
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 350) {
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
          return ProfileGalleryTile(gallery: items[index], isVideo: items[index].type == 'video');
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
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 350) {
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
            placeholder: (_, __) => Container(color: AppColors.greyColor.withOpacity(0.12)),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.greyColor.withOpacity(0.12),
              child: Icon(Icons.broken_image_outlined, color: AppColors.greyColor),
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

  const ProfileEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
