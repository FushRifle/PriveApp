import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/models/profile_model.dart';
import 'package:Prive/bloc/explore/explore_bloc.dart';
import 'package:Prive/ui/widgets/explore/discover_header.dart';
import 'package:Prive/ui/widgets/explore/no_more_profiles.dart';
import 'package:Prive/ui/widgets/explore/swipe_cards_stack.dart';
import 'package:Prive/ui/widgets/explore/filter_bottom_sheet.dart';
import 'package:Prive/ui/widgets/explore/loading_shimmer.dart';
import 'package:Prive/ui/widgets/explore/match_dialog.dart';
import 'package:Prive/ui/widgets/explore/action_buttons.dart';

enum SwipeActionType { like, pass, superLike, none }

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late PageController _pageController;

  // Animation controllers
  late AnimationController _swipeController;
  late AnimationController _buttonAnimationController;
  late AnimationController _feedbackAnimationController;

  // Swipe animation values
  double _swipeProgress = 0.0;
  double _verticalSwipeProgress = 0.0;
  SwipeDirection _swipeDirection = SwipeDirection.none;

  // Drag tracking
  Offset _dragStart = Offset.zero;

  // Thresholds
  static const double _horizontalThreshold = 0.3;
  static const double _verticalThreshold = 0.3;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _pageController = PageController();
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  void _showSwipeFeedback(SwipeActionType action) {
    _feedbackAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _feedbackAnimationController.reset();
      });
    });

    // Haptic feedback
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
  }

  void _showMatchDialog(ProfileModel profile, String matchId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MatchDialog(
        profile: profile,
        matchId: matchId,
        onStartChat: () {
          Navigator.pop(context);
          _navigateToChat(profile);
        },
        onKeepSwiping: () => Navigator.pop(context),
      ),
    );
  }

  void _navigateToChat(ProfileModel profile) {
    debugPrint('Navigate to chat with: ${profile.name}');
    // TODO: Implement navigation
  }

  void _showFilters(
      BuildContext context, Map<String, dynamic> currentFilters) async {
    final newFilters = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilters: currentFilters,
      ),
    );

    if (newFilters != null && mounted) {
      final updatedFilters = {
        ...newFilters,
        'page': 1,
        'filter': 'all',
      };
      context
          .read<ExploreBloc>()
          .add(UpdateExploreFilters(filters: updatedFilters));
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _dragStart = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final exploreState = context.read<ExploreBloc>().state;
    if (exploreState.status != ExploreStatus.success) return;

    setState(() {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      final dx = details.localPosition.dx - _dragStart.dx;
      final dy = details.localPosition.dy - _dragStart.dy;

      _swipeProgress = dx / screenWidth;
      _verticalSwipeProgress = -dy / screenHeight;

      if (dx.abs() > dy.abs()) {
        _swipeDirection = dx > 0 ? SwipeDirection.right : SwipeDirection.left;
        _verticalSwipeProgress = 0.0;
      } else if (dy < -10) {
        _swipeDirection = SwipeDirection.up;
        _swipeProgress = 0.0;
        _verticalSwipeProgress = _verticalSwipeProgress.clamp(0.0, 1.0);
      }
    });
  }

  void _onPanEnd(
      DragEndDetails details, BuildContext context, ExploreState state) {
    if (state.status != ExploreStatus.success) return;
    if (state.currentProfile == null) return;

    final velocity = details.velocity.pixelsPerSecond;
    final isFastSwipe = velocity.dx.abs() > 800 || velocity.dy.abs() > 800;
    final currentProfile = state.currentProfile!;
    final currentIndex = state.currentIndex;

    if (_swipeDirection == SwipeDirection.right &&
        (_swipeProgress > _horizontalThreshold ||
            (isFastSwipe && velocity.dx > 0))) {
      _completeSwipe(
          SwipeDirection.right, currentProfile, currentIndex, context);
    } else if (_swipeDirection == SwipeDirection.left &&
        (_swipeProgress < -_horizontalThreshold ||
            (isFastSwipe && velocity.dx < 0))) {
      _completeSwipe(
          SwipeDirection.left, currentProfile, currentIndex, context);
    } else if (_swipeDirection == SwipeDirection.up &&
        (_verticalSwipeProgress > _verticalThreshold ||
            (isFastSwipe && velocity.dy < -500))) {
      _completeSwipe(SwipeDirection.up, currentProfile, currentIndex, context);
    } else {
      _resetSwipe();
    }
  }

  void _triggerSwipe(
      SwipeDirection direction, BuildContext context, ExploreState state) {
    if (state.currentProfile == null) return;

    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });

    setState(() {
      _swipeDirection = direction;
    });

    _swipeController.forward().then((_) {
      _handleSwipeComplete(
          direction, state.currentProfile!, state.currentIndex, context);
    });
  }

  void _completeSwipe(SwipeDirection direction, ProfileModel profile, int index,
      BuildContext context) {
    setState(() {
      _swipeDirection = direction;
    });

    _swipeController.forward().then((_) {
      _handleSwipeComplete(direction, profile, index, context);
    });
  }

  void _handleSwipeComplete(SwipeDirection direction, ProfileModel profile,
      int index, BuildContext context) {
    String action;
    SwipeActionType actionType;

    switch (direction) {
      case SwipeDirection.right:
        action = 'like';
        actionType = SwipeActionType.like;
        break;
      case SwipeDirection.left:
        action = 'pass';
        actionType = SwipeActionType.pass;
        break;
      case SwipeDirection.up:
        action = 'super_like';
        actionType = SwipeActionType.superLike;
        break;
      case SwipeDirection.none:
        return;
    }

    _showSwipeFeedback(actionType);

    // Dispatch swipe event to BLoC
    context.read<ExploreBloc>().add(SwipeProfile(
          profileId: profile.id,
          action: action,
          index: index,
        ));
  }

  void _resetSwipe() {
    setState(() {
      _swipeProgress = 0.0;
      _verticalSwipeProgress = 0.0;
      _swipeDirection = SwipeDirection.none;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _swipeController.dispose();
    _buttonAnimationController.dispose();
    _feedbackAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return BlocProvider(
      create: (context) => ExploreBloc()
        ..add(LoadExploreProfiles())
        ..add(LoadExploreStats()),
      child: BlocConsumer<ExploreBloc, ExploreState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.error}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<ExploreBloc>().add(ClearExploreError());
          }

          // Check for match (would need to be handled via a separate stream or callback)
          // For now, we'll handle matches in the swipe response
        },
        builder: (context, state) {
          final remainingProfiles = state.remainingProfiles;
          final currentProfile = state.currentProfile;
          final isLoading = state.isLoading;
          final status = state.status;

          return Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  // Main content
                  RefreshIndicator(
                    onRefresh: () async {
                      context.read<ExploreBloc>().add(RefreshExploreProfiles());
                      context.read<ExploreBloc>().add(LoadExploreStats());
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          DiscoverHeader(
                            remainingCount: remainingProfiles,
                            onFilterTap: () =>
                                _showFilters(context, state.currentFilters),
                          ),
                          const SizedBox(height: 24),
                          _buildSwipeContent(context, state),
                          const SizedBox(height: 24),
                          if (status == ExploreStatus.success &&
                              currentProfile != null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: ActionButtons(
                                onSkip: () => _triggerSwipe(
                                    SwipeDirection.left, context, state),
                                onSuperLike: () => _triggerSwipe(
                                    SwipeDirection.up, context, state),
                                onLike: () => _triggerSwipe(
                                    SwipeDirection.right, context, state),
                                onMessage: () =>
                                    _navigateToChat(currentProfile),
                              ),
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  // Swipe feedback overlay
                  if (state.lastSwipeAction != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _feedbackAnimationController,
                            builder: (context, child) {
                              final opacity =
                                  1.0 - _feedbackAnimationController.value;
                              final scale = 0.5 +
                                  (_feedbackAnimationController.value * 0.5);

                              return Opacity(
                                opacity: opacity * 0.8,
                                child: Transform.scale(
                                  scale: scale,
                                  child: _buildFeedbackContent(
                                      state.lastSwipeAction!),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackContent(String action) {
    late IconData icon;
    late Color color;
    late String text;

    switch (action) {
      case 'like':
        icon = Icons.favorite;
        color = Colors.green;
        text = 'LIKED!';
        break;
      case 'pass':
        icon = Icons.close;
        color = Colors.red;
        text = 'PASSED';
        break;
      case 'super_like':
        icon = Icons.star;
        color = Colors.blue;
        text = 'SUPER LIKE!';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeContent(BuildContext context, ExploreState state) {
    switch (state.status) {
      case ExploreStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: LoadingShimmer(),
        );

      case ExploreStatus.empty:
        return NoMoreProfiles(
          onRefresh: () {
            context.read<ExploreBloc>().add(RefreshExploreProfiles());
          },
          message: 'No more profiles in your area\nTry adjusting your filters',
        );

      case ExploreStatus.error:
        return Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Something went wrong, refresh page.',
                style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<ExploreBloc>().add(RefreshExploreProfiles());
                },
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
        );

      case ExploreStatus.success:
        if (state.currentProfile == null) {
          return NoMoreProfiles(
            onRefresh: () {
              context.read<ExploreBloc>().add(RefreshExploreProfiles());
            },
            message: 'You\'ve seen everyone!\nNew profiles coming soon',
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: (details) => _onPanEnd(details, context, state),
            child: SwipeCardsStack(
              profiles: state.profiles,
              currentIndex: state.currentIndex,
              swipeProgress: _swipeProgress,
              verticalSwipeProgress: _verticalSwipeProgress,
              swipeDirection: _swipeDirection,
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
