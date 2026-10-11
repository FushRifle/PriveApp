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
  final ValueChanged<String>? onQueryChanged;
  final VoidCallback? onClear;

  const EventsSearchAndFilters({
    super.key,
    required this.searchController,
    required this.category,
    required this.onCategoryChanged,
    required this.onSearch,
    this.onQueryChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.7),
                  ),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onQueryChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText: 'Search events',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 21),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: searchController,
                      builder: (context, value, _) {
                        if (value.text.trim().isEmpty) {
                          return IconButton(
                            tooltip: 'Search',
                            onPressed: onSearch,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 19,
                            ),
                          );
                        }
                        return IconButton(
                          tooltip: 'Clear search',
                          onPressed: onClear,
                          icon: const Icon(Icons.close_rounded, size: 19),
                        );
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
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
      color:
          selected ? AppColors.primary.withOpacity(0.14) : AppColors.background,
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
