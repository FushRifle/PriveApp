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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Search and filter',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 11,
                fontWeight: AppTheme.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Search events',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search, size: 22),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20),
                onPressed: onSearch,
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
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in eventCategories) ...[
                  ChoiceChip(
                    selected: item == category,
                    label: Text(item.isEmpty ? 'All' : item),
                    onSelected: (_) => onCategoryChanged(item),
                    selectedColor: AppColors.primary.withOpacity(0.12),
                    backgroundColor: AppColors.background,
                    showCheckmark: false,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: item == category
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color:
                          item == category ? AppColors.primary : AppColors.text,
                      fontWeight:
                          item == category ? AppTheme.bold : AppTheme.medium,
                      fontSize: 13,
                    ),
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
