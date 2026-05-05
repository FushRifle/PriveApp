import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/models/post_model.dart';
import 'package:video_player/video_player.dart';
import 'package:Prive/ui/widgets/home/clip_status_bar.dart';
import 'package:Prive/ui/widgets/home/custom_bottom_sheet.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';

class CardPost extends StatefulWidget {
  final dynamic post;
  final bool isDetailView; // Add this flag

  const CardPost({
    required this.post,
    this.isDetailView = false, // Default false for feed
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
  int postId = 0;
  String? mediaUrl;
  String? mediaType;
  String userName = '';
  String userAvatar = '';
  String content = '';
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

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
      likeCount = post.like;
      isSaved = false;
      userName = post.name;
      userAvatar = post.imgProfile;
      content = post.caption;
      postId = post.id;
      mediaUrl = post.picture;
      mediaType = post.picture.isNotEmpty ? 'image' : null;
      return;
    }

    isLiked = widget.post['isLiked'] ?? false;
    likeCount = widget.post['likes'] ?? 0;
    isSaved = widget.post['isSaved'] ?? false;
    userName =
        widget.post['user']?['name'] ?? widget.post['username'] ?? 'User';
    userAvatar = widget.post['user']?['avatar'] ?? '';
    content = widget.post['caption'] ?? widget.post['content'] ?? '';

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
        setState(() {
          _isVideoInitialized = true;
        });
      }).catchError((error) {
        print('Error initializing video: $error');
        setState(() {
          mediaType = null;
        });
      });
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  }

  void _toggleSave() {
    setState(() {
      isSaved = !isSaved;
    });
  }

  void _openComments() {
    customBottomSheetComments(context, postId: postId);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double safeHeight;

        if (mediaType == null) {
          safeHeight = 180.0;
        } else {
          safeHeight = (width * 0.9).clamp(320.0, 450.0);
        }

        const double minScroll = -80.0;
        const double maxScroll = 80.0;

        final cardContent = Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: safeHeight,
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
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMediaContent(),
                      _buildGradientOverlay(),
                      _buildSidePanel(safeHeight, minScroll, maxScroll),
                      _buildBottomInfo(),
                    ],
                  ),
          ),
        );

        // Don't wrap with GestureDetector if in detail view
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
      },
    );
  }

  Widget _buildTextOnlyPost() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleColor.withOpacity(0.08),
            AppColors.purpleColor.withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: AppColors.purpleColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                if (userAvatar.isNotEmpty)
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(userAvatar),
                    onBackgroundImageError: (_, __) {},
                  ),
                if (userAvatar.isNotEmpty) const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    userName,
                    style: AppTheme.blackTextStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildTextOnlyActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  count: likeCount,
                  onTap: _toggleLike,
                  isActive: isLiked,
                  activeColor: Colors.redAccent,
                ),
                const SizedBox(width: 16),
                _buildTextOnlyActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: 0,
                  onTap: _openComments,
                ),
                const SizedBox(width: 16),
                _buildTextOnlyActionButton(
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                  count: 0,
                  onTap: _toggleSave,
                  isActive: isSaved,
                  activeColor: Colors.amber,
                ),
                const Spacer(),
                _buildTextOnlyActionButton(
                  icon: Icons.share_outlined,
                  count: 0,
                  onTap: () {},
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? activeColor : AppColors.greyColor,
          ),
          if (count > 0) ...[
            const SizedBox(width: 3),
            Text(
              count > 999
                  ? '${(count / 1000).toStringAsFixed(1)}K'
                  : count.toString(),
              style: AppTheme.greyTextStyle.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
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
              child: CircularProgressIndicator(color: AppColors.purpleColor),
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
      double safeHeight, double minScroll, double maxScroll) {
    return Positioned(
      right: 0,
      top: 8,
      bottom: 20,
      width: 80,
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
          _buildDraggableHandle(safeHeight, minScroll, maxScroll),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          label: 'Reply',
          onTap: _openComments,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
          label: 'Save',
          onTap: _toggleSave,
          isActive: isSaved,
          activeColor: Colors.amber,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () {},
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
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? activeColor?.withOpacity(0.8)
                  : Colors.white.withOpacity(0.15),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.9),
              size: 18,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            showCount && count > 0 ? '$count' : label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: showCount && count > 0 ? 10 : 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableHandle(
      double safeHeight, double minScroll, double maxScroll) {
    return Positioned(
      left: 0,
      top: (safeHeight / 2 - 35) + _handleOffset,
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
      right: 80,
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
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (content.isNotEmpty && mediaType != null)
                      Text(
                        content,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
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
