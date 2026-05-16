import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/models/gallery_model.dart';
import 'package:Prive/bloc/profile/gallery_profile_cubit.dart';
import 'package:Prive/bloc/profile/profile_bloc.dart';
import 'package:Prive/ui/pages/main/profile/edit_profile_page.dart';
import 'package:Prive/ui/pages/settings/settings_page.dart';
import 'package:Prive/ui/pages/social/friends_list_page.dart';
import 'package:Prive/ui/pages/social/insights_page.dart';
import 'package:Prive/ui/pages/social/matches_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  final bool isOwnProfile;
  final String? userId;

  const ProfilePage({
    super.key,
    this.isOwnProfile = true,
    this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GalleryProfileCubit _galleryCubit;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _galleryCubit = GalleryProfileCubit();
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _galleryCubit.close();
    super.dispose();
  }

  void _loadProfile() {
    if (widget.isOwnProfile) {
      context.read<ProfileBloc>().add(LoadMyProfile());
    } else if (widget.userId != null) {
      final userId = int.tryParse(widget.userId!);
      if (userId != null) {
        context.read<ProfileBloc>().add(LoadProfileByUserId(userId: userId));
      }
    }
  }

  void _loadUserMedia(int userId) {
    _galleryCubit.getUserMedia(
      userId: userId,
      type: null,
      page: 1,
    );
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
      backgroundColor: AppColors.backgroundColor,
      body: BlocProvider.value(
        value: _galleryCubit,
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state.status == ProfileStatus.success) {
              final userId = widget.isOwnProfile
                  ? state.myProfile?.userId ?? state.myProfile?.id
                  : state.viewedProfile?.userId ?? state.viewedProfile?.id;
              if (userId != null) {
                _loadUserMedia(userId);
              }
            }
          },
          builder: (context, state) {
            return _buildBody(state);
          },
        ),
      ),
    );
  }

  Widget _buildBody(ProfileState state) {
    // Loading state
    if (state.status == ProfileStatus.loading ||
        (state.status == ProfileStatus.initial &&
            (widget.isOwnProfile
                ? state.myProfile == null
                : state.viewedProfile == null))) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Error state
    if (state.status == ProfileStatus.error && state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.error!,
              style: AppTheme.greyTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Get profile data
    final profile = widget.isOwnProfile ? state.myProfile : state.viewedProfile;
    if (profile == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return NestedScrollView(
      physics: const BouncingScrollPhysics(),
      controller: _getScrollController(),
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildSliverAppBar(profile),
        SliverToBoxAdapter(child: _buildProfileHeader(profile)),
        _buildStickyTabBar(),
      ],
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildGalleryGrid(profile.userId ?? profile.id),
          _buildVideosTab(profile.userId ?? profile.id),
          _buildTaggedTab(),
        ],
      ),
    );
  }

  ScrollController? _scrollController;
  ScrollController _getScrollController() {
    _scrollController ??= ScrollController();
    return _scrollController!;
  }

  Widget _buildSliverAppBar(Profile profile) {
    final hasCover =
        profile.photos.isNotEmpty && profile.photos.first.isNotEmpty;

    return SliverAppBar(
      expandedHeight: hasCover ? 200 : 100,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon:
            const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
      ),
      actions: [
        if (widget.isOwnProfile)
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: hasCover
            ? _buildCoverImage(profile.photos.first)
            : _buildCoverPlaceholder(),
        centerTitle: false,
      ),
    );
  }

  Widget _buildCoverImage(String imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) =>
              // ignore: deprecated_member_use
              Container(color: AppColors.primary.withOpacity(0.1)),
          errorWidget: (context, url, error) => _buildCoverPlaceholder(),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.95),
                ],
                stops: const [0.65, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.primary.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.photo_camera_back,
          size: 50,
          color: AppColors.primary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Profile profile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        _buildAvatarSection(profile),
        const SizedBox(height: 12),
        _buildNameSection(profile),
        const SizedBox(height: 8),
        _buildBioSection(profile),
        const SizedBox(height: 16),
        _buildStatsRow(profile),
        const SizedBox(height: 24),
        if (widget.isOwnProfile) _buildInsightsButton(),
        if (widget.isOwnProfile) const SizedBox(height: 12),
        _buildActionButtons(profile),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAvatarSection(Profile profile) {
    final avatar = profile.avatar ?? '';
    final name = profile.displayName ?? 'User';
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 65,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 60,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage:
              avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
          child: avatar.isEmpty
              ? Text(
                  firstLetter,
                  style: TextStyle(
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

  Widget _buildNameSection(Profile profile) {
    return Column(
      children: [
        Text(
          profile.displayName ?? 'User',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.ageText,
          style: AppTheme.greyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection(Profile profile) {
    final bio = profile.bio;
    final location = profile.location;
    final gender = profile.gender;

    if ((bio == null || bio.isEmpty) &&
        (location == null || location.isEmpty) &&
        (gender == null || gender.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (bio != null && bio.isNotEmpty && bio != 'No bio yet')
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                bio,
                style:
                    AppTheme.blackTextStyle.copyWith(fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              if (location != null &&
                  location.isNotEmpty &&
                  location != 'Location not set')
                _buildInfoChip(Icons.location_on, location),
              if (gender != null && gender.isNotEmpty)
                _buildInfoChip(
                  gender == 'male' ? Icons.male : Icons.female,
                  gender,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.greyColor),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildStatsRow(Profile profile) {
    // These would come from your API - you might need to add these fields to Profile model
    final followingCount = 0; // TODO: Get from API
    final followersCount = 0; // TODO: Get from API
    final likesCount = 0; // TODO: Get from API

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(_formatCount(followingCount), "Following", () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FriendsListPage(isFollowers: false),
            ),
          );
        }),
        _buildStatItem(_formatCount(followersCount), "Followers", () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FriendsListPage(isFollowers: true),
            ),
          );
        }),
        _buildStatItem(_formatCount(likesCount), "Likes", () {
          if (widget.isOwnProfile) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InsightsPage()),
            );
          }
        }),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: AppTheme.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.greyTextStyle.copyWith(
              fontWeight: AppTheme.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Widget _buildInsightsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InsightsPage()),
        ),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.greyColor.withOpacity(0.2)),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.insights, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'View Insights',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Profile profile) {
    if (widget.isOwnProfile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton(
                  'EDIT PROFILE', AppColors.primary, Colors.white, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              }),
            ),
            const SizedBox(width: 12),
            _buildIconButton(Icons.favorite_outline, AppColors.redColor, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MatchesPage()),
              );
            }),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              _isFollowing ? 'FOLLOWING' : 'FOLLOW',
              _isFollowing ? Colors.transparent : AppColors.primary,
              _isFollowing ? Colors.black : Colors.white,
              () => setState(() => _isFollowing = !_isFollowing),
              hasBorder: _isFollowing,
            ),
          ),
          const SizedBox(width: 12),
          _buildIconButton(Icons.mail_outline, Colors.black87, () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onTap, {
    bool hasBorder = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: bgColor,
          border: hasBorder
              ? Border.all(color: AppColors.greyColor.withOpacity(0.3))
              : null,
          gradient: !hasBorder && bgColor == AppColors.primary
              ? const LinearGradient(colors: [AppColors.primary, Colors.blue])
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }

  Widget _buildStickyTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Colors.black,
          unselectedLabelColor: AppColors.greyColor,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(text: "PHOTOS"),
            Tab(text: "VIDEOS"),
            Tab(text: "TAGGED"),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryGrid(int userId) {
    return BlocBuilder<GalleryProfileCubit, GalleryProfileState>(
      builder: (context, state) {
        if (state is GalleryProfileLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is GalleryProfileLoaded) {
          final galleries =
              state.galleryProfiles.where((g) => g.type != 'video').toList();

          if (galleries.isEmpty) {
            return _buildEmptyState(Icons.photo_library, 'No photos yet');
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (!state.hasMore || state.isLoadingMore) return false;
              if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
                _loadMoreMedia(userId);
              }
              return false;
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: galleries.length,
              itemBuilder: (context, index) =>
                  _buildGalleryItem(galleries[index]),
            ),
          );
        }

        if (state is GalleryProfileLoadingMore) {
          final galleries =
              state.currentProfiles.where((g) => g.type != 'video').toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: galleries.length + 1,
            itemBuilder: (context, index) {
              if (index == galleries.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              return _buildGalleryItem(galleries[index]);
            },
          );
        }

        if (state is GalleryProfileError) {
          return _buildErrorState(state.message, () {
            _galleryCubit.getUserMedia(
              userId: userId,
              type: null,
              page: 1,
            );
          });
        }

        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );
  }

  void _loadMoreMedia(int userId) {
    _galleryCubit.loadMoreMedia(
      userId: userId,
      type: null,
    );
  }

  Widget _buildGalleryItem(GalleryModel gallery) {
    return GestureDetector(
      onTap: () => _navigateToPostDetail(gallery.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: CachedNetworkImageProvider(gallery.image),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (gallery.type == 'video')
              const Positioned(
                top: 12,
                right: 12,
                child: _Badge(icon: Icons.play_arrow),
              ),
            Positioned(
              bottom: 12,
              left: 12,
              child: _Badge(
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      gallery.like,
                      style: const TextStyle(
                        color: Colors.white,
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
                right: 50,
                child: _Badge(
                  child: Text(
                    gallery.caption!,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosTab(int userId) {
    return BlocBuilder<GalleryProfileCubit, GalleryProfileState>(
      builder: (context, state) {
        if (state is GalleryProfileLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is GalleryProfileLoaded) {
          final videos = state.galleryProfiles
              .where((item) => item.type == 'video')
              .toList();

          if (videos.isEmpty) {
            return _buildEmptyState(Icons.videocam, 'No videos yet');
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (!state.hasMore || state.isLoadingMore) return false;
              if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
                _loadMoreMedia(userId);
              }
              return false;
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: videos.length,
              itemBuilder: (context, index) => _buildVideoItem(videos[index]),
            ),
          );
        }

        if (state is GalleryProfileLoadingMore) {
          final videos = state.currentProfiles
              .where((item) => item.type == 'video')
              .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: videos.length + 1,
            itemBuilder: (context, index) {
              if (index == videos.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              return _buildVideoItem(videos[index]);
            },
          );
        }

        if (state is GalleryProfileError) {
          return _buildErrorState(state.message, () {
            _galleryCubit.getUserMedia(
              userId: userId,
              type: 'video',
              page: 1,
            );
          });
        }

        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );
  }

  Widget _buildVideoItem(GalleryModel video) {
    return GestureDetector(
      onTap: () => _navigateToVideoPlayer(video),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: CachedNetworkImageProvider(video.image),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.black.withOpacity(0.2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: _Badge(
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      video.like,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaggedTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark,
            size: 48,
            color: AppColors.greyColor.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No tagged posts',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Posts you\'re tagged in will appear here',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.greyColor.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(message, style: AppTheme.greyTextStyle.copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToPostDetail(String? postId) {
    if (postId == null) return;
    // TODO: Navigate to post detail
  }

  void _navigateToVideoPlayer(GalleryModel video) {
    // TODO: Navigate to video player
  }
}

class _Badge extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final Color? color;

  // ignore: unused_element_parameter
  const _Badge({this.icon, this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child ?? Icon(icon, color: Colors.white, size: 16),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  const _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
