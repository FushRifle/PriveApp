import 'package:flutter/material.dart';
import 'package:cirqle/app/configs/colors.dart';
import 'package:cirqle/app/configs/theme.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final VoidCallback onMessage;

  const ActionButtons({
    super.key,
    required this.onSkip,
    required this.onSuperLike,
    required this.onLike,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.close,
          color: AppColors.redColor,
          onTap: onSkip,
          label: 'Skip',
        ),
        _ActionButton(
          icon: Icons.star,
          color: AppColors.primary,
          size: 48,
          onTap: onSuperLike,
          label: 'Super',
        ),
        _ActionButton(
          icon: Icons.favorite,
          color: AppColors.greenColor,
          onTap: onLike,
          label: 'Like',
        ),
        _ActionButton(
          icon: Icons.send,
          color: Colors.blue,
          onTap: onMessage,
          label: 'Message',
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final String? label;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 44,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: size * 0.5,
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(
            label!,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.medium,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
