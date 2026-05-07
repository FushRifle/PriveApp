import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

enum SwipeActionType { like, pass, superLike, none }

class SwipeFeedbackOverlay extends StatelessWidget {
  final SwipeActionType action;
  final Animation<double> animation;

  const SwipeFeedbackOverlay({
    super.key,
    required this.action,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final opacity = 1.0 - animation.value;
            final scale = 0.5 + (animation.value * 0.5);

            return Opacity(
              opacity: opacity * 0.8,
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: _buildFeedbackContent(),
        ),
      ),
    );
  }

  Widget _buildFeedbackContent() {
    late IconData icon;
    late Color color;
    late String text;

    switch (action) {
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

    return ElasticIn(
      duration: const Duration(milliseconds: 300),
      child: Container(
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
      ),
    );
  }
}
