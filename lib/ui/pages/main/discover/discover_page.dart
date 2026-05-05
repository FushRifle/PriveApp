import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/data/models/profile_model.dart';
import 'package:social_media_app/ui/widgets/discover/action_buttons.dart';
import 'package:social_media_app/ui/widgets/discover/discover_header.dart';
import 'package:social_media_app/ui/widgets/discover/no_more_profiles.dart';
import 'package:social_media_app/ui/widgets/discover/swipe_cards_stack.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with TickerProviderStateMixin {
  late List<ProfileModel> profiles;
  int currentIndex = 0;

  // Animation controllers
  late AnimationController _swipeController;
  late AnimationController _buttonAnimationController;

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
  void initState() {
    super.initState();

    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..addListener(() {
        setState(() {});
      });

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    profiles = [
      ProfileModel(
        name: 'Sophie Anderson',
        age: 24,
        location: 'New York, USA',
        bio:
            'Digital artist & photographer 📸\nExploring the world one frame at a time',
        interests: ['Photography', 'Art', 'Travel', 'Music'],
        image: 'assets/profiles/profile_1.jpeg',
        isOnline: true,
        distance: '2 km away',
        isVerified: true,
        followerCount: 15400,
        postCount: 342,
      ),
      ProfileModel(
        name: 'Marcus Johnson',
        age: 27,
        location: 'Los Angeles, USA',
        bio:
            'Fitness coach & nutritionist 💪\nHelping people transform their lives',
        interests: ['Fitness', 'Health', 'Cooking', 'Motivation'],
        image: 'assets/profiles/profile_2.jpeg',
        isOnline: false,
        distance: '5 km away',
        isVerified: false,
        followerCount: 8900,
        postCount: 156,
      ),
      ProfileModel(
        name: 'Elena Rodriguez',
        age: 23,
        location: 'Miami, USA',
        bio:
            'Travel blogger & food lover 🌎\nCurrently exploring Southeast Asia',
        interests: ['Travel', 'Food', 'Culture', 'Photography'],
        image: 'assets/profiles/profile_3.jpeg',
        isOnline: true,
        distance: '1 km away',
        isVerified: true,
        followerCount: 25600,
        postCount: 523,
      ),
      ProfileModel(
        name: 'Alex Thompson',
        age: 29,
        location: 'Chicago, USA',
        bio: 'Tech entrepreneur & coffee addict ☕\nBuilding the next big thing',
        interests: ['Technology', 'Business', 'Coffee', 'Reading'],
        image: 'assets/profiles/profile_4.jpeg',
        isOnline: false,
        distance: '8 km away',
        isVerified: true,
        followerCount: 32100,
        postCount: 891,
      ),
      ProfileModel(
        name: 'Olivia Chen',
        age: 25,
        location: 'San Francisco, USA',
        bio:
            'Yoga instructor & mindfulness coach 🧘‍♀️\nFinding balance in chaos',
        interests: ['Yoga', 'Meditation', 'Nature', 'Wellness'],
        image: 'assets/profiles/profile_5.jpeg',
        isOnline: true,
        distance: '3 km away',
        isVerified: false,
        followerCount: 12300,
        postCount: 234,
      ),
    ];
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const SizedBox(height: 24),
            DiscoverHeader(
              remainingCount: profiles.length - currentIndex,
            ),
            const SizedBox(height: 24),
            _buildSwipeCardsSection(),
            const SizedBox(height: 24),
            if (currentIndex < profiles.length)
              ActionButtons(
                onSkip: () => _triggerSwipe(SwipeDirection.left),
                onSuperLike: () => _triggerSwipe(SwipeDirection.up),
                onLike: () => _triggerSwipe(SwipeDirection.right),
                onMessage: () => _handleSendMessage(profiles[currentIndex]),
              ),
            const SizedBox(height: 130),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeCardsSection() {
    if (currentIndex >= profiles.length) {
      return NoMoreProfiles(
        onRefresh: () {
          setState(() {
            currentIndex = 0;
          });
        },
      );
    }

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SwipeCardsStack(
        profiles: profiles,
        currentIndex: currentIndex,
        swipeProgress: _swipeProgress,
        verticalSwipeProgress: _verticalSwipeProgress,
        swipeDirection: _swipeDirection,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _dragStart = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      final dx = details.localPosition.dx - _dragStart.dx;
      final dy = details.localPosition.dy - _dragStart.dy;

      _swipeProgress = dx / screenWidth;
      _verticalSwipeProgress = -dy / screenHeight;

      // Determine swipe direction
      if (dx.abs() > dy.abs()) {
        // Horizontal swipe
        _swipeDirection = dx > 0 ? SwipeDirection.right : SwipeDirection.left;
        _verticalSwipeProgress = 0.0;
      } else if (dy < -10) {
        // Upward swipe (super like)
        _swipeDirection = SwipeDirection.up;
        _swipeProgress = 0.0;
        _verticalSwipeProgress = _verticalSwipeProgress.clamp(0.0, 1.0);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Check if swipe exceeded threshold or velocity was high enough
    final velocity = details.velocity.pixelsPerSecond;
    final isFastSwipe = velocity.dx.abs() > 800 || velocity.dy.abs() > 800;

    if (_swipeDirection == SwipeDirection.right &&
        (_swipeProgress > _horizontalThreshold ||
            (isFastSwipe && velocity.dx > 0))) {
      _completeSwipe(SwipeDirection.right);
    } else if (_swipeDirection == SwipeDirection.left &&
        (_swipeProgress < -_horizontalThreshold ||
            (isFastSwipe && velocity.dx < 0))) {
      _completeSwipe(SwipeDirection.left);
    } else if (_swipeDirection == SwipeDirection.up &&
        (_verticalSwipeProgress > _verticalThreshold ||
            (isFastSwipe && velocity.dy < -500))) {
      _completeSwipe(SwipeDirection.up);
    } else {
      _resetSwipe();
    }
  }

  void _triggerSwipe(SwipeDirection direction) {
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });

    setState(() {
      _swipeDirection = direction;
    });

    _swipeController.forward().then((_) {
      _handleSwipeComplete(direction);
    });
  }

  void _completeSwipe(SwipeDirection direction) {
    setState(() {
      _swipeDirection = direction;
    });

    _swipeController.forward().then((_) {
      _handleSwipeComplete(direction);
    });
  }

  void _handleSwipeComplete(SwipeDirection direction) {
    // Get the profile before incrementing the index
    final profile =
        currentIndex < profiles.length ? profiles[currentIndex] : null;

    setState(() {
      currentIndex++;
      _swipeProgress = 0.0;
      _verticalSwipeProgress = 0.0;
      _swipeDirection = SwipeDirection.none;
    });

    _swipeController.reset();

    // Haptic feedback based on action
    switch (direction) {
      case SwipeDirection.right:
        HapticFeedback.mediumImpact();
        print('Liked: ${profile?.name}');
        break;
      case SwipeDirection.left:
        HapticFeedback.lightImpact();
        print('Skipped: ${profile?.name}');
        break;
      case SwipeDirection.up:
        HapticFeedback.heavyImpact();
        print('Super liked: ${profile?.name}');
        _showSuperLikeSnackbar(profile);
        break;
      case SwipeDirection.none:
        break;
    }
  }

  void _resetSwipe() {
    setState(() {
      _swipeProgress = 0.0;
      _verticalSwipeProgress = 0.0;
      _swipeDirection = SwipeDirection.none;
    });
  }

  void _showSuperLikeSnackbar(ProfileModel? profile) {
    if (profile == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Super liked ${profile.name}! ⭐',
          style: AppTheme.whiteTextStyle,
        ),
        backgroundColor: AppColors.purpleColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleSendMessage(ProfileModel profile) {
    HapticFeedback.lightImpact();
    print('Send message to: ${profile.name}');
    // TODO: Navigate to chat with this person
  }
}
