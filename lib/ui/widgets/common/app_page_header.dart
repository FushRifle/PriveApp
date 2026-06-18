import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class AppPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? avatar;
  final String fallback;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingTap;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;
  final Widget? action;

  const AppPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.avatar,
    this.fallback = 'U',
    this.leadingIcon,
    this.onLeadingTap,
    this.actionIcon,
    this.onActionTap,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.white;
    final text = isDark ? AppColors.white : AppColors.black;
    final muted = isDark ? AppColors.white.withOpacity(0.65) : AppColors.grey;
    final border =
        isDark ? AppColors.white.withOpacity(0.12) : AppColors.border;
    final shadow = isDark
        ? AppColors.black.withOpacity(0.25)
        : AppColors.black.withOpacity(0.06);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 20,
        16,
        12,
      ),
      color: background,
      child: Row(
        children: [
          GestureDetector(
            onTap: onLeadingTap == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onLeadingTap?.call();
                  },
            child: _HeaderAvatar(
              avatar: avatar,
              fallback: fallback,
              icon: leadingIcon,
              background: background,
              text: text,
              size: 44,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.blackTextStyle.copyWith(
                    color: text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.greyTextStyle.copyWith(
                    color: muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (action != null)
            action!
          else if (actionIcon != null)
            GestureDetector(
              onTap: onActionTap == null
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onActionTap?.call();
                    },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  actionIcon,
                  color: text,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  final String? avatar;
  final String fallback;
  final IconData? icon;
  final Color background;
  final Color text;
  final double size;

  const _HeaderAvatar({
    required this.avatar,
    required this.fallback,
    required this.icon,
    required this.background,
    required this.text,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: _content(),
        ),
      ),
    );
  }

  Widget _content() {
    if (icon != null) {
      return Container(
        color: AppColors.primary.withOpacity(0.08),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.primary, size: 20),
      );
    }

    final source = avatar ?? '';
    if (source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: BoxFit.cover,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: AppColors.black.withOpacity(0.08),
      alignment: Alignment.center,
      child: Text(
        fallback,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.35,
        ),
      ),
    );
  }
}
