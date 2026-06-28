import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/friends/friends_bloc.dart';
import 'package:clique/bloc/profile/gallery_profile_cubit.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/chat/chat_service.dart';
import 'package:clique/core/services/friends/friends_service.dart';
import 'package:clique/core/models/profile_view.dart';
import 'package:clique/ui/widgets/profile/profile_gallery.dart';
import 'package:clique/ui/widgets/profile/profile_header.dart';

class OtherProfilePage extends StatefulWidget {
  final int userId;

  const OtherProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _scrollController;
  late final GalleryProfileCubit _galleryCubit;
  final FriendsService _friendsService = FriendsService();
  final ChatService _chatService = ChatService();

  bool _isFollowing = false;
  bool _isFollowBusy = false;
  bool _profileRequested = false;
  Relationship? _relationship;
  String? _loadedMediaKey;

  @override
  void initState() {
    super.initState();

    // Keep length 2 for only Posts and Media tabs
    _tabController = TabController(length: 2, vsync: this);
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
  void didUpdateWidget(covariant OtherProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId) {
      _profileRequested = false;
      _loadedMediaKey = null;
      _loadProfile();
    }
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

    context.read<UserBloc>().add(
          LoadUserById(userId: widget.userId),
        );
    context.read<ProfileBloc>().add(
          LoadProfileByUserId(userId: widget.userId),
        );
    _loadRelationship();
  }

  void _reloadProfile() {
    _profileRequested = false;
    _loadedMediaKey = null;
    _loadProfile();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;

    final profile = ProfileView.fromSources(
      user: context.read<UserBloc>().state.viewedUser,
      profile: context.read<ProfileBloc>().state.viewedProfile,
    );
    if (profile == null) return;

    final userId = _profileUserId(profile);
    if (userId == null) return;

    final type = _tabTypeForIndex(_tabController.index);
    if (type == null) return;

    _loadUserMedia(userId, type);
  }

  void _loadUserMedia(int userId, ProfileGalleryTabType type) {
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

  void _loadMoreMedia(int userId, ProfileGalleryTabType type) {
    _galleryCubit.loadMoreMedia(
      userId: userId,
      type: _mediaType(type),
    );
  }

  ProfileGalleryTabType? _tabTypeForIndex(int index) {
    if (index == 0) return ProfileGalleryTabType.posts;
    if (index == 1) return ProfileGalleryTabType.media;
    return null;
  }

  String? _mediaType(ProfileGalleryTabType type) {
    if (type == ProfileGalleryTabType.media) return 'media';
    return null;
  }

  int? _profileUserId(ProfileView profile) {
    return profile.userId != 0 ? profile.userId : profile.id;
  }

  Future<void> _loadRelationship() async {
    try {
      final relationship =
          await _friendsService.checkRelationship(widget.userId);
      if (!mounted) return;

      setState(() {
        _isFollowing = relationship.isFollowing;
        _relationship = relationship;
      });
    } catch (e) {
      debugPrint('Failed to load relationship: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowBusy) return;
    if (_relationship?.hasPendingRequest == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow request is pending')),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    final wasFollowing = _isFollowing;

    setState(() {
      _isFollowing = !wasFollowing;
      _isFollowBusy = true;
    });

    try {
      if (wasFollowing) {
        await _friendsService.unfollowUser(widget.userId);
      } else {
        await _friendsService.followUser(widget.userId);
      }

      if (!mounted) return;
      final relationship =
          await _friendsService.checkRelationship(widget.userId);
      if (!mounted) return;
      setState(() {
        _relationship = relationship;
        _isFollowing = relationship.isFollowing;
      });
      try {
        context.read<FriendsBloc>().add(LoadFollowStats());
      } catch (_) {
        // The other-profile route does not always live under FriendsBloc.
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isFollowing = wasFollowing;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.card,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFollowBusy = false;
        });
      }
    }
  }

  Future<void> _openConversation(ProfileView profile) async {
    final userId = _profileUserId(profile);
    if (userId == null || userId <= 0) return;

    HapticFeedback.lightImpact();
    final isFollowedBack = _relationship?.isFollowedBy ?? false;

    try {
      final conversation = await _chatService.startConversation(
        receiverId: userId,
      );
      final conversationId = _readInt(
        conversation['conversationId'] ?? conversation['id'],
      );
      if (!mounted || conversationId <= 0) return;

      Navigator.pushNamed(
        context,
        NamedRoutes.chatScreen,
        arguments: {
          'conversationId': conversationId,
          'userId': userId,
          'userName': profile.displayName ?? 'User',
          'userAvatar': profile.avatar ?? '',
          'messageLimit': isFollowedBack ? 0 : 1,
          'messageLimitHint': isFollowedBack
              ? null
              : 'You can send one message until they follow you back.',
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.card,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _galleryCubit,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: BlocBuilder<UserBloc, UserState>(
          buildWhen: (previous, current) {
            return previous.status != current.status ||
                previous.error != current.error ||
                previous.viewedUser != current.viewedUser;
          },
          builder: (context, userState) {
            return BlocConsumer<ProfileBloc, ProfileState>(
              listenWhen: (previous, current) {
                final previousProfile = ProfileView.fromSources(
                  user: userState.viewedUser,
                  profile: previous.viewedProfile,
                );
                final currentProfile = ProfileView.fromSources(
                  user: userState.viewedUser,
                  profile: current.viewedProfile,
                );

                return previous.viewedStatus != current.viewedStatus ||
                    previousProfile?.userId != currentProfile?.userId ||
                    previousProfile?.id != currentProfile?.id;
              },
              listener: (context, profileState) {
                final profile = ProfileView.fromSources(
                  user: userState.viewedUser,
                  profile: profileState.viewedProfile,
                );
                if (profile == null) return;

                final userId = _profileUserId(profile);
                if (userId != null) {
                  _loadUserMedia(
                    userId,
                    _tabTypeForIndex(_tabController.index) ??
                        ProfileGalleryTabType.posts,
                  );
                }
              },
              buildWhen: (previous, current) {
                return previous.viewedStatus != current.viewedStatus ||
                    previous.error != current.error ||
                    previous.viewedProfile != current.viewedProfile;
              },
              builder: (context, profileState) {
                final profile = ProfileView.fromSources(
                  user: userState.viewedUser,
                  profile: profileState.viewedProfile,
                );

                // Wrap ProfileBody to only show 2 tabs for other users
                return _OtherProfileBody(
                  isLoading: userState.isLoading ||
                      profileState.viewedStatus == ProfileStatus.loading,
                  error: userState.error ?? profileState.error,
                  profile: profile,
                  isOwnProfile: false,
                  isFollowing: _isFollowing,
                  isFollowRequested:
                      _relationship?.hasPendingRequest ?? false,
                  tabController: _tabController,
                  scrollController: _scrollController,
                  onRetry: _reloadProfile,
                  onToggleFollow: _toggleFollow,
                  onMessage: _openConversation,
                  onLoadMoreMedia: _loadMoreMedia,
                );
              },
            );
          },
        ),
      ),
    );
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// Custom wrapper that only shows Posts and Media tabs for other users
class _OtherProfileBody extends StatelessWidget {
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
  final void Function(int userId, ProfileGalleryTabType type) onLoadMoreMedia;

  const _OtherProfileBody({
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
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
          SliverToBoxAdapter(
            child: ProfileHeaderCard(
              profile: currentProfile,
              isOwnProfile: isOwnProfile,
              isFollowing: isFollowing,
              isFollowRequested: isFollowRequested,
              onToggleFollow: onToggleFollow,
              onMessage: onMessage,
              onOpenAccountSwitcher: null,
              onOpenInsights: null,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              tabController: tabController,
              tabs: const ['Posts', 'Media'],
            ),
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
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<String> tabs;

  _StickyTabBarDelegate({
    required this.tabController,
    required this.tabs,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: tabController,
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.text.withOpacity(0.5),
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return tabController != oldDelegate.tabController ||
        tabs != oldDelegate.tabs;
  }
}