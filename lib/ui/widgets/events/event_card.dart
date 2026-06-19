import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onGoing;
  final VoidCallback onInterested;
  final VoidCallback onLeave;
  final bool isOwner;
  final VoidCallback? onEdit;

  const EventCard({
    super.key,
    required this.event,
    required this.compact,
    required this.onTap,
    required this.onGoing,
    required this.onInterested,
    required this.onLeave,
    this.isOwner = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactWidth = constraints.maxWidth < 400;
        final isCompactImage = compact || isCompactWidth;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      _EventImage(
                        imageUrl: event.imageUrl,
                        compact: isCompactImage,
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Row(
                          children: [
                            if (event.category.isNotEmpty)
                              _FloatingTag(
                                icon: Icons.sell_outlined,
                                label: event.category,
                              ),
                            const Spacer(),
                            if (event.isPrivate)
                              _FloatingTag(
                                icon: Icons.lock_outline,
                                label: 'Private',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(isCompactImage ? 12 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DateRail(date: event.startsAt),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    event.title,
                                    maxLines: isCompactImage ? 2 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.blackTextStyle.copyWith(
                                      fontSize: isCompactImage ? 15 : 16,
                                      fontWeight: AppTheme.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (event.description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      event.description,
                                      maxLines: isCompactImage ? 1 : 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.greyTextStyle.copyWith(
                                        height: 1.4,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (event.location.isNotEmpty)
                              _MetaChip(
                                icon: Icons.place_outlined,
                                label: event.location,
                              ),
                            _MetaChip(
                              icon: Icons.check_circle_outline,
                              label: '${event.goingCount} going',
                            ),
                            _MetaChip(
                              icon: Icons.favorite_border,
                              label: '${event.interestedCount} interested',
                            ),
                            if (event.host?.name.isNotEmpty == true)
                              _MetaChip(
                                icon: Icons.person_outline,
                                label: event.host!.name,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (isOwner)
                          FilledButton.icon(
                            onPressed: onEdit ?? onTap,
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            label: const Text('Edit'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: event.isGoing ? onLeave : onGoing,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: event.isGoing
                                        ? AppColors.success.withOpacity(0.12)
                                        : AppColors.primary,
                                    foregroundColor: event.isGoing
                                        ? AppColors.success
                                        : AppColors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    event.isGoing ? 'Going' : 'RSVP',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: event.isInterested
                                      ? onLeave
                                      : onInterested,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    event.isInterested ? 'Saved' : 'Interested',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DateRail extends StatelessWidget {
  final DateTime date;

  const _DateRail({required this.date});

  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _monthLabel(local.month),
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 10,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${local.day}',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 18,
              fontWeight: AppTheme.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            _weekdayLabel(local.weekday),
            style: AppTheme.greyTextStyle.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  final String imageUrl;
  final bool compact;

  const _EventImage({
    required this.imageUrl,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 120.0 : 150.0;

    if (imageUrl.trim().startsWith('http')) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(height),
          errorWidget: (_, __, ___) => _placeholder(height),
        ),
      );
    }

    return _placeholder(height);
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.background,
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.event_outlined,
            color: AppColors.primary,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 11,
              fontWeight: AppTheme.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FloatingTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 10,
              fontWeight: AppTheme.bold,
            ),
          ),
        ],
      ),
    );
  }
}

String _monthLabel(int month) {
  const labels = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return labels[month - 1];
}

String _weekdayLabel(int weekday) {
  const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  return labels[weekday - 1];
}
