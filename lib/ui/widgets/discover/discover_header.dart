import 'package:flutter/material.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';

class DiscoverHeader extends StatelessWidget {
  final int remainingCount;

  const DiscoverHeader({
    super.key,
    required this.remainingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Icon(Icons.explore, color: AppColors.purpleColor, size: 28),
        ),
        const SizedBox(width: 12),
        Text(
          'Discover People',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 24,
          ),
        ),
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(remainingCount),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.purpleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$remainingCount left',
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.purpleColor,
                fontWeight: AppTheme.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
