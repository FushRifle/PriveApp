import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/profile/gallery_profile_cubit.dart';
import 'package:clique/core/models/gallery_model.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/friends/friends_service.dart';
import 'package:clique/ui/pages/main/profile/edit_profile_page.dart';
import 'package:clique/core/models/profile_view.dart';
import 'package:clique/ui/widgets/post/normal-post/post_card.dart';

class ProfileBody extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final ProfileView? profile;
  final bool isOwnProfile;
  final bool isFollowing;
  final TabController tabController;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final VoidCallback onToggleFollow;
  final ValueChanged<ProfileView>? onMessage;
  final VoidCallback? onOpenAccountSwitcher;
  final void Function(int userId, ProfileGalleryTabType type) onLoadMoreMedia;

  const ProfileBody({
    super.key,
    required this.isLoading,
    required this.error,
    required this.profile,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.tabController,
    required this.scrollController,
    required this.onRetry,
    required this.onToggleFollow,
    this.onMessage,
    this.onOpenAccountSwitcher,
    required this.onLoadMoreMedia,
  });

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const _LoadingState();
    }

    if (error != null && profile == null) {
      return _ErrorState(
        message: error!,
        onRetry: onRetry,
      );
    }

    final currentProfile = profile;

    if (currentProfile == null) {
      return const _LoadingState();
    }

    final userId =
        currentProfile.userId != 0 ? currentProfile.userId : currentProfile.id;

    return NestedScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _ProfileSliverAppBar(
            profile: currentProfile,
            isOwnProfile: isOwnProfile,
          ),
          SliverToBoxAdapter(
            child: _ProfileHeader(
              profile: currentProfile,
              isOwnProfile: isOwnProfile,
              isFollowing: isFollowing,
              onToggleFollow: onToggleFollow,
              onMessage: onMessage,
              onOpenAccountSwitcher: onOpenAccountSwitcher,
            ),
          ),
          _StickyTabBar(
            tabController: tabController,
          ),
        ];
      },
      body: TabBarView(
        controller: tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _GalleryTab(
            userId: userId,
            type: ProfileGalleryTabType.posts,
            onLoadMore: () =>
                onLoadMoreMedia(userId, ProfileGalleryTabType.posts),
          ),
          _GalleryTab(
            userId: userId,
            type: ProfileGalleryTabType.media,
            onLoadMore: () =>
                onLoadMoreMedia(userId, ProfileGalleryTabType.media),
          ),
          const _SavedPostsTab(),
        ],
      ),
    );
  }

  bool get _isInitialLoading {
    return isLoading && profile == null;
  }
}

class _ProfileSliverAppBar extends StatelessWidget {
  final ProfileView profile;
  final bool isOwnProfile;

  const _ProfileSliverAppBar({
    required this.profile,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = _coverUrl;

    return SliverAppBar(
      expandedHeight: 180,
      stretch: true,
      pinned: true,
      backgroundColor: AppColors.black,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.white,
          size: 25,
        ),
      ),
      actions: [
        if (isOwnProfile)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, NamedRoutes.settingsScreen);
            },
            icon: const Icon(
              Icons.manage_accounts_outlined,
              color: AppColors.white,
              size: 25,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            coverUrl.isNotEmpty
                ? _CoverImage(imageUrl: coverUrl)
                : const _CoverPlaceholder(),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.55, 1.0],
                    colors: [
                      AppColors.black.withOpacity(0.42),
                      AppColors.transparent,
                      AppColors.backgroundColor.withOpacity(0.98),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _coverUrl {
    if (profile.coverImage != null && profile.coverImage!.isNotEmpty) {
      return profile.coverImage!;
    }

    if (profile.photos.isNotEmpty && profile.photos.first.isNotEmpty) {
      return profile.photos.first;
    }

    return '';
  }
}

class _CoverImage extends StatelessWidget {
  final String imageUrl;

  const _CoverImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.24),
                AppColors.secondary.withOpacity(0.18),
                AppColors.black.withOpacity(0.18),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.white,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorWidget: (_, __, ___) => const _CoverPlaceholder(),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.28),
            AppColors.secondary.withOpacity(0.2),
            AppColors.black.withOpacity(0.22),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white.withOpacity(0.09),
            border: Border.all(color: AppColors.white.withOpacity(0.14)),
          ),
          child: Icon(
            Icons.photo_camera_back_outlined,
            color: AppColors.white.withOpacity(0.9),
            size: 38,
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileView profile;
  final bool isOwnProfile;
  final bool isFollowing;
  final VoidCallback onToggleFollow;
  final ValueChanged<ProfileView>? onMessage;
  final VoidCallback? onOpenAccountSwitcher;

  const _ProfileHeader({
    required this.profile,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.onToggleFollow,
    this.onMessage,
    this.onOpenAccountSwitcher,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Transform.translate(
        offset: const Offset(0, -26),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border.withOpacity(0.55)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    const SizedBox(height: 46),
                    Positioned(
                      top: -30,
                      child: _AvatarSection(profile: profile),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _NameSection(
                  profile: profile,
                  isOwnProfile: isOwnProfile,
                  onOpenAccountSwitcher: onOpenAccountSwitcher,
                ),
                const SizedBox(height: 10),
                _BioSection(profile: profile),
                const SizedBox(height: 16),
                BlocBuilder<GalleryProfileCubit, GalleryProfileState>(
                  builder: (context, state) {
                    final totalLikes = state is GalleryProfileLoaded
                        ? state.galleryProfiles.fold<int>(
                            0,
                            (total, item) => total + item.likesCount,
                          )
                        : 0;

                    return _TikTokStatsRow(
                      profile: profile,
                      isOwnProfile: isOwnProfile,
                      totalLikes: totalLikes,
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ActionButtons(
                  profile: profile,
                  isOwnProfile: isOwnProfile,
                  isFollowing: isFollowing,
                  onToggleFollow: onToggleFollow,
                  onMessage: onMessage,
                  onOpenAccountSwitcher: onOpenAccountSwitcher,
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final ProfileView profile;

  const _AvatarSection({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatar ?? '';
    final name = profile.displayName ?? 'User';
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 65,
        backgroundColor: AppColors.card,
        child: CircleAvatar(
          radius: 60,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage:
              avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
          child: avatar.isEmpty
              ? Text(
                  firstLetter,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _NameSection extends StatelessWidget {
  final ProfileView profile;
  final bool isOwnProfile;
  final VoidCallback? onOpenAccountSwitcher;

  const _NameSection({
    required this.profile,
    required this.isOwnProfile,
    this.onOpenAccountSwitcher,
  });

  @override
  Widget build(BuildContext context) {
    final handle = profile.username?.trim().isNotEmpty == true
        ? profile.username!.trim()
        : null;

    return Column(
      children: [
        Text(
          profile.displayName ?? 'User',
          textAlign: TextAlign.center,
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 23,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: isOwnProfile && onOpenAccountSwitcher != null
              ? () {
                  HapticFeedback.lightImpact();
                  onOpenAccountSwitcher?.call();
                }
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                handle != null ? '@$handle' : profile.ageText,
                style: AppTheme.greyTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (isOwnProfile && onOpenAccountSwitcher != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BioSection extends StatelessWidget {
  final ProfileView profile;

  const _BioSection({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final bio = profile.bio;
    final location = profile.location;
    final gender = profile.gender;

    final hasBio = bio != null && bio.isNotEmpty && bio != 'No bio yet';
    final hasLocation = location != null &&
        location.isNotEmpty &&
        location != 'Location not set';
    final hasGender = gender != null && gender.isNotEmpty;

    if (!hasBio && !hasLocation && !hasGender) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (hasBio)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              if (hasLocation)
                _InfoChip(
                  icon: Icons.location_on,
                  label: location,
                ),
              if (hasGender)
                _InfoChip(
                  icon: gender == 'male' ? Icons.male : Icons.female,
                  label: gender,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.greyColor,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.greyTextStyle.copyWith(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _TikTokStatsRow extends StatelessWidget {
  static final FriendsService _friendsService = FriendsService();

  final ProfileView profile;
  final bool isOwnProfile;
  final int totalLikes;

  const _TikTokStatsRow({
    required this.profile,
    required this.isOwnProfile,
    required this.totalLikes,
  });

  @override
  Widget build(BuildContext context) {
    final userId = profile.userId != 0 ? profile.userId : profile.id;

    return FutureBuilder<FollowStats>(
      future: isOwnProfile
          ? _friendsService.getFollowStats()
          : _friendsService.getFollowStatsForUser(userId),
      builder: (context, snapshot) {
        final stats = snapshot.data;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: _StatBlock(
                  value: _formatCount(stats?.followingCount ?? 0),
                  label: 'Following',
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.border),
              Expanded(
                child: _StatBlock(
                  value: _formatCount(stats?.followersCount ?? 0),
                  label: 'Followers',
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.border),
              Expanded(
                child: _StatBlock(
                  value: _formatCount(totalLikes),
                  label: 'Likes',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;

  const _StatBlock({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTheme.greyTextStyle.copyWith(
            fontSize: 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ProfileView profile;
  final bool isOwnProfile;
  final bool isFollowing;
  final VoidCallback onToggleFollow;
  final ValueChanged<ProfileView>? onMessage;
  final VoidCallback? onOpenAccountSwitcher;

  const _ActionButtons({
    required this.profile,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.onToggleFollow,
    this.onMessage,
    this.onOpenAccountSwitcher,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwnProfile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                text: 'EDIT',
                backgroundColor: AppColors.backgroundColor,
                textColor: AppColors.text,
                hasBorder: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfilePage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            _IconActionButton(
              icon: Icons.settings_outlined,
              color: AppColors.text,
              onTap: () {
                Navigator.pushNamed(context, NamedRoutes.settingsScreen);
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              text: isFollowing ? 'FOLLOWING' : 'FOLLOW',
              backgroundColor:
                  isFollowing ? AppColors.transparent : AppColors.primary,
              textColor: isFollowing ? AppColors.text : AppColors.white,
              hasBorder: isFollowing,
              onTap: onToggleFollow,
            ),
          ),
          const SizedBox(width: 12),
          _IconActionButton(
            icon: Icons.mail_outline,
            color: AppColors.greyColor,
            onTap: () => onMessage?.call(profile),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool hasBorder;

  const _ActionButton({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: hasBorder ? backgroundColor : null,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: hasBorder ? AppColors.border : Colors.transparent,
          ),
          gradient: !hasBorder && backgroundColor == AppColors.primary
              ? const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                )
              : null,
          boxShadow: !hasBorder && backgroundColor == AppColors.primary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          color: color,
          size: 18,
        ),
      ),
    );
  }
}

class _StickyTabBar extends StatelessWidget {
  final TabController tabController;

  const _StickyTabBar({
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    const extraPadding = 6.0;
    final tabBar = TabBar(
      controller: tabController,
      indicatorColor: AppColors.primary,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStatePropertyAll<Color>(AppColors.transparent),
      tabs: const [
        Tab(
          icon: Icon(Icons.grid_on_rounded),
        ),
        Tab(
          icon: Icon(Icons.movie_filter_outlined),
        ),
        Tab(
          icon: Icon(Icons.bookmark_border_rounded),
        ),
      ],
    );

    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        SizedBox(
          height: tabBar.preferredSize.height + extraPadding,
          child: Padding(
            padding: const EdgeInsets.only(bottom: extraPadding),
            child: tabBar,
          ),
        ),
        tabBar.preferredSize.height + extraPadding,
      ),
    );
  }
}

enum ProfileGalleryTabType {
  posts,
  media,
}

class _GalleryTab extends StatelessWidget {
  final int userId;
  final ProfileGalleryTabType type;
  final VoidCallback onLoadMore;

  const _GalleryTab({
    required this.userId,
    required this.type,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GalleryProfileCubit, GalleryProfileState>(
      builder: (context, state) {
        if (state is GalleryProfileLoading) {
          return const _LoadingState();
        }

        if (state is GalleryProfileLoaded) {
          final items = _filterItems(state.galleryProfiles);
          if (type == ProfileGalleryTabType.posts) {
            return _PostsTab(
              items: items,
              hasMore: state.hasMore,
              isLoadingMore: state.isLoadingMore,
              onLoadMore: onLoadMore,
            );
          }
          return _GalleryGrid(
            userId: userId,
            items: items,
            hasMore: state.hasMore,
            isLoadingMore: state.isLoadingMore,
            onLoadMore: onLoadMore,
            emptyIcon: Icons.perm_media_outlined,
            emptyText: 'No media yet',
          );
        }

        if (state is GalleryProfileLoadingMore) {
          final items = _filterItems(state.currentProfiles);
          if (type == ProfileGalleryTabType.posts) {
            return _PostsTab(
              items: items,
              hasMore: true,
              isLoadingMore: true,
              onLoadMore: onLoadMore,
            );
          }
          return _GalleryGrid(
            userId: userId,
            items: items,
            hasMore: true,
            isLoadingMore: true,
            onLoadMore: onLoadMore,
            emptyIcon: Icons.perm_media_outlined,
            emptyText: 'No media yet',
          );
        }

        if (state is GalleryProfileError) {
          return _ErrorState(
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

        return const _LoadingState();
      },
    );
  }

  List<GalleryModel> _filterItems(List<GalleryModel> items) {
    return items;
  }
}

class _SavedPostsTab extends StatefulWidget {
  const _SavedPostsTab();

  @override
  State<_SavedPostsTab> createState() => _SavedPostsTabState();
}

class _SavedPostsTabState extends State<_SavedPostsTab> {
  int _lastRequestedPostCount = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureFeedLoaded();
    });
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

  FeedBloc? _feedBlocOrNull(BuildContext context) {
    try {
      return context.read<FeedBloc>();
    } catch (_) {
      return null;
    }
  }

  void _maybeLoadMore(FeedState state) {
    if (!mounted) return;

    if (!state.hasMorePosts || state.isLoadingMore) return;
    if (state.posts.length == _lastRequestedPostCount) return;

    final savedPosts = state.posts.where((post) => post.isSaved).toList();
    if (savedPosts.isNotEmpty) return;

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
      return const _EmptyState(
        icon: Icons.bookmark_border_rounded,
        message: 'No saved posts yet',
        subtitle: 'Saved posts appear when this screen can access your feed.',
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
          return const _LoadingState();
        }

        if (savedPosts.isEmpty) {
          return const _EmptyState(
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

            final post = savedPosts[index];

            return CardPost(
              post: post,
              isDetailView: false,
            );
          },
        );
      },
    );
  }
}

class _PostsTab extends StatelessWidget {
  final List<GalleryModel> items;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const _PostsTab({
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !isLoadingMore) {
      return const _EmptyState(
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
          final item = items[index];
          return _GalleryItem(
            gallery: item,
            isVideo: item.type == 'video',
          );
        },
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  final int userId;
  final List<GalleryModel> items;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final IconData emptyIcon;
  final String emptyText;

  const _GalleryGrid({
    required this.userId,
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.emptyIcon,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !isLoadingMore) {
      return _EmptyState(
        icon: emptyIcon,
        message: emptyText,
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
        key: PageStorageKey('gallery_grid_$emptyText'),
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        cacheExtent: 800,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
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

          final item = items[index];

          return RepaintBoundary(
            child: _GalleryItem(
              gallery: item,
              isVideo: item.type == 'video',
            ),
          );
        },
      ),
    );
  }
}

class _GalleryItem extends StatelessWidget {
  final GalleryModel gallery;
  final bool isVideo;

  const _GalleryItem({
    required this.gallery,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: gallery.image,
              fit: BoxFit.cover,
              placeholder: (_, __) {
                return Container(
                  color: AppColors.greyColor.withOpacity(0.12),
                );
              },
              errorWidget: (_, __, ___) {
                return Container(
                  color: AppColors.greyColor.withOpacity(0.12),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.greyColor,
                  ),
                );
              },
            ),
            if (isVideo)
              const Positioned(
                top: 12,
                right: 12,
                child: _Badge(
                  icon: Icons.play_arrow,
                ),
              ),
            Positioned(
              bottom: 12,
              left: 12,
              child: _Badge(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: AppColors.white,
                      size: 12,
                    ),
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
                top: 12,
                left: 12,
                right: isVideo ? 54 : 12,
                child: _Badge(
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
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const _EmptyState({
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
            Icon(
              icon,
              size: 48,
              color: AppColors.greyColor.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
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
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.greyColor,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTheme.greyTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData? icon;
  final Widget? child;

  const _Badge({
    this.icon,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.5),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;

  const _SliverAppBarDelegate(
    this.child,
    this.extent,
  );

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: ColoredBox(
        color: AppColors.backgroundColor,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(
    covariant _SliverAppBarDelegate oldDelegate,
  ) {
    return oldDelegate.child != child || oldDelegate.extent != extent;
  }
}
