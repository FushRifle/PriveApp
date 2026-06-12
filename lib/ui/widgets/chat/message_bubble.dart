import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/ui/widgets/chat/audio_message_bubble.dart';
import 'package:clique/ui/widgets/ui/image_viewer.dart';
import 'package:clique/ui/widgets/ui/video_viewer.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final String userAvatar;
  final Color chatColor;
  final int index;
  final VoidCallback? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.userAvatar,
    required this.chatColor,
    required this.index,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isOwn;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otherBubbleColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final otherTextColor = isDark ? AppColors.darkText : AppColors.lightText;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 6),
      bottomRight: Radius.circular(isMe ? 6 : 18),
    );

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: 8, top: 4, left: isMe ? 42 : 2, right: isMe ? 2 : 42),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              _Avatar(userAvatar: userAvatar),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => _showMessageOptions(context),
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  final shouldReply =
                      isMe ? velocity < -180 : velocity > 180;
                  if (shouldReply) {
                    onReply?.call();
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isMe ? chatColor : otherBubbleColor,
                    borderRadius: borderRadius,
                    border: isMe
                        ? null
                        : Border.all(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : AppColors.lightCardBorder,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.black.withOpacity(isDark ? 0.16 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.replyToId != null) _buildReplyPreview(isMe),
                      _buildMessageContent(isMe, context, otherTextColor),
                      const SizedBox(height: 4),
                      _buildTimeAndStatus(isMe),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            isMe ? AppColors.white.withOpacity(0.15) : AppColors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.reply,
              size: 12, color: isMe ? AppColors.white70 : AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.replyToSender}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isMe ? AppColors.white70 : AppColors.primary,
                  ),
                ),
                Text(
                  message.replyToMessage ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? AppColors.white60 : AppColors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    bool isMe,
    BuildContext context,
    Color otherTextColor,
  ) {
    if (message.messageType == 'image' && message.mediaUrl != null) {
      return GestureDetector(
        onTap: () => _showImageViewer(context, message.mediaUrl!),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: message.mediaUrl!,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 180,
              color: AppColors.grey.shade200,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 180,
              color: AppColors.grey.shade200,
              child: const Center(
                  child: Icon(Icons.error_outline, color: AppColors.red)),
            ),
          ),
        ),
      );
    }

    if (message.messageType == 'video' && message.mediaUrl != null) {
      return GestureDetector(
        onTap: () => _showVideoPlayer(context, message.mediaUrl!),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: message.mediaUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 180,
                  color: AppColors.grey.shade200,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 180,
                  color: AppColors.grey.shade200,
                  child: const Center(
                      child: Icon(Icons.error_outline, color: AppColors.red)),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow,
                  color: AppColors.white, size: 40),
            ),
          ],
        ),
      );
    }

    if (message.messageType == 'audio' &&
        message.mediaUrl != null &&
        message.mediaUrl!.isNotEmpty) {
      return AudioMessageBubble(
        audioUrl: message.mediaUrl!,
        isMe: isMe,
        chatColor: chatColor,
      );
    }

    return Text(
      message.message,
      style: TextStyle(
        color: isMe ? AppColors.white : otherTextColor,
        fontSize: 14,
        height: 1.35,
      ),
      softWrap: true,
      textWidthBasis: TextWidthBasis.longestLine,
    );
  }

  Widget _buildTimeAndStatus(bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            fontSize: 9,
            color: isMe ? AppColors.white60 : AppColors.grey.shade500,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          _buildStatusIcon(),
        ],
      ],
    );
  }

  Widget _buildStatusIcon() {
    if (message.isPending) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 12, color: AppColors.white60),
        ],
      );
    }

    // For own messages - show status indicators
    // Check if message has been read
    if (message.isRead) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 12, color: AppColors.white70),
        ],
      );
    }

    // Message sent but not read yet - show delivered (double checkmark)
    // You can add a 'isDelivered' field to MessageModel if needed
    // For now, we'll show sent status
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done, size: 12, color: AppColors.white60),
      ],
    );
  }

  void _showMessageOptions(BuildContext context) {
    final isMe = message.isOwn;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.greyColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (!isMe) ...[
              _buildOptionTile(
                icon: Icons.reply,
                label: 'Reply',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call();
                },
              ),
              _buildOptionTile(
                icon: Icons.copy,
                label: 'Copy',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(context);
                },
              ),
            ],
            if (isMe)
              _buildOptionTile(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: AppColors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context);
                },
              ),
            if (!isMe)
              _buildOptionTile(
                icon: Icons.flag_outlined,
                label: 'Report',
                color: AppColors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(context);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Message deleted'),
                    backgroundColor: AppColors.green),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    String? selectedReason;
    final reasons = [
      'Spam',
      'Harassment',
      'Inappropriate content',
      'Fake information',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Report Message'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Why are you reporting this message?'),
              const SizedBox(height: 16),
              ...reasons.map((reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: AppColors.primary,
                    onChanged: (value) =>
                        setState(() => selectedReason = value),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (selectedReason != null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Message reported'),
                      backgroundColor: AppColors.red),
                );
              }
            },
            child: const Text('Report', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copied to clipboard'),
          backgroundColor: AppColors.green),
    );
  }

  void _showImageViewer(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          imageUrl: url,
          caption: message.messageType == 'image' ? message.message : null,
        ),
      ),
    );
  }

  void _showVideoPlayer(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoViewer(
          videoUrl: url,
          caption: message.messageType == 'video' ? message.message : null,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${diff.inDays ~/ 7}w';
  }
}

class _Avatar extends StatelessWidget {
  final String userAvatar;

  const _Avatar({required this.userAvatar});

  @override
  Widget build(BuildContext context) {
    if (userAvatar.startsWith('http')) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: CachedNetworkImageProvider(userAvatar),
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: const Icon(Icons.person, size: 16, color: AppColors.primary),
    );
  }
}
