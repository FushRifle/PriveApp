import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

enum InboxFilter { all, unread, pinned, archive }

class InboxToolbar extends StatelessWidget {
  final TextEditingController controller;
  final InboxFilter filter;
  final ValueChanged<InboxFilter> onFilterChanged;
  final VoidCallback onClearSearch;

  const InboxToolbar({
    super.key,
    required this.controller,
    required this.filter,
    required this.onFilterChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: AppTheme.blackTextStyle.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search messages',
                hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 12.5),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: controller.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: onClearSearch,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: InboxFilter.values.map((value) {
                final isSelected = filter == value;
                final label = switch (value) {
                  InboxFilter.all => 'All chats',
                  InboxFilter.unread => 'Unread',
                  InboxFilter.pinned => 'Pinned',
                  InboxFilter.archive => 'Archived',
                };
                final icon = switch (value) {
                  InboxFilter.all => Icons.chat_bubble_outline_rounded,
                  InboxFilter.unread => Icons.mark_chat_unread_outlined,
                  InboxFilter.pinned => Icons.push_pin_outlined,
                  InboxFilter.archive => Icons.archive_outlined,
                };

                return Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: Material(
                    color: isSelected
                        ? AppColors.secondary.withOpacity(0.12)
                        : AppColors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => onFilterChanged(value),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondary.withOpacity(0.35)
                                : AppColors.border.withOpacity(0.45),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 15,
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: AppTheme.blackTextStyle.copyWith(
                                color: isSelected
                                    ? AppColors.secondary
                                    : AppColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: isSelected
                                    ? AppTheme.bold
                                    : AppTheme.medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
