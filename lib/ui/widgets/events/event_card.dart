import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/event_model.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';

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
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image Section
                  Stack(
                    children: [
                      _EventImage(
                        imageUrl: event.imageUrl,
                        compact: isCompactImage,
                      ),
                      // Gradient overlay for better tag visibility
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.35),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Tags
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
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
                                icon: Icons.lock_outline_rounded,
                                label: 'Private',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Content Section
                  Padding(
                    padding: EdgeInsets.all(isCompactImage ? 14 : 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title with Date
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DateRail(date: event.startsAt),
                            const SizedBox(width: 14),
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
                                      fontSize: isCompactImage ? 16 : 18,
                                      fontWeight: AppTheme.bold,
                                      height: 1.25,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (event.description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      event.description,
                                      maxLines: isCompactImage ? 1 : 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.greyTextStyle.copyWith(
                                        height: 1.45,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Metadata Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (event.location.isNotEmpty)
                              _MetaChip(
                                icon: Icons.location_on_outlined,
                                label: event.location,
                              ),
                            _MetaChip(
                              icon: Icons.check_circle_outline,
                              label: '${event.goingCount} going',
                            ),
                            _MetaChip(
                              icon: Icons.favorite_border_rounded,
                              label: '${event.interestedCount} interested',
                            ),
                            if (event.host?.name.isNotEmpty == true)
                              _MetaChip(
                                icon: Icons.person_outline_rounded,
                                label: event.host!.name,
                              ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Action Buttons
                        if (isOwner)
                          FilledButton.icon(
                            onPressed: onEdit ?? onTap,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit Event'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 46),
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        event.isGoing
                                            ? Icons.check_circle_rounded
                                            : Icons.calendar_month_rounded,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        event.isGoing ? 'Going' : 'RSVP',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: event.isInterested
                                      ? onLeave
                                      : onInterested,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    side: BorderSide(
                                      color: event.isInterested
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: 1.2,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: event.isInterested
                                        ? AppColors.primary
                                        : AppColors.text,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        event.isInterested
                                            ? Icons.bookmark_rounded
                                            : Icons.bookmark_border_rounded,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        event.isInterested
                                            ? 'Saved'
                                            : 'Interested',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
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
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _monthLabel(local.month),
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 10,
              fontWeight: AppTheme.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${local.day}',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 20,
              fontWeight: AppTheme.bold,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _weekdayLabel(local.weekday),
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
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
    final height = compact ? 130.0 : 170.0;

    if (imageUrl.trim().startsWith('http')) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: AppNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          preset: AppNetworkImagePreset.card,
          placeholder: (_) => _placeholder(height),
          errorBuilder: (_) => _placeholder(height),
        ),
      );
    }

    return _placeholder(height);
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.event_rounded,
            color: AppColors.primary,
            size: 30,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
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
