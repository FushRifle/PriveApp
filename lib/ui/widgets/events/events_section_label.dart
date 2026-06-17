import 'package:flutter/material.dart';

import 'package:clique/app/configs/theme.dart';

class EventsSectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const EventsSectionLabel({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: AppTheme.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
