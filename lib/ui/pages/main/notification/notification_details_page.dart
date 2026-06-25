import 'package:clique/core/models/feeds_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:clique/ui/pages/main/home/post_detail_page.dart';

class NotificationDetailsPage extends StatefulWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailsPage({
    super.key,
    required this.notification,
  });

  @override
  State<NotificationDetailsPage> createState() =>
      _NotificationDetailsPageState();
}

class _NotificationDetailsPageState extends State<NotificationDetailsPage> {
  final FeedService _feedService = FeedService();

  late final int _postId;
  FeedPost? _post;

  @override
  void initState() {
    super.initState();
    _postId = _resolvePostId();
    _loadPost();
  }

  int _resolvePostId() {
    final notification = widget.notification;
    final data = _asMap(notification['data']);
    return _readInt(
      notification['postId'] ??
          notification['post_id'] ??
          notification['targetId'] ??
          notification['target_id'] ??
          data['postId'] ??
          data['post_id'] ??
          data['targetPostId'] ??
          data['target_post_id'],
    );
  }

  Future<void> _loadPost() async {
    if (_postId <= 0) {
      return;
    }

    try {
      final post = await _feedService.getPostById(_postId);
      if (!mounted) return;
      setState(() => _post = post);
    } catch (_) {
      return;
    }
  }

  void _openPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(
          postId: _post?.id ?? _postId,
          initialPost: _post,
        ),
      ),
    );
  }

  void _openChat(Map<String, dynamic> notification, Map<String, dynamic> data) {
    final conversationId = _readInt(
      data['conversationId'] ??
          data['conversation_id'] ??
          notification['conversationId'] ??
          notification['conversation_id'],
    );
    if (conversationId <= 0) {
      Navigator.pushNamed(context, NamedRoutes.inboxScreen);
      return;
    }

    Navigator.pushNamed(
      context,
      NamedRoutes.chatScreen,
      arguments: {
        'conversationId': conversationId,
        'userName': _actorName(notification),
        'userAvatar': notification['actorAvatar'] ?? data['actorAvatar'] ?? '',
        'userId': _readInt(
          notification['actorId'] ??
              data['actorId'] ??
              data['senderId'] ??
              data['sender_id'],
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final data = _asMap(notification['data']);
    final actorName = _actorName(notification);
    final type = notification['type']?.toString() ?? 'general';
    final content = (notification['message'] ?? notification['content'] ?? '')
        .toString()
        .trim();
    final postImage = _resolvePostImage(notification, data);
    final time = _formatTime(notification['createdAt']?.toString());
    final accent = _notificationColor(type);
    final summary = _summaryForType(type, notification);
    final isComment = type == 'comment' || type == 'post_comment';
    final isMessage = type == 'message' || type == 'chat';

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Activity'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          _ActivityHeaderCard(
            actorName: actorName,
            type: type,
            time: time,
            accent: accent,
            summary: summary,
            content: content,
            postImage: postImage,
          ),
          const SizedBox(height: 12),
          if (isMessage)
            _buildMessageDetails(notification, data, accent)
          else if (isComment)
            _buildCommentDetails(notification, data, accent)
          else
            _buildGenericDetails(summary, content, accent),
        ],
      ),
    );
  }

  Widget _buildGenericDetails(String summary, String content, Color accent) {
    return _DetailPanel(
      icon: Icons.notifications_none_rounded,
      title: summary,
      body:
          content.isEmpty ? 'Open the related page for more context.' : content,
      accent: accent,
      actionLabel: _postId > 0 ? 'View page' : null,
      onAction: _postId > 0 ? _openPost : null,
    );
  }

  Widget _buildMessageDetails(
    Map<String, dynamic> notification,
    Map<String, dynamic> data,
    Color accent,
  ) {
    final message =
        (notification['message'] ?? data['message'] ?? '').toString().trim();

    return _DetailPanel(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Message',
      body: message.isEmpty ? 'Open the conversation to reply.' : message,
      accent: accent,
      actionLabel: 'Open chat',
      onAction: () => _openChat(notification, data),
    );
  }

  Widget _buildCommentDetails(
    Map<String, dynamic> notification,
    Map<String, dynamic> data,
    Color accent,
  ) {
    final comment = (data['comment'] ??
            data['commentText'] ??
            data['comment_text'] ??
            data['snippet'] ??
            notification['content'] ??
            notification['message'] ??
            '')
        .toString()
        .trim();

    return _DetailPanel(
      icon: Icons.mode_comment_outlined,
      title: 'Comment',
      body: comment.isEmpty ? 'Comment activity' : comment,
      accent: accent,
      actionLabel: 'View page',
      onAction: _postId > 0 ? _openPost : null,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _resolvePostImage(
    Map<String, dynamic> notification,
    Map<String, dynamic> data,
  ) {
    final directImage = (notification['postImage'] ??
            notification['post_image'] ??
            data['postImage'] ??
            data['post_image'] ??
            data['imageUrl'] ??
            data['image_url'] ??
            '')
        .toString()
        .trim();
    if (directImage.isNotEmpty) return directImage;

    final attachments = data['attachments'];
    if (attachments is List && attachments.isNotEmpty) {
      for (final item in attachments) {
        final attachment = item is Map
            ? Attachment.fromJson(Map<String, dynamic>.from(item))
            : null;
        final url = attachment == null
            ? ''
            : (attachment.thumbnail?.trim().isNotEmpty == true
                ? attachment.thumbnail!.trim()
                : attachment.url.trim());
        if (url.isNotEmpty) return url;
      }
    }

    return '';
  }

  String _actorName(Map<String, dynamic> item) {
    final data = _asMap(item['data']);
    final value = item['actorName'] ??
        data['actorName'] ??
        data['actorUsername'] ??
        data['username'];
    final name = value?.toString().trim() ?? '';
    return name.isEmpty ? 'User' : name;
  }

  Color _notificationColor(String type) {
    switch (type) {
      case 'message':
      case 'chat':
        return AppColors.primary;
      case 'like':
      case 'post_like':
        return AppColors.primary;
      case 'comment':
      case 'post_comment':
      case 'mention':
        return AppColors.info;
      case 'follow':
      case 'friend_request':
      case 'friend_accepted':
        return AppColors.success;
      case 'match':
        return AppColors.purple;
      default:
        return AppColors.greyColor;
    }
  }

  String _summaryForType(String type, Map<String, dynamic> item) {
    final data = item['data'] is Map
        ? Map<String, dynamic>.from(item['data'] as Map)
        : <String, dynamic>{};
    final content =
        (item['message'] ?? item['content'] ?? '').toString().trim();

    switch (type) {
      case 'like':
      case 'post_like':
        return 'Liked your post';
      case 'comment':
      case 'post_comment':
        return data['snippet']?.toString().isNotEmpty == true
            ? '"${data['snippet']}"'
            : 'Commented on your post';
      case 'follow':
        return 'Started following you';
      case 'friend_request':
        return 'Sent you a friend request';
      case 'friend_accepted':
        return 'Accepted your friend request';
      case 'mention':
        return 'Mentioned you in a post';
      case 'match':
        return 'Matched with you';
      default:
        return content.isNotEmpty ? content : 'Notification activity';
    }
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'Just now';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      if (difference.inDays > 7) {
        return '${difference.inDays ~/ 7}w ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      }
      return 'Just now';
    } catch (_) {
      return 'Just now';
    }
  }
}

class _ActivityHeaderCard extends StatelessWidget {
  final String actorName;
  final String type;
  final String time;
  final Color accent;
  final String summary;
  final String content;
  final String postImage;

  const _ActivityHeaderCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.65)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActivityAvatar(
            imageUrl: postImage,
            fallback: actorName,
            accent: accent,
            type: type,
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
                        actorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.text,
                                ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (content.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityAvatar extends StatelessWidget {
  final String imageUrl;
  final String fallback;
  final Color accent;
  final String type;

  const _ActivityAvatar({
    required this.imageUrl,
    required this.fallback,
    required this.accent,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      'message' || 'chat' => Icons.chat_bubble_outline_rounded,
      'comment' || 'post_comment' => Icons.mode_comment_outlined,
      'like' || 'post_like' => Icons.favorite_border_rounded,
      'follow' ||
      'friend_request' ||
      'friend_accepted' =>
        Icons.person_add_alt_rounded,
      _ => Icons.notifications_none_rounded,
    };

    return Tooltip(
      message: fallback,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(17),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl.trim().isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(icon, color: accent),
              )
            : Center(
                child: Icon(icon, color: accent),
              ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _DetailPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAction,
                icon: Text(actionLabel!),
                label: const Icon(Icons.chevron_right_rounded),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
