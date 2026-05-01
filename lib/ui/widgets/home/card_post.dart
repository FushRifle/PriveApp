import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/app/resources/constant/named_routes.dart';
import 'package:social_media_app/data/hooks/home/feed_hook.dart';
import 'clip_status_bar.dart';

class CardPost extends StatefulWidget {
  final dynamic post;

  const CardPost({required this.post, super.key});

  @override
  State<CardPost> createState() => _CardPostState();
}

class _CardPostState extends State<CardPost> {
  final FeedHook _feedHook = FeedHook();
  bool isLiked = false;
  bool isSaved = false;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    _parsePost();
  }

  void _parsePost() {
    final post =
        widget.post is Map ? widget.post as Map<String, dynamic> : null;
    isLiked = post?['isLiked'] ?? false;
    likeCount = post?['likes'] ?? 0;
  }

  String get _imageUrl {
    final post =
        widget.post is Map ? widget.post as Map<String, dynamic> : null;
    if (post == null) return '';

    // Check attachments first
    final attachments = post['attachments'];
    if (attachments is List && attachments.isNotEmpty) {
      final firstAttachment = attachments[0] as Map<String, dynamic>?;
      return firstAttachment?['url']?.toString() ??
          firstAttachment?['uri']?.toString() ??
          '';
    }

    // Fallback to image field
    return post['image']?.toString() ?? '';
  }

  String get _caption {
    final post =
        widget.post is Map ? widget.post as Map<String, dynamic> : null;
    if (post == null) return '';
    return (post['content'] ?? post['caption'] ?? '').toString();
  }

  String get _userName {
    final post =
        widget.post is Map ? widget.post as Map<String, dynamic> : null;
    if (post == null) return 'User';

    final user = post['user'];
    if (user is Map<String, dynamic>) {
      return (user['name'] ?? 'User').toString();
    }
    return (post['name'] ?? 'User').toString();
  }

  String get _userAvatar {
    final post =
        widget.post is Map ? widget.post as Map<String, dynamic> : null;
    if (post == null) return 'assets/profiles/profile_1.jpeg';

    final user = post['user'];
    if (user is Map<String, dynamic>) {
      return (user['avatar'] ?? 'assets/profiles/profile_1.jpeg').toString();
    }
    return (post['imgProfile'] ?? 'assets/profiles/profile_1.jpeg').toString();
  }

  int get _postId {
    final post =
        widget.post is Map ? widget.post as Map<String, dynamic> : null;
    if (post == null) return 0;
    return post['id'] ?? 0;
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likeCount++;
        _feedHook.likePost(_postId);
      } else {
        likeCount--;
        _feedHook.unlikePost(_postId);
      }
      HapticFeedback.lightImpact();
    });
  }

  void toggleSave() {
    setState(() {
      isSaved = !isSaved;
      HapticFeedback.lightImpact();
    });
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
    return Container(
      width: double.infinity,
      height: 460,
      margin: const EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          _buildImageCover(),
          _buildImageGradient(),
          Positioned(
            height: 375,
            width: 85,
            right: 0,
            top: 25,
            child: Transform.rotate(
              angle: 3.14,
              child: ClipPath(
                clipper: ClipStatusBar(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: ColoredBox(
                    color: AppColors.whiteColor.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 75,
            right: 20,
            child: Column(
              children: [
                _buildStatusButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  text: likeCount.toString(),
                  onTap: toggleLike,
                  isActive: isLiked,
                  activeColor: AppColors.redColor,
                ),
                const SizedBox(height: 10),
                _buildStatusButton(
                  icon: Icons.message,
                  text: 'Comment',
                  onTap: () => onCommentTap(context),
                ),
                const SizedBox(height: 10),
                _buildStatusButton(
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                  text: "Save",
                  onTap: toggleSave,
                  isActive: isSaved,
                  activeColor: AppColors.greenColor,
                ),
                const SizedBox(height: 10),
                _buildStatusButton(
                  icon: Icons.send,
                  text: 'Share',
                  onTap: onShareTap,
                ),
              ],
            ),
          ),
          Positioned(
            width: 5,
            height: 30,
            right: 72,
            top: 200,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          _buildItemPublisher(context),
        ],
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
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: isActive && activeColor != null
                  ? activeColor
                  : AppColors.whiteColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: (activeColor ?? Colors.white).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: Icon(icon,
                size: 20,
                color: isActive ? Colors.white : AppColors.whiteColor),
          ),
          const SizedBox(height: 4),
          Text(text,
              style: AppTheme.whiteTextStyle
                  .copyWith(fontSize: 13, fontWeight: AppTheme.bold)),
        ],
      ),
    );
  }

  Align _buildImageGradient() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.6)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCover() {
    final imageUrl = _imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
              loadingBuilder: (_, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    height: 55,
                    width: 55,
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.8),
                      strokeWidth: 1.2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.purpleColor.withOpacity(0.2),
      child: Center(
        child: Icon(Icons.image,
            size: 60, color: AppColors.purpleColor.withOpacity(0.5)),
      ),
    );
  }

  Container _buildItemPublisher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 18, right: 40, bottom: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () =>
                Navigator.of(context).pushNamed(NamedRoutes.profileScreen),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(_userAvatar,
                      width: 32, height: 32, fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                Text(_userName,
                    style: AppTheme.whiteTextStyle
                        .copyWith(fontSize: 16, fontWeight: AppTheme.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(_caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.whiteTextStyle
                  .copyWith(fontSize: 12, fontWeight: AppTheme.bold)),
          const SizedBox(height: 2),
          Text('#trending #prive',
              style: AppTheme.whiteTextStyle.copyWith(
                  color: AppColors.greenColor,
                  fontSize: 12,
                  fontWeight: AppTheme.medium)),
        ],
      ),
    );
  }
}
