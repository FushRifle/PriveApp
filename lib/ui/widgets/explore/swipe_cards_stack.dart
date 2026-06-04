import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/models/profile_model.dart';
import 'package:clique/ui/widgets/explore/profile_card.dart';
import 'package:clique/ui/widgets/explore/swipeable_card.dart';

enum SwipeDirection {
  none,
  left,
  right,
  up,
}

class SwipeCardsStack extends StatelessWidget {
  final List<ProfileModel> profiles;
  final int currentIndex;
  final double swipeProgress;
  final double verticalSwipeProgress;
  final SwipeDirection swipeDirection;

  const SwipeCardsStack({
    super.key,
    required this.profiles,
    required this.currentIndex,
    this.swipeProgress = 0.0,
    this.verticalSwipeProgress = 0.0,
    this.swipeDirection = SwipeDirection.none,
  });

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty || currentIndex >= profiles.length) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.sizeOf(context);
    final cardHeight = (size.height * 0.58).clamp(440.0, 540.0);

    return SizedBox(
      height: cardHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int offset = 2; offset >= 1; offset--)
            if (currentIndex + offset < profiles.length)
              _BackgroundCard(
                profile: profiles[currentIndex + offset],
                depth: offset,
              ),
          _TopSwipeCard(
            profile: profiles[currentIndex],
            swipeProgress: swipeProgress,
            verticalSwipeProgress: verticalSwipeProgress,
            swipeDirection: swipeDirection,
          ),
        ],
      ),
    );
  }
}

class _BackgroundCard extends StatelessWidget {
  final ProfileModel profile;
  final int depth;

  const _BackgroundCard({
    required this.profile,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final scale = 1 - (depth * 0.035);
    final topOffset = depth * 10.0;

    return Positioned.fill(
      top: topOffset,
      left: depth * 7.0,
      right: depth * 7.0,
      bottom: 0,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: 1 - (depth * 0.18),
          child: RepaintBoundary(
            child: ProfileCard(
              profile: profile,
              isTop: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopSwipeCard extends StatelessWidget {
  final ProfileModel profile;
  final double swipeProgress;
  final double verticalSwipeProgress;
  final SwipeDirection swipeDirection;

  const _TopSwipeCard({
    required this.profile,
    required this.swipeProgress,
    required this.verticalSwipeProgress,
    required this.swipeDirection,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    double horizontalOffset = swipeProgress * size.width * 1.2;
    double verticalOffset = -verticalSwipeProgress * size.height * 0.72;
    double rotation = swipeProgress * 0.45;

    double likeOpacity = 0.0;
    double dislikeOpacity = 0.0;
    double superLikeOpacity = 0.0;

    Color backgroundColor = AppColors.white;

    switch (swipeDirection) {
      case SwipeDirection.right:
        likeOpacity = swipeProgress.abs().clamp(0.0, 1.0);
        backgroundColor = AppColors.green.withOpacity(likeOpacity * 0.18);
        break;

      case SwipeDirection.left:
        dislikeOpacity = swipeProgress.abs().clamp(0.0, 1.0);
        backgroundColor = AppColors.red.withOpacity(dislikeOpacity * 0.18);
        break;

      case SwipeDirection.up:
        superLikeOpacity = verticalSwipeProgress.clamp(0.0, 1.0);
        horizontalOffset = 0;
        rotation = 0;
        backgroundColor = AppColors.purple.withOpacity(superLikeOpacity * 0.18);
        break;

      case SwipeDirection.none:
        break;
    }

    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(
          horizontalOffset,
          verticalOffset,
        ),
        child: Transform.rotate(
          angle: rotation,
          child: RepaintBoundary(
            child: SwipeableCard(
              profile: profile,
              likeOpacity: likeOpacity,
              dislikeOpacity: dislikeOpacity,
              superLikeOpacity: superLikeOpacity,
              cardBackground: backgroundColor,
            ),
          ),
        ),
      ),
    );
  }
}
