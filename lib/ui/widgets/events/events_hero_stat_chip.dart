import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class EventsHeroStatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const EventsHeroStatChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.bold,
            ),
          ),
        ],
      ),
    );
  }
}
