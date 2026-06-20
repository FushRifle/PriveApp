import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

import 'package:clique/bloc/explore/explore_bloc.dart';

import 'package:clique/core/models/profile_model.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/chat/chat_service.dart';

import 'package:clique/ui/widgets/explore/action_buttons.dart';
import 'package:clique/ui/widgets/explore/discover_header.dart';
import 'package:clique/ui/widgets/explore/filter_bottom_sheet.dart';
import 'package:clique/ui/widgets/explore/loading_shimmer.dart';
import 'package:clique/ui/widgets/explore/match_dialog.dart';
import 'package:clique/ui/widgets/explore/no_more_profiles.dart';
import 'package:clique/ui/widgets/explore/swipe_cards_stack.dart';
import 'package:clique/ui/widgets/explore/swipe_feedback_overlay.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({
    super.key,
  });

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _swipeController;
  late final AnimationController _feedbackAnimationController;
  late final AnimationController _buttonAnimationController;

  late final Animation<double> _feedbackAnimation;
  final ChatService _chatService = ChatService();

  Offset _dragOffset = Offset.zero;

  double _swipeProgress = 0.0;
  double _verticalSwipeProgress = 0.0;

  SwipeDirection _swipeDirection = SwipeDirection.none;
  SwipeActionType _feedbackAction = SwipeActionType.none;

  bool _initialized = false;
  bool _isAnimatingSwipe = false;

  static const double _horizontalThreshold = 0.28;
  static const double _verticalThreshold = 0.24;
  static const double _velocityThreshold = 700;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _feedbackAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.92,
      upperBound: 1,
      value: 1,
    );

    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  void _initialize() {
    if (_initialized || !mounted) return;

    _initialized = true;

    final bloc = context.read<ExploreBloc>();

    if (bloc.state.profiles.isEmpty) {
      bloc.add(LoadExploreProfiles());
      bloc.add(LoadExploreStats());
    }
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _feedbackAnimationController.dispose();
    _buttonAnimationController.dispose();

    super.dispose();
  }

  Future<void> _refresh() async {
    context.read<ExploreBloc>().add(RefreshExploreProfiles());
    context.read<ExploreBloc>().add(LoadExploreStats());

    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );
  }

  Future<void> _showFilters(
    BuildContext context,
    Map<String, dynamic> currentFilters,
  ) async {
    HapticFeedback.lightImpact();

    final newFilters = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) {
        return FilterBottomSheet(
          currentFilters: currentFilters,
        );
      },
    );

    if (!mounted || newFilters == null) return;

    this.context.read<ExploreBloc>().add(
          UpdateExploreFilters(
            filters: {
              ...newFilters,
              'page': 1,
              'filter':
                  newFilters['filter'] ?? currentFilters['filter'] ?? 'all',
            },
          ),
        );
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimatingSwipe) return;

    _dragOffset = Offset.zero;
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    ExploreState state,
  ) {
    if (_isAnimatingSwipe) return;
    if (state.status != ExploreStatus.success) return;
    if (state.currentProfile == null) return;

    final size = MediaQuery.sizeOf(context);

    _dragOffset += details.delta;

    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;

    double nextSwipeProgress = dx / size.width;
    double nextVerticalProgress = -dy / size.height;

    SwipeDirection nextDirection = SwipeDirection.none;

    if (dx.abs() > dy.abs() && dx.abs() > 8) {
      nextDirection = dx > 0 ? SwipeDirection.right : SwipeDirection.left;
      nextVerticalProgress = 0;
    } else if (dy < -8) {
      nextDirection = SwipeDirection.up;
      nextSwipeProgress = 0;
      nextVerticalProgress = nextVerticalProgress.clamp(0.0, 1.0);
    }

    setState(() {
      _swipeDirection = nextDirection;
      _swipeProgress = nextSwipeProgress.clamp(-1.2, 1.2);
      _verticalSwipeProgress = nextVerticalProgress.clamp(0.0, 1.2);
    });
  }

  void _onPanEnd(
    DragEndDetails details,
    ExploreState state,
  ) {
    if (_isAnimatingSwipe) return;
    if (state.status != ExploreStatus.success) return;

    final profile = state.currentProfile;

    if (profile == null) {
      _resetSwipe();
      return;
    }

    final velocity = details.velocity.pixelsPerSecond;

    final shouldLike = _swipeDirection == SwipeDirection.right &&
        (_swipeProgress > _horizontalThreshold ||
            velocity.dx > _velocityThreshold);

    final shouldPass = _swipeDirection == SwipeDirection.left &&
        (_swipeProgress < -_horizontalThreshold ||
            velocity.dx < -_velocityThreshold);

    final shouldSuperLike = _swipeDirection == SwipeDirection.up &&
        (_verticalSwipeProgress > _verticalThreshold ||
            velocity.dy < -_velocityThreshold);

    if (shouldLike) {
      _animateSwipeOut(
        direction: SwipeDirection.right,
        profile: profile,
        index: state.currentIndex,
      );
      return;
    }

    if (shouldPass) {
      _animateSwipeOut(
        direction: SwipeDirection.left,
        profile: profile,
        index: state.currentIndex,
      );
      return;
    }

    if (shouldSuperLike) {
      _animateSwipeOut(
        direction: SwipeDirection.up,
        profile: profile,
        index: state.currentIndex,
      );
      return;
    }

    _animateSwipeBack();
  }

  Future<void> _triggerSwipe(
    SwipeDirection direction,
    ExploreState state,
  ) async {
    if (_isAnimatingSwipe) return;

    final profile = state.currentProfile;

    if (profile == null) return;

    await _buttonAnimationController.reverse();
    await _buttonAnimationController.forward();

    _animateSwipeOut(
      direction: direction,
      profile: profile,
      index: state.currentIndex,
    );
  }

  Future<void> _animateSwipeBack() async {
    final beginHorizontal = _swipeProgress;
    final beginVertical = _verticalSwipeProgress;

    _isAnimatingSwipe = true;

    _swipeController.reset();

    void listener() {
      if (!mounted) return;

      final value = Curves.easeOutCubic.transform(
        _swipeController.value,
      );

      setState(() {
        _swipeProgress = beginHorizontal * (1 - value);
        _verticalSwipeProgress = beginVertical * (1 - value);

        if (_swipeProgress.abs() < 0.01 && _verticalSwipeProgress < 0.01) {
          _swipeDirection = SwipeDirection.none;
        }
      });
    }

    _swipeController.addListener(listener);

    await _swipeController.forward();

    _swipeController.removeListener(listener);

    _isAnimatingSwipe = false;

    _resetSwipe();
  }

  Future<void> _animateSwipeOut({
    required SwipeDirection direction,
    required ProfileModel profile,
    required int index,
  }) async {
    if (_isAnimatingSwipe) return;

    _isAnimatingSwipe = true;

    final beginHorizontal = _swipeProgress;
    final beginVertical = _verticalSwipeProgress;

    final targetHorizontal = switch (direction) {
      SwipeDirection.right => 1.25,
      SwipeDirection.left => -1.25,
      SwipeDirection.up => 0.0,
      SwipeDirection.none => 0.0,
    };

    final targetVertical = direction == SwipeDirection.up ? 1.15 : 0.0;

    setState(() {
      _swipeDirection = direction;
    });

    _swipeController.reset();

    void listener() {
      if (!mounted) return;

      final value = Curves.easeInCubic.transform(
        _swipeController.value,
      );

      setState(() {
        _swipeProgress =
            beginHorizontal + ((targetHorizontal - beginHorizontal) * value);

        _verticalSwipeProgress =
            beginVertical + ((targetVertical - beginVertical) * value);
      });
    }

    _swipeController.addListener(listener);

    await _swipeController.forward();

    _swipeController.removeListener(listener);

    _completeSwipe(
      direction: direction,
      profile: profile,
      index: index,
    );

    _resetSwipe();

    _isAnimatingSwipe = false;
  }

  void _completeSwipe({
    required SwipeDirection direction,
    required ProfileModel profile,
    required int index,
  }) {
    final action = switch (direction) {
      SwipeDirection.right => 'like',
      SwipeDirection.left => 'pass',
      SwipeDirection.up => 'super_like',
      SwipeDirection.none => '',
    };

    final actionType = switch (direction) {
      SwipeDirection.right => SwipeActionType.like,
      SwipeDirection.left => SwipeActionType.pass,
      SwipeDirection.up => SwipeActionType.superLike,
      SwipeDirection.none => SwipeActionType.none,
    };

    if (action.isEmpty) return;

    _showSwipeFeedback(actionType);

    context.read<ExploreBloc>().add(
          SwipeProfile(
            profileId: profile.id,
            action: action,
            index: index,
          ),
        );
  }

  void _showSwipeFeedback(SwipeActionType action) {
    if (action == SwipeActionType.none) return;

    switch (action) {
      case SwipeActionType.like:
        HapticFeedback.mediumImpact();
        break;
      case SwipeActionType.pass:
        HapticFeedback.lightImpact();
        break;
      case SwipeActionType.superLike:
        HapticFeedback.heavyImpact();
        break;
      case SwipeActionType.none:
        break;
    }

    setState(() {
      _feedbackAction = action;
    });

    _feedbackAnimationController
      ..reset()
      ..forward().whenComplete(() {
        if (!mounted) return;

        setState(() {
          _feedbackAction = SwipeActionType.none;
        });

        _feedbackAnimationController.reset();
      });
  }

  void _resetSwipe() {
    if (!mounted) return;

    setState(() {
      _dragOffset = Offset.zero;
      _swipeProgress = 0.0;
      _verticalSwipeProgress = 0.0;
      _swipeDirection = SwipeDirection.none;
    });
  }

  void _showMatchDialog(
    ProfileModel profile,
    String matchId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return MatchDialog(
          profile: profile,
          matchId: matchId,
          onStartChat: () {
            Navigator.pop(context);
            _openMessageComposer(profile);
          },
          onKeepSwiping: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _openMessageComposer(ProfileModel profile) async {
    final controller = TextEditingController();

    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message ${profile.name}',
                    style: AppTheme.blackTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: AppTheme.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Write a first message',
                      filled: true,
                      fillColor: AppColors.inputLightBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isEmpty) return;
                        Navigator.pop(context, value);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Send message'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    controller.dispose();

    if (!mounted || message == null || message.trim().isEmpty) return;

    try {
      final response = await _chatService.sendMessage(
        receiverId: profile.id,
        message: message.trim(),
      );
      final conversationId = _readInt(
        response?['conversationId'] ?? response?['conversation_id'],
      );

      if (!mounted) return;

      if (conversationId <= 0) {
        throw Exception('Conversation was not created');
      }

      Navigator.pushNamed(
        context,
        NamedRoutes.chatScreen,
        arguments: {
          'conversationId': conversationId,
          'userName': profile.name,
          'userAvatar': profile.image,
          'userId': profile.id,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send message: $e'),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _showProfileDetails(ProfileModel profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => _ProfileDetailSheet(
        profile: profile,
        onMessage: () {
          Navigator.pop(context);
          _openMessageComposer(profile);
        },
        onViewProfile: () {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            NamedRoutes.otherProfileScreen,
            arguments: profile.id,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocConsumer<ExploreBloc, ExploreState>(
      listenWhen: (previous, current) {
        return previous.error != current.error ||
            previous.matchId != current.matchId ||
            previous.matchedProfile != current.matchedProfile;
      },
      listener: (context, state) {
        final error = state.error;

        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: AppColors.card,
              behavior: SnackBarBehavior.floating,
            ),
          );

          context.read<ExploreBloc>().add(ClearExploreError());
        }

        final matchId = state.matchId;
        final matchedProfile = state.matchedProfile;

        if (matchId != null && matchedProfile != null) {
          _showMatchDialog(matchedProfile, matchId);

          context.read<ExploreBloc>().add(ClearMatchState());
        }
      },
      buildWhen: (previous, current) {
        return previous.status != current.status ||
            previous.profiles != current.profiles ||
            previous.currentIndex != current.currentIndex ||
            previous.remainingProfiles != current.remainingProfiles ||
            previous.currentFilters != current.currentFilters ||
            previous.isLoading != current.isLoading ||
            previous.isRefreshing != current.isRefreshing ||
            previous.isLoadingMore != current.isLoadingMore;
      },
      builder: (context, state) {
        final currentProfile = state.currentProfile;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: DiscoverHeader(
                            remainingCount: state.remainingProfiles,
                            onFilterTap: () {
                              _showFilters(
                                context,
                                state.currentFilters,
                              );
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                      SliverToBoxAdapter(
                        child: _SwipeContent(
                          state: state,
                          swipeProgress: _swipeProgress,
                          verticalSwipeProgress: _verticalSwipeProgress,
                          swipeDirection: _swipeDirection,
                          onPanStart: _onPanStart,
                          onPanUpdate: (details) {
                            _onPanUpdate(details, state);
                          },
                          onPanEnd: (details) {
                            _onPanEnd(details, state);
                          },
                          onOpenProfile: () {
                            final profile = state.currentProfile;
                            if (profile != null) {
                              _showProfileDetails(profile);
                            }
                          },
                        ),
                      ),
                      if (state.status == ExploreStatus.success &&
                          currentProfile != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                            child: ScaleTransition(
                              scale: _buttonAnimationController,
                              child: ActionButtons(
                                onSkip: () {
                                  _triggerSwipe(
                                    SwipeDirection.left,
                                    state,
                                  );
                                },
                                onSuperLike: () {
                                  _triggerSwipe(
                                    SwipeDirection.up,
                                    state,
                                  );
                                },
                                onLike: () {
                                  _triggerSwipe(
                                    SwipeDirection.right,
                                    state,
                                  );
                                },
                                onMessage: () {
                                  _openMessageComposer(currentProfile);
                                },
                              ),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 40),
                      ),
                    ],
                  ),
                ),
                if (_feedbackAction != SwipeActionType.none)
                  Positioned.fill(
                    child: SwipeFeedbackOverlay(
                      action: _feedbackAction,
                      animation: _feedbackAnimation,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SwipeContent extends StatelessWidget {
  final ExploreState state;
  final double swipeProgress;
  final double verticalSwipeProgress;
  final SwipeDirection swipeDirection;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onOpenProfile;

  const _SwipeContent({
    required this.state,
    required this.swipeProgress,
    required this.verticalSwipeProgress,
    required this.swipeDirection,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ExploreStatus.loading:
      case ExploreStatus.initial:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: LoadingShimmer(),
        );

      case ExploreStatus.refreshing:
        if (state.profiles.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: LoadingShimmer(),
          );
        }

        return _SwipeCards(
          state: state,
          swipeProgress: swipeProgress,
          verticalSwipeProgress: verticalSwipeProgress,
          swipeDirection: swipeDirection,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          onOpenProfile: onOpenProfile,
        );

      case ExploreStatus.empty:
        return NoMoreProfiles(
          onRefresh: () {
            context.read<ExploreBloc>().add(RefreshExploreProfiles());
          },
          message: 'No more profiles in your area\nTry adjusting your filters',
        );

      case ExploreStatus.error:
        return _ExploreError(
          onRetry: () {
            context.read<ExploreBloc>().add(RefreshExploreProfiles());
          },
        );

      case ExploreStatus.loadingMore:
      case ExploreStatus.success:
        if (state.currentProfile == null) {
          return NoMoreProfiles(
            onRefresh: () {
              context.read<ExploreBloc>().add(RefreshExploreProfiles());
            },
            message: 'You\'ve seen everyone!\nNew profiles coming soon',
          );
        }

        return _SwipeCards(
          state: state,
          swipeProgress: swipeProgress,
          verticalSwipeProgress: verticalSwipeProgress,
          swipeDirection: swipeDirection,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          onOpenProfile: onOpenProfile,
        );
    }
  }
}

class _SwipeCards extends StatelessWidget {
  final ExploreState state;
  final double swipeProgress;
  final double verticalSwipeProgress;
  final SwipeDirection swipeDirection;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onOpenProfile;

  const _SwipeCards({
    required this.state,
    required this.swipeProgress,
    required this.verticalSwipeProgress,
    required this.swipeDirection,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpenProfile,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: SwipeCardsStack(
          profiles: state.profiles,
          currentIndex: state.currentIndex,
          swipeProgress: swipeProgress,
          verticalSwipeProgress: verticalSwipeProgress,
          swipeDirection: swipeDirection,
        ),
      ),
    );
  }
}

class _ProfileDetailSheet extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onMessage;
  final VoidCallback onViewProfile;

  const _ProfileDetailSheet({
    required this.profile,
    required this.onMessage,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final images = profile.allImages;
    final interests = profile.interests
            ?.where((interest) => interest.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 280,
                child: images.isEmpty
                    ? _DetailImageFallback(profile: profile)
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: CachedNetworkImage(
                              imageUrl: images[index],
                              width: images.length == 1
                                  ? MediaQuery.sizeOf(context).width - 40
                                  : 220,
                              height: 280,
                              fit: BoxFit.cover,
                              memCacheWidth: 1200,
                              memCacheHeight: 1600,
                              filterQuality: FilterQuality.high,
                              errorWidget: (_, __, ___) {
                                return _DetailImageFallback(profile: profile);
                              },
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${profile.name}${profile.age > 0 ? ', ${profile.age}' : ''}',
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 24,
                        fontWeight: AppTheme.bold,
                      ),
                    ),
                  ),
                  if (profile.verified)
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.info,
                      size: 24,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _DetailPill(
                    icon: Icons.location_on_rounded,
                    text: profile.distanceText,
                  ),
                  if (profile.occupation.trim().isNotEmpty)
                    _DetailPill(
                      icon: Icons.work_rounded,
                      text: profile.occupation,
                    ),
                  if (profile.matchScore > 0)
                    _DetailPill(
                      icon: Icons.favorite_rounded,
                      text: '${profile.matchScore}% match',
                    ),
                ],
              ),
              if (profile.bio.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  profile.bio,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 15,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (interests.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests
                      .map(
                        (interest) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            interest,
                            style: AppTheme.blackTextStyle.copyWith(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: AppTheme.medium,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewProfile,
                      icon: const Icon(Icons.person_rounded),
                      label: const Text('Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text,
                        side:
                            const BorderSide(color: AppColors.lightBorderColor),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onMessage,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputLightBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.medium,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImageFallback extends StatelessWidget {
  final ProfileModel profile;

  const _DetailImageFallback({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.inputLightBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: AppColors.greyColor.withOpacity(0.55),
          size: 72,
        ),
      ),
    );
  }
}

class _ExploreError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ExploreError({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 80,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong. Please refresh the page.',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 48),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
