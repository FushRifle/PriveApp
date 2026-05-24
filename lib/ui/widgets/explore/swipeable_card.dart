import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/data/models/profile_model.dart';
import 'package:clique/ui/widgets/explore/profile_card.dart';

class SwipeableCard extends StatelessWidget {
  final ProfileModel profile;
  final double likeOpacity;
  final double dislikeOpacity;
  final double superLikeOpacity;
  final Color cardBackground;

  const SwipeableCard({
    super.key,
    required this.profile,
    this.likeOpacity = 0.0,
    this.dislikeOpacity = 0.0,
    this.superLikeOpacity = 0.0,
    this.cardBackground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ProfileCard(
            profile: profile,
            isTop: true,
          ),
          if (likeOpacity > 0.02)
            _SwipeStamp(
              text: 'LIKE',
              color: AppColors.greenColor,
              opacity: likeOpacity,
              alignment: Alignment.topLeft,
              angle: -0.28,
            ),
          if (dislikeOpacity > 0.02)
            _SwipeStamp(
              text: 'NOPE',
              color: AppColors.redColor,
              opacity: dislikeOpacity,
              alignment: Alignment.topRight,
              angle: 0.28,
            ),
          if (superLikeOpacity > 0.02)
            _SuperLikeStamp(
              opacity: superLikeOpacity,
            ),
        ],
      ),
    );
  }
}

class _SwipeStamp extends StatelessWidget {
  final String text;
  final Color color;
  final double opacity;
  final Alignment alignment;
  final double angle;

  const _SwipeStamp({
    required this.text,
    required this.color,
    required this.opacity,
    required this.alignment,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    final safeOpacity = opacity.clamp(0.0, 1.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 48,
              left: 30,
              right: 30,
            ),
            child: Opacity(
              opacity: safeOpacity,
              child: Transform.rotate(
                angle: angle,
                child: Transform.scale(
                  scale: 0.9 + (safeOpacity * 0.12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: color,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: color,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuperLikeStamp extends StatelessWidget {
  final double opacity;

  const _SuperLikeStamp({
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final safeOpacity = opacity.clamp(0.0, 1.0);
    final scale = 0.65 + (safeOpacity * 0.35);

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: safeOpacity,
            child: Transform.scale(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 82,
                    color: Colors.purple.withOpacity(safeOpacity),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SUPER LIKE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.purple.withOpacity(safeOpacity),
                      fontSize: 31,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
