import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/ui/widgets/chat/audio_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommentAvatar extends StatelessWidget {
  final String imageUrl;
  final String fallback;
  final double size;

  const CommentAvatar({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        fallback.trim().isNotEmpty ? fallback.trim()[0].toUpperCase() : 'U';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => _fallback(initial),
              errorWidget: (_, __, ___) => _fallback(initial),
            )
          : _fallback(initial),
    );
  }

  Widget _fallback(String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.text,
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CommentActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CommentActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.backgroundColor.withOpacity(0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary.withOpacity(0.18)
                : AppColors.cardBorderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentReactionButton extends StatelessWidget {
  final int likes;
  final int dislikes;
  final bool isLiked;
  final bool isDisliked;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const CommentReactionButton({
    super.key,
    required this.likes,
    required this.dislikes,
    required this.isLiked,
    required this.isDisliked,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    final label = isLiked
        ? (likes > 0 ? '$likes Reacted' : 'Reacted')
        : isDisliked
            ? (dislikes > 0 ? '$dislikes Reacted' : 'Reacted')
            : 'React';

    return CommentActionChip(
      icon: isDisliked ? Icons.thumb_down : Icons.emoji_emotions_outlined,
      label: label,
      selected: isLiked || isDisliked,
      onTap: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.transparent,
          builder: (sheetContext) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.cardBorderColor),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.greyColor.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          CommentReactionTile(
                            icon: Icons.thumb_up,
                            label: 'Like',
                            color: AppColors.primary,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              onLike();
                            },
                          ),
                          CommentReactionTile(
                            icon: Icons.thumb_down,
                            label: 'Dislike',
                            color: AppColors.redAccent,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              onDislike();
                            },
                          ),
                          CommentReactionTile(
                            icon: Icons.emoji_emotions_outlined,
                            label: 'React',
                            color: AppColors.secondary,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              onLike();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CommentActionBar extends StatelessWidget {
  final int likes;
  final int dislikes;
  final int replyCount;
  final bool isLiked;
  final bool isDisliked;
  final String timeLabel;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onReply;

  const CommentActionBar({
    super.key,
    required this.likes,
    required this.dislikes,
    required this.replyCount,
    required this.isLiked,
    required this.isDisliked,
    required this.timeLabel,
    required this.onLike,
    required this.onDislike,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CommentReactionButton(
          likes: likes,
          dislikes: dislikes,
          isLiked: isLiked,
          isDisliked: isDisliked,
          onLike: onLike,
          onDislike: onDislike,
        ),
        CommentActionChip(
          icon: Icons.reply_rounded,
          label: replyCount > 0 ? '$replyCount replies' : 'Reply',
          selected: false,
          onTap: onReply,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            timeLabel,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}

class CommentReactionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const CommentReactionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommentVoiceNoteCard extends StatelessWidget {
  final String avatar;
  final String name;
  final String audioUrl;
  final int duration;
  final String timeLabel;
  final bool isTemp;
  final bool isCompact;

  const CommentVoiceNoteCard({
    super.key,
    required this.avatar,
    required this.name,
    required this.audioUrl,
    required this.duration,
    required this.timeLabel,
    this.isTemp = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding =
        isCompact ? const EdgeInsets.all(12) : const EdgeInsets.all(14);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.backgroundColor.withOpacity(0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CommentAvatar(
                imageUrl: avatar,
                fallback: name,
                size: isCompact ? 34 : 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeLabel,
                      style: AppTheme.greyTextStyle.copyWith(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (isTemp) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorderColor),
            ),
            child: AudioMessageBubble(
              audioUrl: audioUrl,
              isMe: false,
              chatColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            duration > 0 ? '$duration s voice note' : 'Voice note',
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
