import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class NotificationEmptyState extends StatelessWidget {
  final bool isError;
  final Future<void> Function()? onRetry;

  const NotificationEmptyState({
    super.key,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.greyColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_none_rounded,
              size: 32,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isError ? 'Could not load activity' : 'You’re all caught up',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isError
                ? 'Check your connection and try again.'
                : 'New likes, comments and connections will appear here.',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}
