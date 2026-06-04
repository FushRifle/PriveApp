part of 'profile_page.dart';

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

  bool _isFollowing = false;
  bool _profileRequested = false;
  String? _loadedMediaKey;

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
  }

  void _reloadProfile() {
    _profileRequested = false;
    _loadedMediaKey = null;
    _loadProfile();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;

    final profile = _ProfileView.fromSources(
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

  int? _profileUserId(_ProfileView profile) {
    return profile.userId != 0 ? profile.userId : profile.id;
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
                final previousProfile = _ProfileView.fromSources(
                  user: userState.viewedUser,
                  profile: previous.viewedProfile,
                );
                final currentProfile = _ProfileView.fromSources(
                  user: userState.viewedUser,
                  profile: current.viewedProfile,
                );

                return previous.viewedStatus != current.viewedStatus ||
                    previousProfile?.userId != currentProfile?.userId ||
                    previousProfile?.id != currentProfile?.id;
              },
              listener: (context, profileState) {
                final profile = _ProfileView.fromSources(
                  user: userState.viewedUser,
                  profile: profileState.viewedProfile,
                );
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
                return previous.viewedStatus != current.viewedStatus ||
                    previous.error != current.error ||
                    previous.viewedProfile != current.viewedProfile;
              },
              builder: (context, profileState) {
                final profile = _ProfileView.fromSources(
                  user: userState.viewedUser,
                  profile: profileState.viewedProfile,
                );

                return _ProfileBody(
                  isLoading: userState.isLoading ||
                      profileState.viewedStatus == ProfileStatus.loading,
                  error: userState.error ?? profileState.error,
                  profile: profile,
                  isOwnProfile: false,
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
