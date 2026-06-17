import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:clique/ui/pages/main/home/post_detail_page.dart';
import 'package:clique/ui/widgets/common/effect_text.dart';
import 'package:clique/ui/widgets/post/normal-post/repost_card.dart';

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

  FeedPost? _post;
  bool _isLoadingPost = true;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    final postId = _readInt(
      widget.notification['postId'] ??
          widget.notification['post_id'] ??
          widget.notification['targetId'] ??
          widget.notification['target_id'] ??
          _asMap(widget.notification['data'])['postId'] ??
          _asMap(widget.notification['data'])['post_id'] ??
          _asMap(widget.notification['data'])['targetPostId'] ??
          _asMap(widget.notification['data'])['target_post_id'],
    );

    if (postId <= 0) {
      if (!mounted) return;
      setState(() => _isLoadingPost = false);
      return;
    }

    try {
      final post = await _feedService.getPostById(postId);
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
    final postImage = (notification['postImage'] ??
            data['postImage'] ??
            data['imageUrl'] ??
            '')
        .toString();
    final time = _formatTime(notification['createdAt']?.toString());
    final accent = _notificationColor(type);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: AppColors.backgroundColor,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _NotificationHero(
                actorName: actorName,
                type: type,
                time: time,
                accent: accent,
                notification: notification,
              ),
              
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Related post',
                    child: _isLoadingPost
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : _post != null
                            ? Column(
                                children: [
                                  RepostCard(
                                    post: _post!,
                                    isDetailView: false,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _openPost,
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('Open post'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Could not load the related post on this device. You can still review the activity above.',
                                style: AppTheme.greyTextStyle.copyWith(
                                  height: 1.45,
                                ),
                              ),
                  ),
                  if (postImage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Preview image',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: postImage,
                              height: 240,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                height: 240,
                                color: AppColors.greyColor.withOpacity(0.08),
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                height: 240,
                                color: AppColors.greyColor.withOpacity(0.08),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: _TypeChip(
                                label: type.replaceAll('_', ' '),
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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

class _NotificationHero extends StatelessWidget {
  final String actorName;
  final String type;
  final String time;
  final Color accent;
  final Map<String, dynamic> notification;

  const _NotificationHero({
    required this.actorName,
    required this.type,
    required this.time,
    required this.accent,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.22),
            AppColors.primary.withOpacity(0.12),
            AppColors.backgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.card.withOpacity(0.94),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.16),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _iconForType(type),
                      size: 32,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TypeChip(
                          label: type.replaceAll('_', ' '),
                          color: accent,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          actorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.blackTextStyle.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _summaryForType(type, notification),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.greyTextStyle.copyWith(
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    time,
                    style: AppTheme.greyTextStyle.copyWith(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'like':
      case 'post_like':
        return Icons.favorite_rounded;
      case 'comment':
      case 'post_comment':
      case 'mention':
        return Icons.chat_bubble_rounded;
      case 'follow':
      case 'friend_request':
      case 'friend_accepted':
        return Icons.person_add_alt_1_rounded;
      case 'match':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.notifications_rounded;
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
            ? 'Commented: "${data['snippet']}"'
            : 'Commented on your post';
      case 'follow':
        return 'Started following you';
      case 'match':
        return 'Matched with you';
      default:
        return content.isNotEmpty ? content : 'Notification activity';
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.greyTextStyle.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
