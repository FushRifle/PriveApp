import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/models/post_model.dart';
import 'package:Prive/bloc/home/feed_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:Prive/ui/widgets/home/clip_status_bar.dart';
import 'package:Prive/ui/widgets/home/custom_bottom_sheet.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';

class CardPost extends StatefulWidget {
  final dynamic post;
  final bool isDetailView;

  const CardPost({
    required this.post,
    this.isDetailView = false,
    super.key,
  });

  @override
  State<CardPost> createState() => _CardPostState();
}

class _CardPostState extends State<CardPost> {
  double _handleOffset = 0.0;
  bool isLiked = false;
  bool isSaved = false;
  int likeCount = 0;
  int commentCount = 0;
  int postId = 0;
  String? mediaUrl;
  String? mediaType;
  String userName = '';
  String userAvatar = '';
  String content = '';
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  DateTime createdAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _parsePost();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _parsePost() {
    if (widget.post is PostModel) {
      final post = widget.post as PostModel;
      isLiked = post.isLiked;
      likeCount = post.likeCount;
      commentCount = post.commentCount;
      isSaved = post.isSaved;
      userName = post.name;
      userAvatar = post.imgProfile;
      content = post.displayText;
      postId = post.id;
      mediaUrl = post.picture;
      mediaType = post.picture.isNotEmpty ? 'image' : null;
      createdAt = post.createdAt;
      return;
    }

    // Parse from Map
    isLiked = widget.post['isLiked'] ?? false;
    likeCount = widget.post['likes'] ?? 0;
    commentCount = widget.post['commentCount'] ?? widget.post['comments'] ?? 0;
    isSaved = widget.post['isSaved'] ?? false;
    userName =
        widget.post['user']?['name'] ?? widget.post['username'] ?? 'User';
    userAvatar = widget.post['user']?['avatar'] ?? '';
    content = widget.post['caption'] ?? widget.post['content'] ?? '';

    final createdAtStr = widget.post['createdAt'] ??
        widget.post['created_at'] ??
        widget.post['time'];
    if (createdAtStr != null) {
      try {
        createdAt = DateTime.parse(createdAtStr.toString());
      } catch (e) {
        createdAt = DateTime.now();
      }
    }

    final id = widget.post['id'] ?? widget.post['_id'];
    if (id is int) {
      postId = id;
    } else if (id is String) {
      postId = int.tryParse(id) ?? 0;
    } else {
      postId = 0;
    }

    final attachments = widget.post['attachments'];
    if (attachments != null && attachments.isNotEmpty) {
      final firstAttachment = attachments[0];
      mediaUrl = firstAttachment['url'];
      mediaType = firstAttachment['type'];

      if (mediaType == 'video' && mediaUrl != null) {
        _initializeVideoController();
      }
    } else {
      mediaType = null;
      mediaUrl = null;
    }
  }

  void _initializeVideoController() {
    _videoController = VideoPlayerController.network(mediaUrl!)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
        }
      }).catchError((error) {
        debugPrint('Error initializing video: $error');
        if (mounted) {
          setState(() {
            mediaType = null;
          });
        }
      });
  }

  void _toggleLike() {
    if (isLiked) {
      context.read<FeedBloc>().add(UnlikePost(postId));
    } else {
      context.read<FeedBloc>().add(LikePost(postId));
    }

    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likeCount++;
      } else {
        likeCount--;
      }
    });
  }

  void _toggleSave() async {
    setState(() {
      isSaved = !isSaved;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(isSaved ? 'Saved to collection' : 'Removed from collection'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openComments() {
    customBottomSheetComments(context, postId: postId);
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: mediaType == null
                ? _buildTextOnlyPost()
                : SizedBox(
                    width: width,
                    height: width * 1.2,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaContent(),
                        _buildGradientOverlay(),
                        _buildSidePanel(width, width * 1.2, -80, 80),
                        _buildBottomInfo(),
                      ],
                    ),
                  ),
          ),
        );
      },
    );

    if (widget.isDetailView) {
      return cardContent;
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          NamedRoutes.postDetailScreen,
          arguments: widget.post,
        );
      },
      child: cardContent,
    );
  }

  Widget _buildTextOnlyPost() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: AppColors.greyTextColor.withOpacity(0.15),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (userAvatar.isNotEmpty)
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(userAvatar),
                    onBackgroundImageError: (_, __) {},
                  ),
                if (userAvatar.isNotEmpty) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: AppTheme.blackTextStyle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimeAgo(createdAt),
                        style: AppTheme.greyTextStyle.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildTextOnlyActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    count: likeCount,
                    onTap: _toggleLike,
                    isActive: isLiked,
                    activeColor: Colors.redAccent,
                  ),
                ),
                Expanded(
                  child: _buildTextOnlyActionButton(
                    icon: Icons.chat_bubble_outline,
                    count: commentCount,
                    onTap: _openComments,
                  ),
                ),
                Expanded(
                  child: _buildTextOnlyActionButton(
                    icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                    count: 0,
                    onTap: _toggleSave,
                    isActive: isSaved,
                    activeColor: AppColors.secondary,
                  ),
                ),
                Expanded(
                  child: _buildTextOnlyActionButton(
                    icon: Icons.share_outlined,
                    count: 0,
                    onTap: _onShare,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextOnlyActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? (activeColor ?? Colors.redAccent).withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 22,
              color: isActive ? activeColor : AppColors.greyColor,
            ),
          ),
          const SizedBox(height: 2),
          if (count > 0)
            Text(
              count > 999
                  ? '${(count / 1000).toStringAsFixed(1)}K'
                  : count.toString(),
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
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
    } else {
      return 'Just now';
    }
  }

  Widget _buildMediaContent() {
    if (mediaType == 'video' &&
        _isVideoInitialized &&
        _videoController != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoController!),
          Positioned.fill(
            child: InkWell(
              onTap: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          if (!_videoController!.value.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
        ],
      );
    } else if (mediaType == 'image' && mediaUrl != null) {
      return Image.network(
        mediaUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.greyColor.withOpacity(0.2),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image,
                      size: 40, color: AppColors.greyColor),
                  const SizedBox(height: 6),
                  Text('Failed to load image', style: AppTheme.greyTextStyle),
                ],
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.greyColor.withOpacity(0.1),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        },
      );
    }

    return Container(
      color: AppColors.greyColor.withOpacity(0.2),
      child: Center(
        child: Text(
          content.isNotEmpty ? content : 'No media content',
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.3, 0.7, 1.0],
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel(
      double width, double height, double minScroll, double maxScroll) {
    return Positioned(
      right: 0,
      top: 8,
      bottom: 20,
      width: 85,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 3.14,
            child: ClipPath(
              clipper: ClipStatusBar(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                ),
              ),
            ),
          ),
          _buildActionButtons(),
          _buildDraggableHandle(height, minScroll, maxScroll),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          label: 'Like',
          onTap: _toggleLike,
          isActive: isLiked,
          activeColor: Colors.redAccent,
          showCount: true,
          count: likeCount,
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          label: 'Reply',
          onTap: _openComments,
          showCount: true,
          count: commentCount,
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
          label: 'Save',
          onTap: _toggleSave,
          isActive: isSaved,
          activeColor: Colors.amber,
        ),
        const SizedBox(height: 20),
        _buildActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: _onShare,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
    bool showCount = false,
    int count = 0,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? activeColor?.withOpacity(0.8)
                  : Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.95),
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            showCount && count > 0 ? _formatCount(count) : label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: showCount && count > 0 ? 12 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Widget _buildDraggableHandle(
      double height, double minScroll, double maxScroll) {
    return Positioned(
      left: 0,
      top: (height / 2 - 35) + _handleOffset,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _handleOffset += details.delta.dy;
            _handleOffset = _handleOffset.clamp(minScroll, maxScroll);
          });
        },
        onVerticalDragEnd: (_) {
          setState(() => _handleOffset = 0);
        },
        child: Container(
          width: 3,
          height: 35,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Positioned(
      left: 14,
      right: 85,
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (userAvatar.isNotEmpty)
                CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(userAvatar),
                  onBackgroundImageError: (_, __) {},
                ),
              if (userAvatar.isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (content.isNotEmpty && mediaType != null)
                      Text(
                        content,
                        style: TextStyle(
                          color: AppColors.whiteColor.withOpacity(0.9),
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
