import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

import 'package:clique/bloc/profile/gallery_profile_cubit.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/bloc/friends/friends_bloc.dart';
import 'package:clique/bloc/insights/insights_bloc.dart';
import 'package:clique/bloc/match/match_bloc.dart';

import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/models/gallery_model.dart';
import 'package:clique/core/services/chat/chat_service.dart';
import 'package:clique/core/services/friends/friends_service.dart';

import 'package:clique/ui/pages/main/match/matches_page.dart';
import 'package:clique/ui/pages/main/profile/edit_profile_page.dart';
import 'package:clique/ui/pages/settings/settings_page.dart';
import 'package:clique/ui/pages/social/friends_list_page.dart';
import 'package:clique/ui/pages/social/insights_page.dart';

part 'other_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  late final ScrollController _scrollController;
  late final GalleryProfileCubit _galleryCubit;

  bool _isFollowing = false;
  bool _profileRequested = false;

  String? _loadedMediaKey;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _scrollController = ScrollController();
    _galleryCubit = GalleryProfileCubit();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _galleryCubit.close();

    super.dispose();
  }

  void _loadProfile() {
    if (_profileRequested) return;

    _profileRequested = true;

    context.read<UserBloc>().add(LoadCurrentUser());
    context.read<ProfileBloc>().add(LoadMyProfile());
  }

  void _reloadProfile() {
    _profileRequested = false;
    _loadedMediaKey = null;
    _loadProfile();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;

    final profile = _currentProfile(
      context.read<UserBloc>().state,
      context.read<ProfileBloc>().state,
    );
    if (profile == null) return;

    final userId = _profileUserId(profile);
    if (userId == null) return;

    final type = _tabTypeForIndex(_tabController.index);
    if (type == null) return;

    _loadUserMedia(userId, type);
  }

  void _loadUserMedia(int userId, _GalleryTabType type) {
    final mediaType = _mediaType(type);
    final key = '$userId:${mediaType ?? 'all'}';
    if (_loadedMediaKey == key) return;

    _loadedMediaKey = key;

    _galleryCubit.getUserMedia(
      userId: userId,
      type: mediaType,
      page: 1,
    );
  }

  void _loadMoreMedia(int userId, _GalleryTabType type) {
    _galleryCubit.loadMoreMedia(
      userId: userId,
      type: _mediaType(type),
    );
  }

  _GalleryTabType? _tabTypeForIndex(int index) {
    if (index == 0) return _GalleryTabType.photos;
    if (index == 1) return _GalleryTabType.videos;
    return null;
  }

  String? _mediaType(_GalleryTabType type) {
    return type == _GalleryTabType.videos ? 'video' : 'image';
  }

  _ProfileView? _currentProfile(
    UserState userState,
    ProfileState profileState,
  ) {
    return _ProfileView.fromSources(
      user: userState.currentUser,
      profile: profileState.myProfile,
    );
  }

  int? _profileUserId(_ProfileView profile) {
    return profile.userId != 0 ? profile.userId : profile.id;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _galleryCubit,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: BlocBuilder<UserBloc, UserState>(
          buildWhen: (previous, current) {
            return previous.status != current.status ||
                previous.error != current.error ||
                previous.currentUser != current.currentUser;
          },
          builder: (context, userState) {
            return BlocConsumer<ProfileBloc, ProfileState>(
              listenWhen: (previous, current) {
                final previousProfile = _currentProfile(userState, previous);
                final currentProfile = _currentProfile(userState, current);

                return previous.status != current.status ||
                    previousProfile?.userId != currentProfile?.userId ||
                    previousProfile?.id != currentProfile?.id;
              },
              listener: (context, profileState) {
                if (userState.status != UserStatus.success &&
                    profileState.status != ProfileStatus.success) {
                  return;
                }

                final profile = _currentProfile(userState, profileState);
                if (profile == null) return;

                final userId = _profileUserId(profile);
                if (userId != null) {
                  _loadUserMedia(
                    userId,
                    _tabTypeForIndex(_tabController.index) ??
                        _GalleryTabType.photos,
                  );
                }
              },
              buildWhen: (previous, current) {
                return previous.status != current.status ||
                    previous.error != current.error ||
                    previous.myProfile != current.myProfile;
              },
              builder: (context, profileState) {
                final profile = _currentProfile(userState, profileState);

                return _ProfileBody(
                  isLoading: userState.isLoading ||
                      profileState.status == ProfileStatus.loading,
                  error: userState.error ?? profileState.error,
                  profile: profile,
                  isOwnProfile: true,
                  isFollowing: _isFollowing,
                  tabController: _tabController,
                  scrollController: _scrollController,
                  onRetry: _reloadProfile,
                  onToggleFollow: () {
                    HapticFeedback.mediumImpact();

                    setState(() {
                      _isFollowing = !_isFollowing;
                    });
                  },
                  onLoadMoreMedia: _loadMoreMedia,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProfileView {
  final int id;
  final int userId;
  final String? displayName;
  final String? bio;
  final String? avatar;
  final String? coverImage;
  final List<String> photos;
  final List<String> interests;
  final int age;
  final String? gender;
  final String? lookingFor;
  final String? location;
  final String? work;
  final String? education;

  const _ProfileView({
    required this.id,
    required this.userId,
    this.displayName,
    this.bio,
    this.avatar,
    this.coverImage,
    this.photos = const [],
    this.interests = const [],
    this.age = 0,
    this.gender,
    this.lookingFor,
    this.location,
    this.work,
    this.education,
  });

  static _ProfileView? fromSources({
    Map<String, dynamic>? user,
    Profile? profile,
  }) {
    if (user == null && profile == null) return null;

    final id = _readInt(user?['id'] ?? user?['userId'] ?? user?['user_id']);
    final userId = _readInt(user?['userId'] ?? user?['user_id'] ?? user?['id']);
    final profileUserId = profile?.userId ?? 0;
    final name = _readName(user) ?? _readString(profile?.displayName);

    return _ProfileView(
      id: id != 0 ? id : profile?.id ?? 0,
      userId: profileUserId != 0 ? profileUserId : userId,
      displayName: name,
      bio: _readString(profile?.bio) ?? _readString(user?['bio']),
      avatar: _readString(user?['avatar']) ?? _readString(profile?.avatar),
      coverImage: _readString(
              user?['coverImage'] ?? user?['cover_image'] ?? user?['cover']) ??
          _readString(profile?.coverImage),
      photos: profile?.photos.isNotEmpty == true
          ? profile!.photos
          : _readStringList(user?['photos']),
      interests: profile?.interests.isNotEmpty == true
          ? profile!.interests
          : _readStringList(user?['interests'] ?? user?['languages']),
      age: profile?.age != 0 ? profile?.age ?? 0 : _readInt(user?['age']),
      gender: _readString(profile?.gender) ?? _readString(user?['gender']),
      lookingFor: _readString(profile?.lookingFor) ??
          _readString(user?['lookingFor'] ?? user?['looking_for']),
      location:
          _readString(profile?.location) ?? _readString(user?['location']),
      work: _readString(profile?.work) ?? _readString(user?['work']),
      education:
          _readString(profile?.education) ?? _readString(user?['education']),
    );
  }

  Map<String, dynamic> toProfileUpdateData() {
    return {
      'displayName': displayName,
      'bio': bio,
      'avatar': avatar,
      'coverImage': coverImage,
      'age': age > 0 ? age : null,
      'gender': gender,
      'lookingFor': lookingFor,
      'location': location,
      'work': work,
      'education': education,
      'interests': interests,
    };
  }

  Map<String, dynamic> toUserUpdateData() {
    return {
      'name': displayName,
      'bio': bio,
      'avatar': avatar,
      'coverImage': coverImage,
      'age': age > 0 ? age : null,
      'location': location,
      'work': work,
      'education': education,
      'languages': interests,
    };
  }

  String get displayNameOrDefault => displayName ?? 'User';

  String get ageText => age > 0 ? '$age years old' : 'Age not specified';

  static String? _readString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty && item != 'null')
          .toList();
    }
    return const [];
  }

  static String? _readName(Map<String, dynamic>? user) {
    if (user == null) return null;

    final name = _readString(user['name'] ?? user['displayName']);
    if (name != null) return name;

    final firstName = _readString(user['firstName'] ?? user['first_name']);
    final lastName = _readString(user['lastName'] ?? user['last_name']);
    final fullName = [
      firstName,
      lastName,
    ].whereType<String>().join(' ').trim();
    if (fullName.isNotEmpty) return fullName;

    return _readString(user['username'] ?? user['email']);
  }
}

class _ProfileBody extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final _ProfileView? profile;
  final bool isOwnProfile;
  final bool isFollowing;
  final TabController tabController;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final VoidCallback onToggleFollow;
  final ValueChanged<_ProfileView>? onMessage;
  final void Function(int userId, _GalleryTabType type) onLoadMoreMedia;

  const _ProfileBody({
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
            type: _GalleryTabType.photos,
            onLoadMore: () => onLoadMoreMedia(userId, _GalleryTabType.photos),
          ),
          _GalleryTab(
            userId: userId,
            type: _GalleryTabType.videos,
            onLoadMore: () => onLoadMoreMedia(userId, _GalleryTabType.videos),
          ),
          const _TaggedTab(),
        ],
      ),
    );
  }

  bool get _isInitialLoading {
    return isLoading && profile == null;
  }
}

class _ProfileSliverAppBar extends StatelessWidget {
  final _ProfileView profile;
  final bool isOwnProfile;

  const _ProfileSliverAppBar({
    required this.profile,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = _coverUrl;
    final hasCover = coverUrl.isNotEmpty;

    return SliverAppBar(
      expandedHeight: hasCover ? 220 : 120,
      pinned: true,
      backgroundColor: AppColors.card,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.primary,
          size: 25,
        ),
      ),
      actions: [
        if (isOwnProfile)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.primary,
              size: 25,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: hasCover
            ? _CoverImage(imageUrl: coverUrl)
            : const _CoverPlaceholder(),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) {
            return Container(
              color: AppColors.primary.withOpacity(0.08),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorWidget: (_, __, ___) => const _CoverPlaceholder(),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.62, 1],
                colors: [
                  AppColors.transparent,
                  AppColors.card.withOpacity(0.96),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.greyColor.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_back,
              size: 50,
              color: AppColors.greyColor.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No cover photo',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final _ProfileView profile;
  final bool isOwnProfile;
  final bool isFollowing;
  final VoidCallback onToggleFollow;
  final ValueChanged<_ProfileView>? onMessage;

  const _ProfileHeader({
    required this.profile,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.onToggleFollow,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          _AvatarSection(profile: profile),
          const SizedBox(height: 12),
          _NameSection(profile: profile),
          const SizedBox(height: 8),
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

              return _StatsRow(
                profile: profile,
                isOwnProfile: isOwnProfile,
                totalLikes: totalLikes,
              );
            },
          ),
          const SizedBox(height: 24),
          if (isOwnProfile) const _InsightsButton(),
          if (isOwnProfile) const SizedBox(height: 12),
          _ActionButtons(
            profile: profile,
            isOwnProfile: isOwnProfile,
            isFollowing: isFollowing,
            onToggleFollow: onToggleFollow,
            onMessage: onMessage,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final _ProfileView profile;

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
  final _ProfileView profile;

  const _NameSection({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          profile.displayName ?? 'User',
          textAlign: TextAlign.center,
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
}

class _BioSection extends StatelessWidget {
  final _ProfileView profile;

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

class _StatsRow extends StatelessWidget {
  static final FriendsService _friendsService = FriendsService();

  final _ProfileView profile;
  final bool isOwnProfile;
  final int totalLikes;

  const _StatsRow({
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

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(
              value: _formatCount(stats?.followingCount ?? 0),
              label: 'Following',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => FriendsBloc(),
                      child: const FriendsListPage(
                        isFollowers: false,
                      ),
                    ),
                  ),
                );
              },
            ),
            _StatItem(
              value: _formatCount(stats?.followersCount ?? 0),
              label: 'Followers',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => FriendsBloc(),
                      child: const FriendsListPage(
                        isFollowers: true,
                      ),
                    ),
                  ),
                );
              },
            ),
            _StatItem(
              value: _formatCount(totalLikes),
              label: 'Likes',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => InsightsBloc(),
                      child: const InsightsPage(),
                    ),
                  ),
                );
              },
            ),
          ],
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
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
}

class _InsightsButton extends StatelessWidget {
  const _InsightsButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => InsightsBloc(),
                child: const InsightsPage(),
              ),
            ),
          );
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.insights,
                  color: AppColors.primary,
                  size: 20,
                ),
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
}

class _ActionButtons extends StatelessWidget {
  final _ProfileView profile;
  final bool isOwnProfile;
  final bool isFollowing;
  final VoidCallback onToggleFollow;
  final ValueChanged<_ProfileView>? onMessage;

  const _ActionButtons({
    required this.profile,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.onToggleFollow,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwnProfile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                text: 'EDIT PROFILE',
                backgroundColor: AppColors.primary,
                textColor: AppColors.white,
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
            const SizedBox(width: 12),
            _IconActionButton(
              icon: Icons.favorite_outline,
              color: AppColors.redColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => MatchBloc(),
                      child: const MatchesPage(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
        height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: hasBorder ? Border.all(color: AppColors.border) : null,
          gradient: !hasBorder && backgroundColor == AppColors.primary
              ? const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                )
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
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          color: color,
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
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.text,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(text: 'PHOTOS'),
            Tab(text: 'VIDEOS'),
            Tab(text: 'TAGGED'),
          ],
        ),
      ),
    );
  }
}

enum _GalleryTabType {
  photos,
  videos,
}

class _GalleryTab extends StatelessWidget {
  final int userId;
  final _GalleryTabType type;
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
          return _GalleryGrid(
            userId: userId,
            items: _filterItems(state.galleryProfiles),
            hasMore: state.hasMore,
            isLoadingMore: state.isLoadingMore,
            onLoadMore: onLoadMore,
            emptyIcon: type == _GalleryTabType.photos
                ? Icons.photo_library
                : Icons.videocam,
            emptyText: type == _GalleryTabType.photos
                ? 'No photos yet'
                : 'No videos yet',
          );
        }

        if (state is GalleryProfileLoadingMore) {
          return _GalleryGrid(
            userId: userId,
            items: _filterItems(state.currentProfiles),
            hasMore: true,
            isLoadingMore: true,
            onLoadMore: onLoadMore,
            emptyIcon: type == _GalleryTabType.photos
                ? Icons.photo_library
                : Icons.videocam,
            emptyText: type == _GalleryTabType.photos
                ? 'No photos yet'
                : 'No videos yet',
          );
        }

        if (state is GalleryProfileError) {
          return _ErrorState(
            message: state.message,
            onRetry: () {
              context.read<GalleryProfileCubit>().getUserMedia(
                    userId: userId,
                    type: type == _GalleryTabType.videos ? 'video' : 'image',
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
    if (type == _GalleryTabType.videos) {
      return items.where((item) => item.type == 'video').toList();
    }

    return items.where((item) => item.type != 'video').toList();
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

class _TaggedTab extends StatelessWidget {
  const _TaggedTab();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Icons.bookmark,
      message: 'No tagged posts',
      subtitle: 'Posts you are tagged in will appear here',
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
  final TabBar tabBar;

  const _SliverAppBarDelegate(
    this.tabBar,
  );

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(
    covariant _SliverAppBarDelegate oldDelegate,
  ) {
    return oldDelegate.tabBar != tabBar;
  }
}
