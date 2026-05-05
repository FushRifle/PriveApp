import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/app/resources/constant/named_routes.dart';
import 'package:social_media_app/data/services/home/feed_service.dart';

import 'clip_status_bar.dart';

class CardPost extends StatefulWidget {
  final dynamic post;

  const CardPost({
    required this.post,
    super.key,
  });

  @override
  State<CardPost> createState() => _CardPostState();
}

class _CardPostState extends State<CardPost> {
  final FeedService _feedService = FeedService();

  bool isLiked = false;
  bool isSaved = false;
  int likeCount = 0;

  Map<String, dynamic> get _post {
    if (widget.post is Map<String, dynamic>) {
      return widget.post as Map<String, dynamic>;
    }

    if (widget.post is Map) {
      return Map<String, dynamic>.from(widget.post as Map);
    }

    return {};
  }

  @override
  void initState() {
    super.initState();
    _parsePost();
  }

  @override
  void didUpdateWidget(covariant CardPost oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.post != widget.post) {
      _parsePost();
    }
  }

  void _parsePost() {
    final post = _post;

    isLiked = post['isLiked'] == true || post['is_liked'] == true;
    likeCount =
        _toInt(post['likes'] ?? post['likesCount'] ?? post['likes_count']);
  }

  int get _postId {
    return _toInt(_post['id']);
  }

  String get _imageUrl {
    final attachments = _post['attachments'];

    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;

      if (first is Map) {
        return (first['url'] ?? first['uri'] ?? first['imageUrl'] ?? '')
            .toString();
      }

      if (first is String) {
        return first;
      }
    }

    return (_post['image'] ??
            _post['imageUrl'] ??
            _post['image_url'] ??
            _post['mediaUrl'] ??
            '')
        .toString();
  }

  String get _caption {
    return (_post['content'] ?? _post['caption'] ?? '').toString();
  }

  Map<String, dynamic> get _user {
    final user = _post['user'];

    if (user is Map<String, dynamic>) return user;
    if (user is Map) return Map<String, dynamic>.from(user);

    return {};
  }

  String get _userName {
    return (_user['name'] ??
            _user['username'] ??
            _post['name'] ??
            _post['username'] ??
            'User')
        .toString();
  }

  String get _userAvatar {
    return (_user['avatar'] ??
            _user['avatarUrl'] ??
            _user['avatar_url'] ??
            _post['imgProfile'] ??
            _post['avatar'] ??
            '')
        .toString();
  }

  Future<void> toggleLike() async {
    if (_postId == 0) return;

    final oldLiked = isLiked;
    final oldCount = likeCount;

    setState(() {
      isLiked = !isLiked;
      likeCount = isLiked ? likeCount + 1 : (likeCount - 1).clamp(0, 999999);
    });

    HapticFeedback.lightImpact();

    try {
      if (isLiked) {
        await _feedService.likePost(_postId);
      } else {
        await _feedService.unlikePost(_postId);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLiked = oldLiked;
        likeCount = oldCount;
      });
    }
  }

  void toggleSave() {
    setState(() {
      isSaved = !isSaved;
    });

    HapticFeedback.lightImpact();
  }

  void onCommentTap(BuildContext context) {
    HapticFeedback.lightImpact();

    Navigator.pushNamed(
      context,
      NamedRoutes.postDetailScreen,
      arguments: widget.post,
    );
  }

  void onShareTap() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardHeight = width * 1.22;
        final safeHeight = cardHeight.clamp(390.0, 500.0);

        return SizedBox(
          width: double.infinity,
          height: safeHeight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageCover(),
                  _buildImageGradient(),
                  Positioned(
                    right: 0,
                    top: 28,
                    bottom: 68,
                    width: 68,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: 3.14,
                        child: ClipPath(
                          clipper: ClipStatusBar(),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: ColoredBox(
                              color: AppColors.whiteColor.withOpacity(0.22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 44,
                    bottom: 88,
                    width: 52,
                    child: _buildActions(context),
                  ),
                  Positioned(
                    width: 4,
                    height: 24,
                    right: 58,
                    top: safeHeight / 2 - 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 82,
                    bottom: 20,
                    child: _buildItemPublisher(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusButton(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              text: _formatCount(likeCount),
              onTap: toggleLike,
              isActive: isLiked,
              activeColor: AppColors.redColor,
            ),
            const SizedBox(height: 8),
            _buildStatusButton(
              icon: Icons.mode_comment_outlined,
              text: 'Reply',
              onTap: () => onCommentTap(context),
            ),
            const SizedBox(height: 8),
            _buildStatusButton(
              icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
              text: 'Save',
              onTap: toggleSave,
              isActive: isSaved,
              activeColor: AppColors.greenColor,
            ),
            const SizedBox(height: 8),
            _buildStatusButton(
              icon: Icons.send_outlined,
              text: 'Send',
              onTap: onShareTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: isActive && activeColor != null
                    ? activeColor
                    : AppColors.whiteColor.withOpacity(0.38),
                borderRadius: BorderRadius.circular(22),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color:
                              (activeColor ?? Colors.white).withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                size: 15,
                color: AppColors.whiteColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.whiteTextStyle.copyWith(
                fontSize: 8.5,
                fontWeight: AppTheme.bold,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGradient() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.22),
              Colors.black.withOpacity(0.72),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCover() {
    final imageUrl = _imageUrl;

    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
      loadingBuilder: (_, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return Stack(
          fit: StackFit.expand,
          children: [
            _buildPlaceholder(),
            Center(
              child: SizedBox(
                height: 38,
                width: 38,
                child: CircularProgressIndicator(
                  color: Colors.white.withOpacity(0.85),
                  strokeWidth: 1.4,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.purpleColor.withOpacity(0.18),
      child: Center(
        child: Icon(
          Icons.image,
          size: 52,
          color: AppColors.purpleColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildItemPublisher(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(NamedRoutes.profileScreen);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  _userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.whiteTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: AppTheme.bold,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_caption.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text(
            _caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 11,
              height: 1.2,
              fontWeight: AppTheme.medium,
            ),
          ),
        ],
        const SizedBox(height: 3),
        Text(
          '#trending #prive',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.whiteTextStyle.copyWith(
            color: AppColors.greenColor,
            fontSize: 10,
            fontWeight: AppTheme.medium,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final avatar = _userAvatar;

    if (avatar.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.network(
          avatar,
          width: 30,
          height: 30,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(),
        ),
      );
    }

    if (avatar.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.asset(
          avatar,
          width: 30,
          height: 30,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(),
        ),
      );
    }

    return _avatarFallback();
  }

  Widget _avatarFallback() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.whiteColor.withOpacity(0.35),
      ),
      child: const Icon(
        Icons.person,
        size: 17,
        color: Colors.white,
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toString();
  }
}
