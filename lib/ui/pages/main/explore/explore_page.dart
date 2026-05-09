import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/models/profile_model.dart';
import 'package:Prive/data/services/discover/explore_service.dart';
import 'package:Prive/ui/widgets/explore/discover_header.dart';
import 'package:Prive/ui/widgets/explore/no_more_profiles.dart';
import 'package:Prive/ui/widgets/explore/swipe_cards_stack.dart';
import 'package:Prive/ui/widgets/explore/filter_bottom_sheet.dart';
import 'package:Prive/ui/widgets/explore/loading_shimmer.dart';
import 'package:Prive/ui/widgets/explore/match_dialog.dart';
import 'package:Prive/ui/widgets/explore/action_buttons.dart';

enum LoadingState { initial, loading, loaded, empty, error }

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final ExploreService _exploreService = ExploreService();

  List<ProfileModel> _profiles = [];
  int _currentIndex = 0;
  LoadingState _loadingState = LoadingState.initial;
  String _errorMessage = '';

  // Filter parameters
  Map<String, dynamic> _currentFilters = {
    'filter': 'all',
    'page': 1,
    'minAge': null,
    'maxAge': null,
    'distance': null,
    'verifiedOnly': false,
    'sortBy': null,
  };

  // Match stats
  int _totalLikes = 0;
  bool _hasMoreProfiles = true;

  // Animation controllers
  late AnimationController _swipeController;
  late AnimationController _buttonAnimationController;
  late AnimationController _feedbackAnimationController;

  // Swipe animation values
  double _swipeProgress = 0.0;
  double _verticalSwipeProgress = 0.0;
  SwipeDirection _swipeDirection = SwipeDirection.none;
  SwipeActionType _lastSwipeAction = SwipeActionType.none;

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
    _loadInitialData();
  }

  void _initializeControllers() {
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

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadProfiles(),
      _loadStats(),
    ]);
  }

  Future<void> _loadProfiles() async {
    if (_loadingState == LoadingState.loading) return;

    setState(() {
      _loadingState = LoadingState.loading;
      _errorMessage = '';
    });

    try {
      final result = await _exploreService.getExploreProfiles(
        page: _currentFilters['page'],
        filter: _currentFilters['filter'],
        minAge: _currentFilters['minAge'],
        maxAge: _currentFilters['maxAge'],
        distance: _currentFilters['distance'],
        verifiedOnly: _currentFilters['verifiedOnly'],
        sortBy: _currentFilters['sortBy'],
      );

      final newProfiles = result['profiles'] as List<ProfileModel>;
      final hasMore = result['hasMore'] as bool;

      setState(() {
        if (_currentFilters['page'] == 1) {
          _profiles = newProfiles;
          _currentIndex = 0;
        } else {
          _profiles.addAll(newProfiles);
        }
        _loadingState =
            newProfiles.isEmpty ? LoadingState.empty : LoadingState.loaded;
        _hasMoreProfiles = hasMore;
      });
    } catch (e) {
      setState(() {
        _loadingState = LoadingState.error;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profiles: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _exploreService.getStats();
      setState(() {
        _totalLikes = stats['totalLikes'] ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      setState(() {});
    }
  }

  Future<void> _handleSwipeAction(
      SwipeDirection direction, ProfileModel profile) async {
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

    try {
      final response = await _exploreService.swipe(profile.id, action);

      // Check if it's a match
      if (response['isMatch'] == true) {
        _showMatchDialog(profile, response['matchId']);
      }

      // Update stats
      if (actionType == SwipeActionType.like) {
        setState(() => _totalLikes++);
      }

      // Load next profile
      _moveToNextProfile();
    } catch (e) {
      debugPrint('Swipe error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to $action: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      // Don't move to next profile if API call failed
      _resetSwipe();
    }
  }

  void _moveToNextProfile() {
    setState(() {
      _currentIndex++;
      _swipeProgress = 0.0;
      _verticalSwipeProgress = 0.0;
      _swipeDirection = SwipeDirection.none;
    });
    _swipeController.reset();

    if (_currentIndex >= _profiles.length - 2 &&
        _hasMoreProfiles &&
        _loadingState != LoadingState.loading) {
      _currentFilters['page'] = (_currentFilters['page'] as int) + 1;
      _loadProfiles();
    }
  }

  void _showSwipeFeedback(SwipeActionType action) {
    setState(() {
      _lastSwipeAction = action;
    });

    _feedbackAnimationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _lastSwipeAction = SwipeActionType.none;
          });
          _feedbackAnimationController.reset();
        }
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

  void _showFilters() async {
    final newFilters = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilters: _currentFilters,
      ),
    );

    if (newFilters != null && mounted) {
      setState(() {
        _currentFilters = newFilters;
        _currentFilters['page'] = 1;
        _currentFilters['filter'] = 'all';
      });
      _loadProfiles();
    }
  }

  void _refreshProfiles() {
    setState(() {
      _currentFilters['page'] = 1;
      _currentIndex = 0;
    });
    _loadProfiles();
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

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            RefreshIndicator(
              onRefresh: () async => _refreshProfiles(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    DiscoverHeader(
                      remainingCount: _profiles.length - _currentIndex,
                      onFilterTap: _showFilters,
                    ),
                    const SizedBox(height: 24),
                    _buildSwipeContent(),
                    const SizedBox(height: 24),
                    if (_loadingState == LoadingState.loaded &&
                        _currentIndex < _profiles.length)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ActionButtons(
                          onSkip: () => _triggerSwipe(SwipeDirection.left),
                          onSuperLike: () => _triggerSwipe(SwipeDirection.up),
                          onLike: () => _triggerSwipe(SwipeDirection.right),
                          onMessage: () =>
                              _navigateToChat(_profiles[_currentIndex]),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // Swipe feedback overlay
            if (_lastSwipeAction != SwipeActionType.none)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _feedbackAnimationController,
                      builder: (context, child) {
                        final opacity =
                            1.0 - _feedbackAnimationController.value;
                        final scale =
                            0.5 + (_feedbackAnimationController.value * 0.5);

                        return Opacity(
                          opacity: opacity * 0.8,
                          child: Transform.scale(
                            scale: scale,
                            child: _buildFeedbackContent(),
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
  }

  Widget _buildFeedbackContent() {
    late IconData icon;
    late Color color;
    late String text;

    switch (_lastSwipeAction) {
      case SwipeActionType.like:
        icon = Icons.favorite;
        color = Colors.green;
        text = 'LIKED!';
        break;
      case SwipeActionType.pass:
        icon = Icons.close;
        color = Colors.red;
        text = 'PASSED';
        break;
      case SwipeActionType.superLike:
        icon = Icons.star;
        color = Colors.blue;
        text = 'SUPER LIKE!';
        break;
      case SwipeActionType.none:
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

  Widget _buildSwipeContent() {
    switch (_loadingState) {
      case LoadingState.initial:
      case LoadingState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: LoadingShimmer(),
        );

      case LoadingState.empty:
        return NoMoreProfiles(
          onRefresh: _refreshProfiles,
          message: 'No more profiles in your area\nTry adjusting your filters',
        );

      case LoadingState.error:
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
                onPressed: _loadProfiles,
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

      case LoadingState.loaded:
        if (_currentIndex >= _profiles.length) {
          return NoMoreProfiles(
            onRefresh: _refreshProfiles,
            message: 'You\'ve seen everyone!\nNew profiles coming soon',
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: SwipeCardsStack(
              profiles: _profiles,
              currentIndex: _currentIndex,
              swipeProgress: _swipeProgress,
              verticalSwipeProgress: _verticalSwipeProgress,
              swipeDirection: _swipeDirection,
            ),
          ),
        );
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_loadingState != LoadingState.loaded) return;
    setState(() {
      _dragStart = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_loadingState != LoadingState.loaded) return;

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

  void _onPanEnd(DragEndDetails details) {
    if (_loadingState != LoadingState.loaded) return;

    final velocity = details.velocity.pixelsPerSecond;
    final isFastSwipe = velocity.dx.abs() > 800 || velocity.dy.abs() > 800;
    final currentProfile = _profiles[_currentIndex];

    if (_swipeDirection == SwipeDirection.right &&
        (_swipeProgress > _horizontalThreshold ||
            (isFastSwipe && velocity.dx > 0))) {
      _completeSwipe(SwipeDirection.right, currentProfile);
    } else if (_swipeDirection == SwipeDirection.left &&
        (_swipeProgress < -_horizontalThreshold ||
            (isFastSwipe && velocity.dx < 0))) {
      _completeSwipe(SwipeDirection.left, currentProfile);
    } else if (_swipeDirection == SwipeDirection.up &&
        (_verticalSwipeProgress > _verticalThreshold ||
            (isFastSwipe && velocity.dy < -500))) {
      _completeSwipe(SwipeDirection.up, currentProfile);
    } else {
      _resetSwipe();
    }
  }

  void _triggerSwipe(SwipeDirection direction) {
    if (_currentIndex >= _profiles.length) return;

    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });

    setState(() {
      _swipeDirection = direction;
    });

    _swipeController.forward().then((_) {
      _handleSwipeComplete(direction, _profiles[_currentIndex]);
    });
  }

  void _completeSwipe(SwipeDirection direction, ProfileModel profile) {
    setState(() {
      _swipeDirection = direction;
    });

    _swipeController.forward().then((_) {
      _handleSwipeComplete(direction, profile);
    });
  }

  void _handleSwipeComplete(SwipeDirection direction, ProfileModel profile) {
    _handleSwipeAction(direction, profile);
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
    _swipeController.dispose();
    _buttonAnimationController.dispose();
    _feedbackAnimationController.dispose();
    super.dispose();
  }
}

enum SwipeActionType { like, pass, superLike, none }
