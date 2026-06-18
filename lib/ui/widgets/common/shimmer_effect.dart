import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -0.5,
      end: 1.5,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final baseColor = widget.baseColor ?? AppColors.greyColor;
            final highlightColor = widget.highlightColor ?? Colors.grey.shade300;
            
            return LinearGradient(
              begin: Alignment(
                _shimmerAnimation.value - 1,
                -0.5,
              ),
              end: Alignment(
                _shimmerAnimation.value,
                0.5,
              ),
              colors: [
                baseColor,
                highlightColor.withOpacity(0.7),
                baseColor,
              ],
              stops: const [0.0, 0.3, 0.6],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}