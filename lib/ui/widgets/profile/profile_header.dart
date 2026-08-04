import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/bloc/profile/gallery_profile_cubit.dart';
import 'package:clique/core/models/profile_view.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/friends/friends_service.dart';
import 'package:clique/ui/pages/main/profile/edit_profile_page.dart';

class ProfileCoverHeader extends StatelessWidget {
  final ProfileView profile;
  final bool isOwnProfile;

  const ProfileCoverHeader({
    super.key,
    required this.profile,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = _coverUrl;

    return SliverAppBar(
      expandedHeight: 184,
      stretch: true,
      pinned: true,
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
        child: Material(
          color: AppColors.black.withOpacity(0.34),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.white,
              size: 22,
            ),
          ),
        ),
      ),
      titleSpacing: 8,
      title: Text(
        isOwnProfile ? 'My profile' : (profile.displayName ?? 'Profile'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          shadows: [Shadow(color: Color(0x66000000), blurRadius: 8)],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            coverUrl.isNotEmpty
                ? ProfileCoverImage(imageUrl: coverUrl)
                : const ProfileCoverPlaceholder(),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.55, 1.0],
                    colors: [
                      AppColors.black.withOpacity(0.46),
                      AppColors.transparent,
                      AppColors.backgroundColor.withOpacity(0.94),
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

class ProfileCoverImage extends StatelessWidget {
  final String imageUrl;

  const ProfileCoverImage({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.card.withOpacity(0.2),
              AppColors.secondary.withOpacity(0.16),
              AppColors.background.withOpacity(0.12),
            ],
          ),
        ),
      ),
      errorWidget: (_, __, ___) => const ProfileCoverPlaceholder(),
    );
  }
}

class ProfileCoverPlaceholder extends StatelessWidget {
  const ProfileCoverPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.26),
            AppColors.secondary.withOpacity(0.2),
            AppColors.black.withOpacity(0.14),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white.withOpacity(0.18),
            ),
          ),
          child: const Icon(
            Icons.image_outlined,
            color: AppColors.white,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class ProfileHeaderCard extends StatelessWidget {
  final ProfileView profile;
  final bool isOwnProfile;
  final bool isFollowing;
  final bool isFollowRequested;
  final VoidCallback onToggleFollow;
  final ValueChanged<ProfileView>? onMessage;
  final VoidCallback? onOpenAccountSwitcher;
  final VoidCallback? onOpenInsights;

  const ProfileHeaderCard({
    super.key,
    required this.profile,
    required this.isOwnProfile,
    required this.isFollowing,
    this.isFollowRequested = false,
    required this.onToggleFollow,
    this.onMessage,
    this.onOpenAccountSwitcher,
    this.onOpenInsights,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return Transform.translate(
          offset: const Offset(0, 0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 14),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                isCompact ? 14 : 16,
                0,
                isCompact ? 14 : 16,
                isCompact ? 16 : 18,
              ),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border.withOpacity(0.55)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
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
                      const SizedBox(height: 68),
                      Positioned(
                        top: -30,
                        child: ProfileAvatarBubble(
                          profile: profile,
                          radius: isCompact ? 50 : 58,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ProfileIdentityRow(
                    profile: profile,
                    isOwnProfile: isOwnProfile,
                    onOpenAccountSwitcher: onOpenAccountSwitcher,
                  ),
                  const SizedBox(height: 8),
                  ProfileBioRow(profile: profile),
                  const SizedBox(height: 14),
                  ProfileActionRow(
                    profile: profile,
                    isOwnProfile: isOwnProfile,
                    isFollowing: isFollowing,
                    isFollowRequested: isFollowRequested,
                    onToggleFollow: onToggleFollow,
                    onMessage: onMessage,
                    onOpenInsights: onOpenInsights,
                  ),
                  const SizedBox(height: 14),
                  ProfileStatsRow(profile: profile, isOwnProfile: isOwnProfile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProfileAvatarBubble extends StatelessWidget {
  final ProfileView profile;
  final double radius;

  const ProfileAvatarBubble({
    super.key,
    required this.profile,
    this.radius = 58,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatar ?? '';
    final name = profile.displayName ?? 'U';
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final isOfficial = profile.isOfficialAccount;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.card,
        child: CircleAvatar(
          radius: radius - 4,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: isOfficial || avatar.isEmpty
              ? null
              : CachedNetworkImageProvider(avatar),
          child: isOfficial
              ? Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/icons/clique.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(
                      firstLetter,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              : avatar.isEmpty
                  ? Text(
                      firstLetter,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
        ),
      ),
    );
  }
}

class ProfileIdentityRow extends StatelessWidget {
  final ProfileView profile;
  final bool isOwnProfile;
  final VoidCallback? onOpenAccountSwitcher;

  const ProfileIdentityRow({
    super.key,
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
        const SizedBox(height: 10),
        Text(
          profile.displayName ?? 'User',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: isOwnProfile && onOpenAccountSwitcher != null
              ? () {
                  HapticFeedback.lightImpact();
                  onOpenAccountSwitcher!.call();
                }
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    handle != null ? '@$handle' : profile.ageText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.greyTextStyle.copyWith(
                      fontSize: 12,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
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
        ),
      ],
    );
  }
}

class ProfileBioRow extends StatelessWidget {
  final ProfileView profile;

  const ProfileBioRow({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final bio = profile.bio;
    final location = profile.location;
    final work = profile.work;
    final hasBio = bio != null && bio.trim().isNotEmpty && bio != 'No bio yet';
    final hasLocation = location != null &&
        location.trim().isNotEmpty &&
        location != 'Location not set';
    final hasWork = work != null && work.trim().isNotEmpty;

    if (!hasBio && !hasLocation && !hasWork) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[
      if (hasLocation)
        ProfileInfoChip(icon: Icons.location_on, label: location),
      if (hasWork) ProfileInfoChip(icon: Icons.badge_outlined, label: work),
    ];

    return Column(
      children: [
        if (hasBio)
          Padding(
            padding: const EdgeInsets.only(bottom: 15, top: 15),
            child: Text(
              bio,
              textAlign: TextAlign.center,
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 14,
                height: 1.35,
                color: AppColors.text,
              ),
            ),
          ),
        if (chips.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: chips,
          ),
      ],
    );
  }
}

class ProfileInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const ProfileInfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width - 64;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: availableWidth.clamp(120.0, 420.0).toDouble(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border.withOpacity(0.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileStatsRow extends StatelessWidget {
  static final FriendsService _friendsService = FriendsService();

  final ProfileView profile;
  final bool isOwnProfile;

  const ProfileStatsRow({
    super.key,
    required this.profile,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    final userId = profile.userId != 0 ? profile.userId : profile.id;
    FeedBloc? feedBloc;
    try {
      feedBloc = context.read<FeedBloc>();
    } catch (_) {
      feedBloc = null;
    }

    return FutureBuilder<FollowStats>(
      future: isOwnProfile
          ? _friendsService.getFollowStats()
          : _friendsService.getFollowStatsForUser(userId),
      builder: (context, snapshot) {
        final stats = snapshot.data;

        Widget buildStats([int? feedLikes]) {
          return BlocBuilder<GalleryProfileCubit, GalleryProfileState>(
            builder: (context, galleryState) {
              final galleryLikes = galleryState is GalleryProfileLoaded
                  ? galleryState.galleryProfiles.fold<int>(
                      0,
                      (total, item) => total + item.likesCount,
                    )
                  : 0;

              final totalLikes =
                  (feedLikes ?? 0) > 0 ? feedLikes! : galleryLikes;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 360;

                  if (isCompact) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.border.withOpacity(0.35),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: constraints.maxWidth / 3 - 12,
                            child: ProfileStatBlock(
                              value: _formatCount(stats?.followingCount ?? 0),
                              label: 'Following',
                              onTap: isOwnProfile
                                  ? () => _openFollowList(
                                        context,
                                        isFollowers: false,
                                      )
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth / 3 - 12,
                            child: ProfileStatBlock(
                              value: _formatCount(stats?.followersCount ?? 0),
                              label: 'Followers',
                              onTap: isOwnProfile
                                  ? () => _openFollowList(
                                        context,
                                        isFollowers: true,
                                      )
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth / 3 - 12,
                            child: ProfileStatBlock(
                              value: _formatCount(totalLikes),
                              label: 'Likes',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ProfileStatBlock(
                            value: _formatCount(stats?.followingCount ?? 0),
                            label: 'Following',
                            onTap: isOwnProfile
                                ? () => _openFollowList(
                                      context,
                                      isFollowers: false,
                                    )
                                : null,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: ProfileStatBlock(
                            value: _formatCount(stats?.followersCount ?? 0),
                            label: 'Followers',
                            onTap: isOwnProfile
                                ? () => _openFollowList(
                                      context,
                                      isFollowers: true,
                                    )
                                : null,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: ProfileStatBlock(
                            value: _formatCount(totalLikes),
                            label: 'Likes',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        }

        if (feedBloc == null) {
          return buildStats();
        }

        return BlocBuilder<FeedBloc, FeedState>(
          bloc: feedBloc,
          builder: (context, feedState) {
            final feedLikes = feedState.posts
                .where((post) => post.user.id == userId)
                .fold<int>(0, (total, post) => total + post.likes);
            return buildStats(feedLikes);
          },
        );
      },
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  void _openFollowList(
    BuildContext context, {
    required bool isFollowers,
  }) {
    Navigator.pushNamed(
      context,
      NamedRoutes.friendListScreen,
      arguments: {'isFollowers': isFollowers},
    );
  }
}

class ProfileStatBlock extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const ProfileStatBlock({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Text(
          value,
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTheme.greyTextStyle.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      ),
    );
  }
}

class ProfileActionRow extends StatelessWidget {
  final ProfileView profile;
  final bool isOwnProfile;
  final bool isFollowing;
  final bool isFollowRequested;
  final VoidCallback onToggleFollow;
  final ValueChanged<ProfileView>? onMessage;
  final VoidCallback? onOpenInsights;

  const ProfileActionRow({
    super.key,
    required this.profile,
    required this.isOwnProfile,
    required this.isFollowing,
    this.isFollowRequested = false,
    required this.onToggleFollow,
    this.onMessage,
    this.onOpenInsights,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        if (isOwnProfile) {
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isCompact ? 80 : 90,
                child: ProfileActionButton(
                  text: 'EDIT',
                  backgroundColor: AppColors.card,
                  textColor: AppColors.primary,
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
              ProfileIconActionButton(
                icon: Icons.settings_outlined,
                color: AppColors.primary,
                onTap: () =>
                    Navigator.pushNamed(context, NamedRoutes.settingsScreen),
              ),
              ProfileIconActionButton(
                icon: Icons.insights_rounded,
                color: AppColors.primary,
                onTap: onOpenInsights ??
                    () => Navigator.pushNamed(
                          context,
                          NamedRoutes.insightsScreen,
                        ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: ProfileActionButton(
                text: isFollowing
                    ? 'FOLLOWING'
                    : isFollowRequested
                        ? 'REQUESTED'
                        : 'FOLLOW',
                backgroundColor: isFollowing || isFollowRequested
                    ? AppColors.transparent
                    : AppColors.primary,
                textColor: isFollowing || isFollowRequested
                    ? AppColors.text
                    : AppColors.white,
                hasBorder: isFollowing || isFollowRequested,
                onTap: onToggleFollow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfileActionButton(
                text: 'MESSAGE',
                backgroundColor: AppColors.backgroundColor,
                textColor: AppColors.text,
                hasBorder: true,
                onTap: () => onMessage?.call(profile),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ProfileActionButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool hasBorder;

  const ProfileActionButton({
    super.key,
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
        height: 42,
        constraints: const BoxConstraints(minWidth: 0),
        decoration: BoxDecoration(
          color: hasBorder ? backgroundColor : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasBorder ? AppColors.border : Colors.transparent,
          ),
          gradient: null,
          boxShadow: hasBorder
              ? null
              : [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileIconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ProfileIconActionButton({
    super.key,
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
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class ProfileTabItem {
  final String label;
  final IconData icon;

  const ProfileTabItem({required this.label, required this.icon});
}

class ProfileStickyTabBar extends StatelessWidget {
  final TabController tabController;
  final List<ProfileTabItem> tabs;

  const ProfileStickyTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: ProfileSliverHeaderDelegate(
        LayoutBuilder(
          builder: (context, constraints) {
            final showIconAndLabel =
                tabs.length <= 2 || constraints.maxWidth >= 620;
            final iconOnly = tabs.length > 2 && constraints.maxWidth < 360;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 9, 12, 7),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.6),
                    ),
                  ),
                  child: TabBar(
                    controller: tabController,
                    dividerColor: AppColors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    labelColor: AppColors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: const WidgetStatePropertyAll<Color>(
                      AppColors.transparent,
                    ),
                    tabs: tabs
                        .map(
                          (tab) => Tab(
                            height: 42,
                            child: Tooltip(
                              message: tab.label,
                              child: showIconAndLabel
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(tab.icon, size: 18),
                                        const SizedBox(width: 7),
                                        Flexible(
                                          child: Text(
                                            tab.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                  : iconOnly
                                      ? Icon(tab.icon, size: 20)
                                      : Text(
                                          tab.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            );
          },
        ),
        62,
      ),
    );
  }
}

class ProfileSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;

  const ProfileSliverHeaderDelegate(this.child, this.extent);

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: ColoredBox(
        color: AppColors.backgroundColor,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant ProfileSliverHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.extent != extent;
  }
}
