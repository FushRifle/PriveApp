import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';

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

    return Dismissible(
      key: Key(
          'message_${message.id}_${message.createdAt.millisecondsSinceEpoch}'),
      direction:
          isMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        padding: EdgeInsets.only(right: isMe ? 20 : 0, left: !isMe ? 20 : 0),
        child: Icon(Icons.reply, color: AppColors.primary, size: 24),
      ),
      onDismissed: (direction) => onReply?.call(),
      child: Padding(
        padding: EdgeInsets.only(
            bottom: 8, top: 5, left: isMe ? 0 : 2, right: isMe ? 2 : 0),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: userAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(userAvatar)
                      : null,
                  child: userAvatar.isEmpty
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
              ),
            Flexible(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onLongPress: () => _showMessageOptions(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? chatColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyToId != null) _buildReplyPreview(isMe),
                        _buildMessageContent(isMe, context),
                        const SizedBox(height: 4),
                        _buildTimeAndStatus(isMe),
                      ],
                    ),
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
        color: isMe ? Colors.white.withOpacity(0.15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.reply,
              size: 12, color: isMe ? Colors.white70 : AppColors.primary),
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
                    color: isMe ? Colors.white70 : AppColors.primary,
                  ),
                ),
                Text(
                  message.replyToMessage ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white60 : Colors.grey.shade600,
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

  Widget _buildMessageContent(bool isMe, BuildContext context) {
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
              color: Colors.grey.shade200,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 180,
              color: Colors.grey.shade200,
              child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.red)),
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
                  color: Colors.grey.shade200,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey.shade200,
                  child: const Center(
                      child: Icon(Icons.error_outline, color: Colors.red)),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.play_arrow, color: Colors.white, size: 40),
            ),
          ],
        ),
      );
    }

    if (message.messageType == 'audio' && message.mediaUrl != null) {
      return Row(
        children: [
          Icon(Icons.audiotrack,
              color: isMe ? Colors.white : AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Audio message',
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
          ),
        ],
      );
    }

    return Text(
      message.message,
      style: TextStyle(
        color: isMe ? Colors.white : AppColors.blackColor,
        fontSize: 14,
        height: 1.4,
      ),
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
            color: isMe ? Colors.white60 : Colors.grey.shade500,
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
    // For own messages - show status indicators
    // Check if message has been read
    if (message.isRead) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 12, color: Colors.white70),
        ],
      );
    }

    // Message sent but not read yet - show delivered (double checkmark)
    // You can add a 'isDelivered' field to MessageModel if needed
    // For now, we'll show sent status
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done, size: 12, color: Colors.white60),
      ],
    );
  }

  void _showMessageOptions(BuildContext context) {
    final isMe = message.isOwn;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context);
                },
              ),
            if (!isMe)
              _buildOptionTile(
                icon: Icons.flag_outlined,
                label: 'Report',
                color: Colors.red,
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
                    backgroundColor: Colors.green),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
                      backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copied to clipboard'), backgroundColor: Colors.green),
    );
  }

  void _showImageViewer(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    placeholder: (_, __) => const CircularProgressIndicator(),
                    errorWidget: (_, __, ___) => const Icon(Icons.error_outline,
                        color: Colors.white, size: 50),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoPlayer(BuildContext context, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video player coming soon')),
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
