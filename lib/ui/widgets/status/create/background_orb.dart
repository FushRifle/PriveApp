import 'package:flutter/material.dart';

class BackgroundOrb extends StatelessWidget {
  final Color color;
  final double size;

  const BackgroundOrb({
    super.key,
    required this.color,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            Colors.transparent,
          ],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}