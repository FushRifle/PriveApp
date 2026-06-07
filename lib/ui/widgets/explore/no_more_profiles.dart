import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class NoMoreProfiles extends StatelessWidget {
  final VoidCallback onRefresh;
  final String message;

  const NoMoreProfiles({
    super.key,
    required this.onRefresh,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Icon(
                Icons.info_outline_rounded,
                key: const ValueKey('celebration'),
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No more profiles',
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 20,
                fontWeight: AppTheme.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.trim().isEmpty
                  ? 'Check back later for new people'
                  : message,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(120, 48), // Reduced width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24, // Reduced from 32
                  vertical: 12, // Reduced from 16
                ),
              ),
              child: Text(
                'Refresh',
                style: AppTheme.whiteTextStyle.copyWith(
                  fontWeight: AppTheme.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
