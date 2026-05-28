import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';

enum SwipeActionType {
  like,
  pass,
  superLike,
  none,
}

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
    if (action == SwipeActionType.none) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final value = animation.value;
            final opacity = (1 - value).clamp(0.0, 1.0);
            final scale = 0.72 + (value * 0.28);

            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: _FeedbackContent(
            action: action,
          ),
        ),
      ),
    );
  }
}

class _FeedbackContent extends StatelessWidget {
  final SwipeActionType action;

  const _FeedbackContent({
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final data = _dataForAction(action);

    if (data == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.45),
            blurRadius: 22,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data.icon,
            color: AppColors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            data.text,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  _FeedbackData? _dataForAction(SwipeActionType action) {
    switch (action) {
      case SwipeActionType.like:
        return const _FeedbackData(
          icon: Icons.favorite,
          color: AppColors.green,
          text: 'LIKED!',
        );

      case SwipeActionType.pass:
        return const _FeedbackData(
          icon: Icons.close,
          color: AppColors.red,
          text: 'PASSED',
        );

      case SwipeActionType.superLike:
        return const _FeedbackData(
          icon: Icons.star,
          color: AppColors.blue,
          text: 'SUPER LIKE!',
        );

      case SwipeActionType.none:
        return null;
    }
  }
}

class _FeedbackData {
  final IconData icon;
  final Color color;
  final String text;

  const _FeedbackData({
    required this.icon,
    required this.color,
    required this.text,
  });
}
