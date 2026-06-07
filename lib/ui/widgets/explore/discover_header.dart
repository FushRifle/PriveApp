import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';

class DiscoverHeader extends StatelessWidget {
  final int remainingCount;
  final VoidCallback onFilterTap;

  const DiscoverHeader({
    super.key,
    required this.remainingCount,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Brand section
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.explore,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Discover',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const Spacer(),

          const SizedBox(width: 12),
          // Filter button
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              onPressed: onFilterTap,
              icon: const Icon(Icons.filter_list),
              color: AppColors.white,
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
