import 'package:flutter/material.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';

class DiscoverHeader extends StatelessWidget {
  final int remainingCount;

  const DiscoverHeader({
    super.key,
    required this.remainingCount,
    required int totalLikes,
    required int totalMatches,
    required bool isLoadingStats,
    required void Function() onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Icon(Icons.explore, color: AppColors.secondary, size: 28),
        ),
        const SizedBox(width: 12),
        Text(
          'Discover People',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(remainingCount),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$remainingCount left',
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.blackTextColor,
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
