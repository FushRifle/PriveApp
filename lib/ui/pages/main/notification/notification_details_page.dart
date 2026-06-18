import 'package:clique/core/models/feeds_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:clique/ui/pages/main/home/post_detail_page.dart';
import 'package:clique/ui/widgets/notification/details/notification_hero.dart';
import 'package:clique/ui/widgets/notification/details/details_card.dart';
import 'package:clique/ui/widgets/notification/details/post_section.dart';

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
  bool _isLoadingPost = true;

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
      if (!mounted) return;
      setState(() => _isLoadingPost = false);
      return;
    }

    try {
      final post = await _feedService.getPostById(_postId);
      if (!mounted) return;
      setState(() {
        _post = post;
        _isLoadingPost = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPost = false);
    }
  }

  void _openPost() {
    final post = _post;
    if (post == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(
          postId: post.id,
          initialPost: post,
        ),
      ),
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

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: AppColors.backgroundColor,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: NotificationHero(
                actorName: actorName,
                type: type,
                time: time,
                accent: accent,
                summary: summary,
                content: content,
                postImage: postImage,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                DetailsCard(
                  notification: notification,
                  actorName: actorName,
                  type: type,
                  time: time,
                  accent: accent,
                ),
                const SizedBox(height: 20),
                
                PostSection(
                  isLoading: _isLoadingPost,
                  post: _post,
                  postId: _postId,
                  postImage: postImage,
                  onOpenPost: _openPost,
                ),
              ]),
            ),
          ),
        ],
      ),
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