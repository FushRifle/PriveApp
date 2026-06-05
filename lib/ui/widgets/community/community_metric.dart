import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class CommunityMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const CommunityMetric({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.medium,
            ),
          ),
        ),
      ],
    );
  }
}
