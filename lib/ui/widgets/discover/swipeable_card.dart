import 'package:flutter/material.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/data/profile_model.dart';
import 'package:social_media_app/ui/widgets/discover/profile_card.dart';

class SwipeableCard extends StatelessWidget {
  final ProfileModel profile; // Changed from Map to ProfileModel
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
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          ProfileCard(
            profile: profile,
            isTop: true,
          ),
          // Like Stamp
          if (likeOpacity > 0)
            Opacity(
              opacity: likeOpacity,
              child: _buildStamp(
                text: 'LIKE',
                color: AppColors.greenColor,
                isLeft: true,
                topOffset: 40 + (likeOpacity * 30),
              ),
            ),
          // Dislike Stamp
          if (dislikeOpacity > 0)
            Opacity(
              opacity: dislikeOpacity,
              child: _buildStamp(
                text: 'NOPE',
                color: AppColors.redColor,
                isLeft: false,
                topOffset: 40 + (dislikeOpacity * 30),
              ),
            ),
          // Super Like Stamp
          if (superLikeOpacity > 0)
            Opacity(
              opacity: superLikeOpacity,
              child: _buildSuperLikeStamp(superLikeOpacity),
            ),
        ],
      ),
    );
  }

  Widget _buildStamp({
    required String text,
    required Color color,
    required bool isLeft,
    required double topOffset,
  }) {
    return Positioned(
      top: topOffset,
      left: isLeft ? 30 : null,
      right: isLeft ? null : 30,
      child: Transform.rotate(
        angle: isLeft ? -0.3 : 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuperLikeStamp(double opacity) {
    return Positioned(
      bottom: 200,
      left: 0,
      right: 0,
      child: Transform.scale(
        scale: 0.5 + (opacity * 0.5),
        child: Column(
          children: [
            Icon(
              Icons.star,
              size: 80 * (0.5 + opacity * 0.5),
              color: Colors.purple.withOpacity(opacity),
            ),
            const SizedBox(height: 8),
            Text(
              'SUPER LIKE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.purple.withOpacity(opacity),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
