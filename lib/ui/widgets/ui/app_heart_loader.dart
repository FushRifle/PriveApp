import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';

class AppHeartLoader extends StatefulWidget {
  final double size;

  const AppHeartLoader({
    super.key,
    this.size = 72,
  });

  @override
  State<AppHeartLoader> createState() => _AppHeartLoaderState();
}

class _AppHeartLoaderState extends State<AppHeartLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = _controller.value;
            final beat = math.sin(progress * math.pi * 2);
            final scale = 0.92 + (beat.clamp(0.0, 1.0) * 0.1);
            final ringOpacity = (1 - progress).clamp(0.0, 1.0);

            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 0.72 + progress * 0.34,
                  child: Opacity(
                    opacity: ringOpacity * 0.35,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: progress * math.pi * 2,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: widget.size * 0.11,
                      height: widget.size * 0.11,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: scale,
                  child: CustomPaint(
                    size: Size.square(widget.size * 0.58),
                    painter: _HeartPainter(
                      color: AppColors.primary,
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  const _HeartPainter({
    required this.color,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(width * 0.5, height * 0.88);
    path.cubicTo(
        width * 0.18, height * 0.66, 0, height * 0.46, 0, height * 0.24);
    path.cubicTo(0, height * 0.08, width * 0.13, 0, width * 0.29, 0);
    path.cubicTo(width * 0.39, 0, width * 0.47, height * 0.06, width * 0.5,
        height * 0.16);
    path.cubicTo(width * 0.53, height * 0.06, width * 0.61, 0, width * 0.71, 0);
    path.cubicTo(width * 0.87, 0, width, height * 0.08, width, height * 0.24);
    path.cubicTo(
      width,
      height * 0.46,
      width * 0.82,
      height * 0.66,
      width * 0.5,
      height * 0.88,
    );
    path.close();

    canvas.drawShadow(path, shadowColor, 12, true);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            AppColors.pink,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
  }
}
