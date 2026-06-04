import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

import 'package:clique/bloc/explore/explore_bloc.dart';

import 'package:clique/core/models/profile_model.dart';

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
            _navigateToChat(profile);
          },
          onKeepSwiping: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _navigateToChat(ProfileModel profile) {
    debugPrint('Navigate to chat with: ${profile.name}');
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
              backgroundColor: AppColors.red,
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
                                  _navigateToChat(currentProfile);
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

  const _SwipeContent({
    required this.state,
    required this.swipeProgress,
    required this.verticalSwipeProgress,
    required this.swipeDirection,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
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

  const _SwipeCards({
    required this.state,
    required this.swipeProgress,
    required this.verticalSwipeProgress,
    required this.swipeDirection,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
