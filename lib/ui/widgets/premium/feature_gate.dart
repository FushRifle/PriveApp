import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/subscription/feature_access_cubit.dart';
import 'package:clique/ui/pages/settings/subscribe_page.dart';

class FeatureGate extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? lockedChild;
  final bool hideWhenLocked;

  const FeatureGate({
    super.key,
    required this.permission,
    required this.child,
    this.lockedChild,
    this.hideWhenLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureAccessCubit, FeatureAccessState>(
      builder: (context, state) {
        if (state.access.can(permission)) return child;
        if (hideWhenLocked) return const SizedBox.shrink();
        return lockedChild ??
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscribePage()),
                );
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
}
