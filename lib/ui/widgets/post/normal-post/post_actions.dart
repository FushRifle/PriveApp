import 'package:clique/app/configs/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostActions extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final int repostCount;
  final bool isSaved;
  final bool isReposted;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onRepost;
  final VoidCallback? onLikeLongPress;
  final Key? likeActionKey;
  final IconData? selectedReactionIcon;
  final Color? selectedReactionColor;
  final String? selectedReactionLabel;
  final bool showLikeAction;

  const PostActions({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    this.shareCount = 0,
    this.viewCount = 0,
    this.repostCount = 0,
    this.isSaved = false,
    this.isReposted = false,
    required this.onLike,
    required this.onComment,
    required this.onSave,
    required this.onShare,
    required this.onRepost,
    this.onLikeLongPress,
    this.likeActionKey,
    this.selectedReactionIcon,
    this.selectedReactionColor,
    this.selectedReactionLabel,
    this.showLikeAction = true,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = AppColors.textSecondary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTiny = constraints.maxWidth < 340;

        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 8),
          child: Column(
            children: [
              if (viewCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 1),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insights_outlined,
                          size: 12,
                          color: AppColors.textSecondary.withOpacity(0.75),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${_formatCount(viewCount)} views',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                children: [
                  if (showLikeAction) ...[
                    _ResponsiveAction(
                      key: likeActionKey,
                      icon: isLiked
                          ? (selectedReactionIcon ?? Icons.favorite_rounded)
                          : Icons.favorite_border_rounded,
                      label: _formatCount(likeCount),
                      color: isLiked
                          ? (selectedReactionColor ?? AppColors.redAccent)
                          : actionColor,
                      onTap: onLike,
                      onLongPress: onLikeLongPress,
                      showLabel: !isTiny,
                      compact: true,
                      emphasized: isLiked,
                    ),
                  ],
                  _ResponsiveAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: _formatCount(commentCount),
                    color: actionColor,
                    onTap: onComment,
                    showLabel: !isTiny,
                    compact: true,
                  ),
                  _ResponsiveAction(
                    icon: Icons.repeat_rounded,
                    label: repostCount > 0 ? _formatCount(repostCount) : null,
                    color: isReposted ? AppColors.primary : actionColor,
                    onTap: onRepost,
                    showLabel: !isTiny,
                    compact: true,
                    emphasized: isReposted,
                  ),
                  _ResponsiveAction(
                    icon: Icons.send_rounded,
                    label: shareCount > 0 ? _formatCount(shareCount) : null,
                    color: actionColor,
                    onTap: onShare,
                    showLabel: !isTiny,
                    compact: true,
                  ),
                  const Spacer(),
                  _ResponsiveAction(
                    icon: isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isSaved ? AppColors.primary : actionColor,
                    onTap: onSave,
                    showLabel: false,
                    compact: true,
                    emphasized: isSaved,
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

class _ResponsiveAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showLabel;
  final bool compact;
  final bool emphasized;

  const _ResponsiveAction({
    super.key,
    required this.icon,
    this.label,
    required this.color,
    this.onTap,
    this.onLongPress,
    required this.showLabel,
    required this.compact,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final shouldShowLabel = showLabel && label != null && label!.isNotEmpty;

    final horizontalPadding = shouldShowLabel ? 6.0 : 7.0;
    const verticalPadding = 7.0;
    final iconSize = compact ? 20.0 : 21.0;
    const fontSize = 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap?.call();
              },
        onLongPress: onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onLongPress?.call();
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 38,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: emphasized ? 1.1 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize,
                  shadows: emphasized
                      ? [
                          Shadow(
                            color: color.withOpacity(0.28),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              if (shouldShowLabel) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
