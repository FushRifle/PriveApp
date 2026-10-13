import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';

class MainTabHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const MainTabHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
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
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            for (final action in actions) ...[
              action,
              const SizedBox(width: 5),
            ],
          ],
        ),
      ),
    );
  }
}

class MainTabHeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;

  const MainTabHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: AppColors.white,
                  size: 20,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondary),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainTabProfileAction extends StatelessWidget {
  final VoidCallback? onTap;

  const MainTabProfileAction({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserBloc, UserState, Map<String, dynamic>?>(
      selector: (state) => state.currentUser,
      builder: (context, user) {
        final avatar = user?['avatar']?.toString() ?? '';
        final name = user?['name']?.toString() ??
            user?['username']?.toString() ??
            'User';
        final fallback =
            name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

        return Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (onTap != null) {
                onTap!();
              } else {
                Navigator.pushNamed(context, NamedRoutes.profileScreen);
              }
            },
            customBorder: const CircleBorder(),
            child: _HeaderAvatar(
              avatar: avatar,
              fallback: fallback,
            ),
          ),
        );
      },
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  final String avatar;
  final String fallback;

  const _HeaderAvatar({
    required this.avatar,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    const size = 38.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondary,
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: avatar.isNotEmpty && avatar.startsWith('http')
              ? AppNetworkImage(
                  imageUrl: avatar,
                  fit: BoxFit.cover,
                  preset: AppNetworkImagePreset.avatar,
                  placeholder: (_) => _fallback(),
                  errorBuilder: (_) => _fallback(),
                )
              : avatar.isNotEmpty
                  ? Image.asset(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.isDarkMode
          ? AppColors.white.withOpacity(0.08)
          : AppColors.black.withOpacity(0.08),
      alignment: Alignment.center,
      child: Text(
        fallback,
        style: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
          fontSize: 13.3,
        ),
      ),
    );
  }
}
