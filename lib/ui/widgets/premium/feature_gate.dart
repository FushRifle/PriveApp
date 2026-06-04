import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/subscription/feature_access_cubit.dart';
import 'package:clique/data/models/feature_access_model.dart';
import 'package:clique/ui/pages/settings/subscribe_page.dart';

class FeatureGate extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? lockedChild;
  final bool hideWhenLocked;
  final bool showInlineUpsell;

  const FeatureGate({
    super.key,
    required this.permission,
    required this.child,
    this.lockedChild,
    this.hideWhenLocked = false,
    this.showInlineUpsell = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureAccessCubit, FeatureAccessState>(
      builder: (context, state) {
        if (state.access.can(permission)) return child;
        if (hideWhenLocked) return const SizedBox.shrink();
        if (lockedChild != null) return lockedChild!;
        if (showInlineUpsell) {
          return PremiumUpsellCard(permission: permission);
        }
        return lockedChild ??
            InkWell(
              onTap: () {
                FeatureGate.openSubscribePage(context);
              },
              borderRadius: BorderRadius.circular(8),
              child: Opacity(
                opacity: 0.56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    child,
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.lock_rounded,
                          color: AppColors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
      },
    );
  }

  static void openSubscribePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscribePage()),
    );
  }
}

class PremiumUpsellCard extends StatelessWidget {
  final String permission;
  final String? title;
  final String? description;

  const PremiumUpsellCard({
    super.key,
    required this.permission,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final feature = FeatureAccessPolicy.feature(permission);

    return InkWell(
      onTap: () => FeatureGate.openSubscribePage(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? feature.title,
                    style: AppTheme.blackTextStyle.copyWith(
                      fontSize: 15,
                      fontWeight: AppTheme.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description ?? feature.description,
                    style: AppTheme.greyTextStyle.copyWith(
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
