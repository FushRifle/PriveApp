import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class CommunityListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String category;
  final int invitationCount;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSearch;
  final VoidCallback onCreate;

  const CommunityListHeader({
    super.key,
    required this.searchController,
    required this.category,
    required this.invitationCount,
    required this.onCategoryChanged,
    required this.onSearch,
    required this.onCreate,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spaces',
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 30,
                        fontWeight: AppTheme.extraBold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      invitationCount == 0
                          ? 'Find focused groups and useful conversations'
                          : '$invitationCount invitation${invitationCount == 1 ? '' : 's'} waiting',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: onCreate,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  fixedSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add),
                tooltip: 'Create community',
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Search spaces',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.tune),
                onPressed: onSearch,
                tooltip: 'Search',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final item = categories[index];
                final selected = item == category;
                return ChoiceChip(
                  selected: selected,
                  label: Text(item.isEmpty ? 'All' : item),
                  onSelected: (_) => onCategoryChanged(item),
                  selectedColor: AppColors.primary.withOpacity(0.16),
                  backgroundColor: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.text,
                    fontWeight: selected ? AppTheme.bold : AppTheme.medium,
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
}
