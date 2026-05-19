import 'package:flutter/material.dart';
import 'package:clique/data/models/profile_model.dart';
import 'package:clique/ui/widgets/explore/profile_card.dart';
import 'package:clique/ui/widgets/explore/swipeable_card.dart';

class SwipeCardsStack extends StatelessWidget {
  final List<ProfileModel> profiles; // Changed from Map to ProfileModel
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
    if (currentIndex >= profiles.length) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 480,
      child: Stack(
        children: [
          ..._buildBackgroundCards(),
          _buildTopCard(context),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundCards() {
    final List<Widget> cards = [];
    for (int i = 1; i <= 2; i++) {
      if (currentIndex + i < profiles.length) {
        cards.add(
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: i * 8.0,
            left: i * 4.0,
            right: i * 4.0,
            bottom: i * 4.0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: 0.7 - (i * 0.1),
              child: ProfileCard(
                profile: profiles[currentIndex + i],
                isTop: false,
              ),
            ),
          ),
        );
      }
    }
    return cards;
  }

  Widget _buildTopCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double horizontalOffset = swipeProgress * screenWidth * 1.5;
    double verticalOffset = -verticalSwipeProgress * screenHeight * 0.8;
    double rotation = swipeProgress * 0.5;

    double likeOpacity = 0.0;
    double dislikeOpacity = 0.0;
    double superLikeOpacity = 0.0;

    Color cardBackground = Colors.white;

    switch (swipeDirection) {
      case SwipeDirection.right:
        likeOpacity = swipeProgress.clamp(0.0, 1.0);
        cardBackground = Colors.green.withOpacity(swipeProgress * 0.3);
        break;
      case SwipeDirection.left:
        dislikeOpacity = (-swipeProgress).clamp(0.0, 1.0);
        cardBackground = Colors.red.withOpacity((-swipeProgress) * 0.3);
        break;
      case SwipeDirection.up:
        superLikeOpacity = verticalSwipeProgress.clamp(0.0, 1.0);
        cardBackground = Colors.purple.withOpacity(verticalSwipeProgress * 0.3);
        horizontalOffset = 0;
        rotation = 0;
        break;
      case SwipeDirection.none:
        break;
    }

    return Transform.translate(
      offset: Offset(horizontalOffset, verticalOffset),
      child: Transform.rotate(
        angle: rotation,
        child: SwipeableCard(
          profile: profiles[currentIndex],
          likeOpacity: likeOpacity,
          dislikeOpacity: dislikeOpacity,
          superLikeOpacity: superLikeOpacity,
          cardBackground: cardBackground,
        ),
      ),
    );
  }
}

enum SwipeDirection { none, left, right, up }
