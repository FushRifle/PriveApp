import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

const eventCategories = [
  '',
  'Music',
  'Tech',
  'Business',
  'Sports',
  'Social',
  'Nightlife',
];

class EventsSearchAndFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String category;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSearch;

  const EventsSearchAndFilters({
    super.key,
    required this.searchController,
    required this.category,
    required this.onCategoryChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
       color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.card.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search events',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 22),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: onSearch,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final item in eventCategories) ...[
                  _CategoryTab(
                    label: item.isEmpty ? 'All' : item,
                    selected: item == category,
                    onTap: () => onCategoryChanged(item),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withOpacity(0.14) : AppColors.background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.greyTextStyle.copyWith(
              color: selected ? AppColors.primary : AppColors.text,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
