import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class EventsEmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const EventsEmptyState({
    super.key,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.card,
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.event_available_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No events yet',
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 19,
                  fontWeight: AppTheme.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create the first event and let people RSVP.',
                textAlign: TextAlign.center,
                style:
                    AppTheme.greyTextStyle.copyWith(fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create event'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
