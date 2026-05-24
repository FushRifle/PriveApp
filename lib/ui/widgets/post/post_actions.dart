import 'package:clique/app/configs/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostActions extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const PostActions({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Row(
        children: [
          _ActionPill(
            icon: isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: _formatCount(likeCount),
            color: isLiked ? Colors.redAccent : Colors.black87,
            onTap: onLike,
          ),
          const SizedBox(width: 10),
          _ActionPill(
            icon: Icons.mode_comment_outlined,
            label: _formatCount(commentCount),
            color: Colors.black87,
            onTap: onComment,
          ),
          const SizedBox(width: 10),
          _IconAction(
            icon: Icons.send_outlined,
            onTap: onShare,
          ),
          const Spacer(),
          _IconAction(
            icon: Icons.bookmark_border_rounded,
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
      borderRadius: BorderRadius.circular(24),
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
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundColor.withOpacity(0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: Colors.black87,
            size: 20,
          ),
        ),
      ),
    );
  }
}
