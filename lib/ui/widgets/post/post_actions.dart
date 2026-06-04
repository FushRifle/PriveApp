import 'package:clique/app/configs/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostActions extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int repostCount;
  final bool isSaved;
  final bool isReposted;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onRepost;

  const PostActions({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    this.shareCount = 0,
    this.repostCount = 0,
    this.isSaved = false,
    this.isReposted = false,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.onShare,
    required this.onRepost,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = AppColors.text;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Row(
        children: [
          _ActionPill(
            icon: isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: _formatCount(likeCount),
            color: isLiked ? AppColors.redAccent : actionColor,
            onTap: onLike,
          ),
          const SizedBox(width: 10),
          _ActionPill(
            icon: Icons.mode_comment_outlined,
            label: _formatCount(commentCount),
            color: actionColor,
            onTap: onComment,
          ),
          const SizedBox(width: 10),
          _IconAction(
            icon: Icons.send_outlined,
            label: shareCount > 0 ? _formatCount(shareCount) : null,
            color: actionColor,
            onTap: onShare,
          ),
          const SizedBox(width: 10),
          _IconAction(
            icon: Icons.repeat_rounded,
            label: repostCount > 0 ? _formatCount(repostCount) : null,
            color: isReposted ? AppColors.primary : actionColor,
            onTap: onRepost,
          ),
          const Spacer(),
          _IconAction(
            icon: isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: isSaved ? AppColors.primary : actionColor,
            onTap: onSave,
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count <= 0) return '0';

    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }

    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }

    return count.toString();
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundColor.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppColors.cardBorderColor,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 19,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundColor.withOpacity(0.9),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.cardBorderColor,
            ),
          ),
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: label == null ? 10 : 11,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                  if (label != null) ...[
                    const SizedBox(width: 5),
                    Text(
                      label!,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
