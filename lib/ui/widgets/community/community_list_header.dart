import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class CommunityListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String category;
  final int communityCount;
  final int memberCount;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSearch;

  const CommunityListHeader({
    super.key,
    required this.searchController,
    required this.category,
    required this.communityCount,
    required this.memberCount,
    required this.onCategoryChanged,
    required this.onSearch,
  });

  static const categories = [
    '',
    'Creators',
    'Dating',
    'Lifestyle',
    'Music',
    'Tech',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), // Balanced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  icon: Icons.diversity_3_outlined,
                  value: '$communityCount',
                  label: 'Groups',
                ),
              ),
              const SizedBox(width: 12), // Modern, slightly wider spacing
              Expanded(
                child: _SummaryTile(
                  icon: Icons.people_alt_outlined,
                  value: _formatCount(memberCount),
                  label: 'Members',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12), // Unified squarish-smooth radius
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: 'Search groups',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, size: 20),
                  onPressed: onSearch,
                  tooltip: 'Search',
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 38, // Slightly lower profile for a slicker look
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final item = categories[index];
                final selected = item == category;
                return ChoiceChip(
                  selected: selected,
                  label: Text(item.isEmpty ? 'All' : item),
                  onSelected: (_) => onCategoryChanged(item),
                  selectedColor: AppColors.primary.withOpacity(0.12), // Subtle accent tint
                  backgroundColor: AppColors.card,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Matching modern corner profile
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.text,
                    fontWeight: selected ? AppTheme.bold : AppTheme.medium,
                    fontSize: 14,
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: categories.length,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // Tighter, cleaner inner spacing
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12), // Consistent 12dp rounded corners
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08), // Softer badge background
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded( // Added layout safety to prevent text overflows on small screens
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 16, // Cleaned up text hierarchy scale
                    fontWeight: AppTheme.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}