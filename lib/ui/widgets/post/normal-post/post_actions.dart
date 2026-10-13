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
        final hasEngagement = likeCount > 0 ||
            commentCount > 0 ||
            repostCount > 0 ||
            shareCount > 0 ||
            viewCount > 0;
        final secondaryMetrics = <String>[
          if (commentCount > 0)
            '${_formatCount(commentCount)} ${commentCount == 1 ? 'comment' : 'comments'}',
          if (repostCount > 0)
            '${_formatCount(repostCount)} ${repostCount == 1 ? 'repost' : 'reposts'}',
          if (shareCount > 0)
            '${_formatCount(shareCount)} ${shareCount == 1 ? 'share' : 'shares'}',
          if (viewCount > 0) '${_formatCount(viewCount)} views',
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(9, 0, 9, 6),
          child: Column(
            children: [
              if (hasEngagement)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 7),
                  child: Row(
                    children: [
                      if (likeCount > 0) ...[
                        Icon(
                          Icons.favorite_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatCount(likeCount)} ${likeCount == 1 ? 'reaction' : 'reactions'}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (secondaryMetrics.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            secondaryMetrics.join('  ·  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else
                        const Spacer(),
                    ],
                  ),
                ),
              if (hasEngagement)
                Divider(
                  height: 1,
                  thickness: 0.6,
                  color: AppColors.border.withOpacity(0.5),
                ),
              const SizedBox(height: 1),
              Row(
                children: [
                  if (showLikeAction) ...[
                    Expanded(
                      flex: isTiny ? 1 : 2,
                      child: _ResponsiveAction(
                        key: likeActionKey,
                        icon: isLiked
                            ? (selectedReactionIcon ?? Icons.favorite_rounded)
                            : Icons.favorite_border_rounded,
                        label: isLiked ? (_selectedLabelOrDefault()) : 'React',
                        color: isLiked
                            ? (selectedReactionColor ?? AppColors.redAccent)
                            : actionColor,
                        onTap: onLike,
                        onLongPress: onLikeLongPress,
                        showLabel: !isTiny,
                        compact: true,
                        emphasized: isLiked,
                      ),
                    ),
                  ],
                  Expanded(
                    flex: isTiny ? 1 : 2,
                    child: _ResponsiveAction(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Reply',
                      color: actionColor,
                      onTap: onComment,
                      showLabel: !isTiny,
                      compact: true,
                    ),
                  ),
                  Expanded(
                    flex: isTiny ? 1 : 2,
                    child: _ResponsiveAction(
                      icon: Icons.repeat_rounded,
                      label: 'Repost',
                      color: isReposted ? AppColors.primary : actionColor,
                      onTap: onRepost,
                      showLabel: !isTiny,
                      compact: true,
                      emphasized: isReposted,
                    ),
                  ),
                  Expanded(
                    child: _ResponsiveAction(
                      icon: Icons.near_me_outlined,
                      tooltip: 'Share',
                      color: actionColor,
                      onTap: onShare,
                      showLabel: false,
                      compact: true,
                    ),
                  ),
                  Expanded(
                    child: _ResponsiveAction(
                      icon: isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      tooltip: isSaved ? 'Remove bookmark' : 'Bookmark',
                      color: isSaved ? AppColors.primary : actionColor,
                      onTap: onSave,
                      showLabel: false,
                      compact: true,
                      emphasized: isSaved,
                    ),
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

  String _selectedLabelOrDefault() {
    final label = selectedReactionLabel?.trim();
    return label == null || label.isEmpty ? 'React' : label;
  }
}

class _ResponsiveAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? tooltip;
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
    this.tooltip,
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

    final horizontalPadding = shouldShowLabel ? 4.0 : 3.0;
    const verticalPadding = 6.0;
    final iconSize = compact ? 21.0 : 22.0;
    const fontSize = 10.5;

    final action = Material(
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 40,
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

    if (tooltip == null) return action;
    return Tooltip(message: tooltip!, child: action);
  }
}
