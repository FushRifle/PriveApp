import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

/// Header for pushed pages. It shares the main-tab header's visual language
/// while retaining a leading navigation action.
class AppPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingTap;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;
  final Widget? action;

  const AppPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingIcon,
    this.onLeadingTap,
    this.actionIcon,
    this.onActionTap,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, topInset + 10, 12, 12),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              _HeaderIconAction(
                icon: leadingIcon!,
                tooltip: 'Back',
                onTap: onLeadingTap,
              ),
              const SizedBox(width: 10),
            ] else
              const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.blackTextStyle.copyWith(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.greyTextStyle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 5),
              action!,
            ] else if (actionIcon != null) ...[
              const SizedBox(width: 5),
              _HeaderIconAction(
                icon: actionIcon!,
                tooltip: title,
                onTap: onActionTap,
              ),
            ],
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _HeaderIconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? AppColors.secondary
            : AppColors.secondary.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap?.call();
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              icon,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
