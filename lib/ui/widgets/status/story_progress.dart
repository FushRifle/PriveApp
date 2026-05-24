import 'package:flutter/material.dart';

class StoryProgress extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Animation<double> animation;

  const StoryProgress({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return Row(
      children: List.generate(
        count,
        (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _ProgressSegment(
                index: index,
                currentIndex: currentIndex,
                animation: animation,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final int index;
  final int currentIndex;
  final Animation<double> animation;

  const _ProgressSegment({
    required this.index,
    required this.currentIndex,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = index < currentIndex;
    final isCurrent = index == currentIndex;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 3,
        color: Colors.white.withOpacity(0.28),
        child: isPast
            ? const ColoredBox(color: Colors.white)
            : isCurrent
                ? AnimatedBuilder(
                    animation: animation,
                    builder: (_, __) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: animation.value.clamp(0.0, 1.0),
                        child: const ColoredBox(color: Colors.white),
                      );
                    },
                  )
                : null,
      ),
    );
  }
}
