import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/profile/gallery_profile_cubit.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/models/profile_view.dart';
import 'package:clique/ui/widgets/profile/profile_widgets.dart';

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

  void _openAccountSwitcher() {
    Navigator.pushNamed(context, NamedRoutes.accountSwitchScreen);
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
    return null;
  }

  ProfileView? _currentProfile(
    UserState userState,
    ProfileState profileState,
  ) {
    return ProfileView.fromSources(
      user: userState.currentUser,
      profile: profileState.myProfile,
    );
  }

  int? _profileUserId(ProfileView profile) {
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
                        ProfileGalleryTabType.posts,
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

                return ProfileBody(
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
                  onOpenAccountSwitcher: _openAccountSwitcher,
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
