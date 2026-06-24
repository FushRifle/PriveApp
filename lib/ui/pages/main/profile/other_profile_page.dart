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
import 'package:clique/ui/widgets/profile/profile_widgets.dart';

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

                return ProfileBody(
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
