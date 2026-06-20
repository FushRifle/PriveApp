import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class NotificationHero extends StatelessWidget {
  final String actorName;
  final String type;
  final String time;
  final Color accent;
  final String summary;
  final String content;
  final String postImage;

  const NotificationHero({
    super.key,
    required this.actorName,
    required this.type,
    required this.time,
    required this.accent,
    required this.summary,
    required this.content,
    required this.postImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  _TypeIcon(type: type, accent: accent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actorName,
                          style: AppTheme.blackTextStyle.copyWith(
                            fontSize: 24,
                            color: AppColors.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          style: AppTheme.greyTextStyle.copyWith(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: time,
                  ),
                  const SizedBox(width: 8),
                  if (postImage.isNotEmpty) ...[
                    _InfoChip(
                      icon: Icons.image_rounded,
                      label: 'Has image',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final String type;
  final Color accent;

  const _TypeIcon({required this.type, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withOpacity(0.12),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Icon(
        _iconForType(type),
        size: 28,
        color: accent,
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'like':
      case 'post_like':
        return Icons.favorite_rounded;
      case 'comment':
      case 'post_comment':
      case 'mention':
        return Icons.chat_bubble_rounded;
      case 'follow':
      case 'friend_request':
      case 'friend_accepted':
        return Icons.person_add_alt_1_rounded;
      case 'match':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
