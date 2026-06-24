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
    final actionColor = AppColors.text;
    final width = MediaQuery.sizeOf(context).width;

    final isTiny = width < 340;
    final isSmall = width < 390;

    final horizontalPadding = isSmall ? 10.0 : 16.0;
    final gap = isTiny
        ? 6.0
        : isSmall
            ? 8.0
            : 10.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        10,
        horizontalPadding,
        16,
      ),
      child: Row(
        children: [
          if (showLikeAction) ...[
            Flexible(
              child: _ResponsiveAction(
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
                compact: isSmall,
              ),
            ),
            SizedBox(width: gap),
          ],
          Flexible(
            child: _ResponsiveAction(
              icon: Icons.mode_comment_outlined,
              label: _formatCount(commentCount),
              color: actionColor,
              onTap: onComment,
              showLabel: !isTiny,
              compact: isSmall,
            ),
          ),
          SizedBox(width: gap),
          Flexible(
            child: _ResponsiveAction(
              icon: Icons.visibility_outlined,
              label: _formatCount(viewCount),
              color: actionColor,
              onTap: null,
              showLabel: !isTiny,
              compact: isSmall,
            ),
          ),
          SizedBox(width: gap),
          Flexible(
            child: _ResponsiveAction(
              icon: Icons.repeat_rounded,
              label: repostCount > 0 ? _formatCount(repostCount) : null,
              color: isReposted ? AppColors.primary : actionColor,
              onTap: onRepost,
              showLabel: !isSmall,
              compact: isSmall,
            ),
          ),
          SizedBox(width: gap),
          _ResponsiveAction(
            icon: isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: isSaved ? AppColors.primary : actionColor,
            onTap: onSave,
            showLabel: false,
            compact: isSmall,
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

class _ResponsiveAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showLabel;
  final bool compact;

  const _ResponsiveAction({
    super.key,
    required this.icon,
    this.label,
    required this.color,
    this.onTap,
    this.onLongPress,
    required this.showLabel,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final shouldShowLabel = showLabel && label != null && label!.isNotEmpty;

    final horizontalPadding = compact
        ? shouldShowLabel
            ? 10.0
            : 9.0
        : shouldShowLabel
            ? 14.0
            : 12.0;

    final verticalPadding = compact ? 9.0 : 11.0;
    final iconSize = compact ? 19.0 : 20.0;
    final fontSize = compact ? 12.0 : 13.0;
    final radius = compact ? 12.0 : 14.0;

    return Material(
      color: AppColors.backgroundColor.withOpacity(0.96),
      borderRadius: BorderRadius.circular(radius),
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
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: color == AppColors.primary || color == AppColors.redAccent
                  ? color.withOpacity(0.16)
                  : AppColors.cardBorderColor,
            ),
            gradient: color == AppColors.primary || color == AppColors.redAccent
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.10),
                      AppColors.backgroundColor.withOpacity(0.94),
                    ],
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: iconSize,
              ),
              if (shouldShowLabel) ...[
                SizedBox(width: compact ? 7 : 9),
                Flexible(
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
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
