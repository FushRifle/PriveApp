import 'package:flutter/material.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';

class NoMoreProfiles extends StatelessWidget {
  final VoidCallback onRefresh;

  const NoMoreProfiles({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.purpleColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Icon(
                Icons.celebration,
                key: const ValueKey('celebration'),
                size: 64,
                color: AppColors.purpleColor,
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
              'Check back later for new people',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
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
