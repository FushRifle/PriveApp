import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/models/gallery_model.dart';
import 'package:Prive/ui/bloc/gallery_profile_cubit.dart';
import 'package:Prive/ui/pages/main/profile/edit_profile_page.dart';
import 'package:Prive/ui/pages/settings/settings_page.dart';
import 'package:Prive/ui/pages/social/friends_list_page.dart';
import 'package:Prive/ui/pages/social/insights_page.dart';
import 'package:Prive/ui/pages/social/matches_page.dart';
import 'package:Prive/data/services/user/user_service.dart';
import 'package:Prive/data/hooks/auth/auth_hook.dart';

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

class _ProfilePageState extends State<ProfilePage> {
  final AuthHook _authHook = AuthHook();
  final UserService _userService = UserService();

  bool _isFollowing = false;
  bool _isLoading = true;
  Map<String, dynamic> _user = {};
  String? _error;

  int _followingCount = 0;
  int _followersCount = 0;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _authHook.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> userData;

      if (widget.isOwnProfile) {
        userData = await _userService.getCurrentUser();
      } else if (widget.userId != null) {
        final userId = int.tryParse(widget.userId!);
        if (userId != null) {
          userData = await _userService.getUserById(userId);
        } else {
          throw 'Invalid user ID';
        }
      } else {
        throw 'No user ID provided';
      }

      setState(() {
        _user = userData;
        _followingCount =
            userData['followingCount'] ?? userData['following']?.length ?? 0;
        _followersCount =
            userData['followersCount'] ?? userData['followers']?.length ?? 0;
        _likesCount = userData['likesCount'] ?? userData['totalLikes'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getUserName() {
    return _user['name'] ?? _user['username'] ?? 'User';
  }

  String _getUserUsername() {
    final username = _user['username'];
    if (username != null && username.isNotEmpty) {
      return '@$username';
    }
    return '@user';
  }

  String _getUserAvatar() {
    return _user['avatar'] ?? '';
  }

  String _getUserBio() {
    return _user['bio'] ?? '';
  }

  String _getUserLocation() {
    return _user['location'] ?? '';
  }

  String _getUserWork() {
    return _user['work'] ?? '';
  }

  String _getUserEducation() {
    return _user['education'] ?? '';
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: AppTheme.greyTextStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : DefaultTabController(
                  length: 3,
                  child: NestedScrollView(
                    physics: const BouncingScrollPhysics(),
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        _buildSliverAppBar(context),
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildHeroProfile(),
                              const SizedBox(height: 16),
                              _buildBioSection(),
                              const SizedBox(height: 16),
                              _buildStatsRow(),
                              const SizedBox(height: 24),
                              if (widget.isOwnProfile) _buildInsightsButton(),
                              const SizedBox(height: 12),
                              _buildActionButtons(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                        _buildStickyTabBar(),
                      ];
                    },
                    body: TabBarView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildGalleryGrid(),
                        _buildVideosTab(),
                        _buildTaggedTab(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBioSection() {
    final bio = _getUserBio();
    final location = _getUserLocation();
    final work = _getUserWork();
    final education = _getUserEducation();

    if (bio.isEmpty && location.isEmpty && work.isEmpty && education.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                bio,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              if (location.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on,
                        size: 14, color: AppColors.greyColor),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              if (work.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work, size: 14, color: AppColors.greyColor),
                    const SizedBox(width: 4),
                    Text(
                      work,
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              if (education.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, size: 14, color: AppColors.greyColor),
                    const SizedBox(width: 4),
                    Text(
                      education,
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InsightsPage(),
            ),
          );
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.greyColor.withOpacity(0.2)),
          ),
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
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        icon:
            const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
      ),
      actions: [
        if (widget.isOwnProfile)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroProfile() {
    final avatar = _getUserAvatar();
    final name = _getUserName();
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary, Colors.blueAccent.shade100],
            ),
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
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
        const SizedBox(height: 16),
        Text(
          name,
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 24,
          ),
        ),
        Text(
          _getUserUsername(),
          style: AppTheme.greyTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FriendsListPage(isFollowers: false),
              ),
            );
          },
          child: _statItem(_formatCount(_followingCount), "Following"),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FriendsListPage(isFollowers: true),
              ),
            );
          },
          child: _statItem(_formatCount(_followersCount), "Followers"),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (widget.isOwnProfile) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InsightsPage(),
                ),
              );
            }
          },
          child: _statItem(_formatCount(_likesCount), "Likes"),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _statItem(String value, String label) {
    return Column(
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
    );
  }

  Widget _buildActionButtons() {
    if (widget.isOwnProfile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  );
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'EDIT PROFILE',
                      style: AppTheme.whiteTextStyle.copyWith(
                        fontWeight: AppTheme.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatchesPage(),
                  ),
                );
              },
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.greyColor.withOpacity(0.3)),
                ),
                child: const Icon(Icons.favorite_outline,
                    color: AppColors.redColor),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _isFollowing = !_isFollowing);
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: _isFollowing
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.primary, Colors.blue],
                          ),
                    border: _isFollowing
                        ? Border.all(
                            color: AppColors.greyColor.withOpacity(0.3))
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _isFollowing ? 'FOLLOWING' : 'FOLLOW',
                      style: TextStyle(
                        color: _isFollowing ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.greyColor.withOpacity(0.3)),
              ),
              child: const Icon(Icons.mail_outline, color: Colors.black87),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStickyTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
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

  Widget _buildGalleryGrid() {
    final allPosts = _getUserPostsFromFeed();
    return BlocProvider(
      create: (context) =>
          GalleryProfileCubit()..getGalleryProfile(feedPosts: allPosts),
      child: BlocBuilder<GalleryProfileCubit, GalleryProfileState>(
        builder: (context, state) {
          if (state is GalleryProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is GalleryProfileLoaded) {
            if (state.galleryProfiles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 48,
                      color: AppColors.greyColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No photos yet',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: state.galleryProfiles.length,
              itemBuilder: (context, index) {
                final gallery = state.galleryProfiles[index];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // Navigate to post detail
                    _navigateToPostDetail(context, gallery.id);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: DecorationImage(
                        image: NetworkImage(gallery.image),
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
                        // Video indicator
                        if (gallery.type == 'video')
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),

                        // Like count
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.favorite,
                                    color: Colors.white, size: 12),
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

                        // Caption preview
                        if (gallery.caption != null &&
                            gallery.caption!.isNotEmpty)
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 50,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                gallery.caption!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          if (state is GalleryProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.greyColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: AppTheme.greyTextStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final cubit = context.read<GalleryProfileCubit>();
                      cubit.getGalleryProfile(
                          feedPosts: _getUserPostsFromFeed());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      ),
    );
  }

  Widget _buildVideosTab() {
    final allPosts = _getUserPostsFromFeed();

    return BlocProvider(
      create: (context) =>
          GalleryProfileCubit()..getGalleryProfile(feedPosts: allPosts),
      child: BlocBuilder<GalleryProfileCubit, GalleryProfileState>(
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam,
                      size: 48,
                      color: AppColors.greyColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No videos yet',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _navigateToVideoPlayer(context, video);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: DecorationImage(
                        image: NetworkImage(video.image),
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
                        // Play button overlay
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

                        // Like count
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.favorite,
                                    color: Colors.white, size: 12),
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

                        // Duration indicator (optional)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '00:00',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
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

// Helper method to get user posts from feed
  List<dynamic> _getUserPostsFromFeed() {
    // You need to implement this based on your state management
    // Example with Riverpod:
    // final feedState = ref.read(feedProvider);
    // final targetUserId = widget.isOwnProfile
    //     ? _user['id']?.toString()
    //     : widget.userId;
    //
    // return feedState.posts.where((post) {
    //   final postUserId = post['userId']?.toString() ??
    //                      post['user_id']?.toString() ??
    //                      post['user']['id']?.toString();
    //   return postUserId == targetUserId;
    // }).toList();

    // Temporary: return empty list
    return [];
  }

// Helper method to navigate to post detail
  void _navigateToPostDetail(BuildContext context, String? postId) {
    if (postId == null) return;

    // Navigate to post detail page
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => PostDetailPage(postId: postId),
    //   ),
    // );

    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Open post: $postId'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

// Helper method to navigate to video player
  void _navigateToVideoPlayer(BuildContext context, GalleryModel video) {
    // Navigate to video player page
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => VideoPlayerPage(
    //       videoUrl: video.videoUrl!,
    //       thumbnail: video.image,
    //       likes: video.like,
    //       caption: video.caption,
    //     ),
    //   ),
    // );

    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Play video: ${video.videoUrl}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
