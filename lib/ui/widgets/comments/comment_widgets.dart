import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/ui/widgets/chat/audio_message_bubble.dart';
import 'package:clique/ui/widgets/post/normal-post/post_reaction_picker.dart';
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

class CommentThread {
  final Comment parent;
  final List<Comment> replies;

  CommentThread({
    required this.parent,
    required this.replies,
  });
}

List<CommentThread> groupCommentsIntoThreads(List<Comment> comments) {
  if (comments.isEmpty) return const [];

  final sortedComments = [...comments]..sort((a, b) {
      final byDate = a.createdAt.compareTo(b.createdAt);
      if (byDate != 0) return byDate;
      return a.id.compareTo(b.id);
    });

  final threads = <CommentThread>[];
  final threadIndexByCommentId = <int, int>{};
  final pendingReplies = <int, List<Comment>>{};

  for (final comment in sortedComments) {
    final parentId = comment.parentCommentId;
    if (parentId == null || parentId <= 0) {
      final replies = pendingReplies.remove(comment.id) ?? const <Comment>[];
      final thread = CommentThread(
        parent: comment,
        replies: [...replies]..sort(
            (a, b) {
              final byDate = a.createdAt.compareTo(b.createdAt);
              if (byDate != 0) return byDate;
              return a.id.compareTo(b.id);
            },
          ),
      );
      threadIndexByCommentId[comment.id] = threads.length;
      threads.add(thread);
      continue;
    }

    final threadIndex = threadIndexByCommentId[parentId];
    if (threadIndex != null) {
      threads[threadIndex].replies.add(comment);
      threads[threadIndex].replies.sort(
        (a, b) {
          final byDate = a.createdAt.compareTo(b.createdAt);
          if (byDate != 0) return byDate;
          return a.id.compareTo(b.id);
        },
      );
    } else {
      pendingReplies.putIfAbsent(parentId, () => []).add(comment);
    }
  }

  if (pendingReplies.isNotEmpty) {
    for (final entry in pendingReplies.entries) {
      final orphanReplies = [...entry.value]..sort(
          (a, b) {
            final byDate = a.createdAt.compareTo(b.createdAt);
            if (byDate != 0) return byDate;
            return a.id.compareTo(b.id);
          },
        );

      if (orphanReplies.isEmpty) continue;

      threads.add(
        CommentThread(
          parent: orphanReplies.removeAt(0),
          replies: orphanReplies,
        ),
      );
    }
  }

  threads.sort(
    (a, b) {
      final byDate = a.parent.createdAt.compareTo(b.parent.createdAt);
      if (byDate != 0) return byDate;
      return a.parent.id.compareTo(b.parent.id);
    },
  );

  return threads;
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

class CommentReactionButton extends StatefulWidget {
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
  State<CommentReactionButton> createState() => _CommentReactionButtonState();
}

class _CommentReactionButtonState extends State<CommentReactionButton> {
  final GlobalKey _reactionButtonKey = GlobalKey();

  void _openReactionPicker() {
    final buttonBox =
        _reactionButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null || !buttonBox.hasSize) {
      showPostReactionPicker(
        context,
        onSelected: _applyReaction,
      );
      return;
    }

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) {
      showPostReactionPicker(
        context,
        onSelected: _applyReaction,
      );
      return;
    }

    final topLeft = buttonBox.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = buttonBox.localToGlobal(
      buttonBox.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final anchor = Rect.fromLTRB(
      topLeft.dx,
      topLeft.dy,
      bottomRight.dx,
      bottomRight.dy,
    );

    showPostReactionPicker(
      context,
      anchorRect: anchor,
      onSelected: _applyReaction,
    );
  }

  void _applyReaction(PostReaction reaction) {
    if (reaction.label == 'Angry') {
      widget.onDislike();
      return;
    }

    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isLiked
        ? (widget.likes > 0 ? '${widget.likes} Reactions' : 'Reaction')
        : widget.isDisliked
            ? (widget.dislikes > 0 ? '${widget.dislikes} dislikes' : 'dislike')
            : 'React';

    return CommentActionChip(
      key: _reactionButtonKey,
      icon:
          widget.isDisliked ? Icons.thumb_down : Icons.emoji_emotions_outlined,
      label: label,
      selected: widget.isLiked || widget.isDisliked,
      onTap: () {
        HapticFeedback.mediumImpact();
        _openReactionPicker();
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card.withOpacity(isCompact ? 0.06 : 0.10),
            AppColors.backgroundColor.withOpacity(0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.blackTextStyle.copyWith(
                              fontSize: isCompact ? 13 : 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            duration > 0 ? '${duration}s' : 'voice',
                            style: AppTheme.greyTextStyle.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
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
              color: AppColors.cardColor.withOpacity(0.96),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
            child: AudioMessageBubble(
              audioUrl: audioUrl,
              isMe: false,
              chatColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Voice note',
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              Text(
                timeLabel,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommentThreadCard extends StatelessWidget {
  final CommentThread thread;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<Comment> onLike;
  final ValueChanged<Comment> onDislike;
  final ValueChanged<Comment> onReply;

  const CommentThreadCard({
    super.key,
    required this.thread,
    required this.isFirst,
    required this.isLast,
    required this.onLike,
    required this.onDislike,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final replies = thread.replies;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThreadCommentEntry(
            comment: thread.parent,
            isRoot: true,
            isFirst: isFirst,
            isLast: isLast && replies.isEmpty,
            onLike: onLike,
            onDislike: onDislike,
            onReply: onReply,
          ),
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${replies.length} repl${replies.length == 1 ? 'y' : 'ies'}',
                    style: AppTheme.greyTextStyle.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < replies.length; index++) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _ThreadCommentEntry(
                  comment: replies[index],
                  isRoot: false,
                  isFirst: index == 0,
                  isLast: index == replies.length - 1,
                  compact: true,
                  onLike: onLike,
                  onDislike: onDislike,
                  onReply: onReply,
                ),
              ),
              if (index != replies.length - 1) const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _ThreadCommentEntry extends StatelessWidget {
  final Comment comment;
  final bool isRoot;
  final bool isFirst;
  final bool isLast;
  final bool compact;
  final ValueChanged<Comment> onLike;
  final ValueChanged<Comment> onDislike;
  final ValueChanged<Comment> onReply;

  const _ThreadCommentEntry({
    required this.comment,
    required this.isRoot,
    required this.isFirst,
    required this.isLast,
    required this.onLike,
    required this.onDislike,
    required this.onReply,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 34.0 : 40.0;
    final contentFontSize = compact ? 13.0 : 14.0;

    return Stack(
      children: [
        if (isRoot)
          Positioned(
            left: avatarSize / 2 - 0.75,
            top: isFirst ? avatarSize + 2 : -12,
            bottom: isLast ? 16 : -12,
            child: Container(
              width: 1.5,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(left: isRoot ? 0 : 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommentAvatar(
                imageUrl: comment.userAvatar,
                fallback: comment.userName,
                size: avatarSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            comment.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.greyTextStyle.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 13 : 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.formattedTimeAgo,
                          style: AppTheme.greyTextStyle.copyWith(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    if (comment.hasVoiceNote)
                      CommentVoiceNoteCard(
                        avatar: comment.userAvatar,
                        name: comment.userName,
                        audioUrl: comment.audioUrl,
                        duration: comment.duration,
                        timeLabel: comment.formattedTimeAgo,
                        isTemp: false,
                        isCompact: compact,
                      )
                    else
                      Text(
                        comment.content,
                        style: AppTheme.greyTextStyle.copyWith(
                          fontSize: contentFontSize,
                          height: 1.45,
                          color: AppColors.text,
                          fontWeight:
                              compact ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    const SizedBox(height: 8),
                    CommentActionBar(
                      likes: comment.likes,
                      dislikes: comment.dislikes,
                      replyCount: comment.replyCount,
                      isLiked: comment.isLiked,
                      isDisliked: comment.isDisliked,
                      timeLabel: comment.formattedTimeAgo,
                      onLike: () => onLike(comment),
                      onDislike: () => onDislike(comment),
                      onReply: () => onReply(comment),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
