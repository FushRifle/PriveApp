import 'package:flutter/material.dart';
import 'package:clique/core/models/profile_view.dart';
import 'package:clique/ui/widgets/profile/profile_gallery.dart';
import 'package:clique/ui/widgets/profile/profile_header.dart';

class ProfileBody extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final ProfileView? profile;
  final bool isOwnProfile;
  final bool isFollowing;
  final bool isFollowRequested;
  final TabController tabController;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final VoidCallback onToggleFollow;
  final ValueChanged<ProfileView>? onMessage;
  final VoidCallback? onOpenAccountSwitcher;
  final VoidCallback? onOpenInsights;
  final void Function(int userId, ProfileGalleryTabType type) onLoadMoreMedia;

  const ProfileBody({
    super.key,
    required this.isLoading,
    required this.error,
    required this.profile,
    required this.isOwnProfile,
    required this.isFollowing,
    this.isFollowRequested = false,
    required this.tabController,
    required this.scrollController,
    required this.onRetry,
    required this.onToggleFollow,
    this.onMessage,
    this.onOpenAccountSwitcher,
    this.onOpenInsights,
    required this.onLoadMoreMedia,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && profile == null) {
      return const ProfileLoadingState();
    }

    if (error != null && profile == null) {
      return ProfileErrorState(message: error!, onRetry: onRetry);
    }

    final currentProfile = profile;
    if (currentProfile == null) {
      return const ProfileLoadingState();
    }

    final userId =
        currentProfile.userId != 0 ? currentProfile.userId : currentProfile.id;

    return NestedScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          ProfileCoverHeader(
            profile: currentProfile,
            isOwnProfile: isOwnProfile,
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ProfileHeaderCard(
                  profile: currentProfile,
                  isOwnProfile: isOwnProfile,
                  isFollowing: isFollowing,
                  isFollowRequested: isFollowRequested,
                  onToggleFollow: onToggleFollow,
                  onMessage: onMessage,
                  onOpenAccountSwitcher: onOpenAccountSwitcher,
                  onOpenInsights: onOpenInsights,
                ),
              ),
            ),
          ),
          ProfileStickyTabBar(
            tabController: tabController,
            tabs: const [
              ProfileTabItem(label: 'Posts', icon: Icons.grid_view_rounded),
              ProfileTabItem(
                label: 'Media',
                icon: Icons.perm_media_outlined,
              ),
              ProfileTabItem(
                label: 'Saved',
                icon: Icons.bookmark_border_rounded,
              ),
              ProfileTabItem(label: 'Drafts', icon: Icons.drafts_outlined),
            ],
          ),
        ];
      },
      body: TabBarView(
        controller: tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          ProfileGalleryTab(
            userId: userId,
            type: ProfileGalleryTabType.posts,
            onLoadMore: () =>
                onLoadMoreMedia(userId, ProfileGalleryTabType.posts),
          ),
          ProfileGalleryTab(
            userId: userId,
            type: ProfileGalleryTabType.media,
            onLoadMore: () =>
                onLoadMoreMedia(userId, ProfileGalleryTabType.media),
          ),
          const ProfileSavedPostsTab(),
          const ProfileDraftsTab(),
        ],
      ),
    );
  }
}
