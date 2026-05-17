import 'dart:ui';
import 'package:Prive/bloc/home/feed_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/models/feeds_models.dart';
import 'package:video_player/video_player.dart';
import 'package:Prive/ui/widgets/home/clip_status_bar.dart';
import 'package:Prive/ui/widgets/home/custom_bottom_sheet.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';

class CardPost extends StatefulWidget {
  final FeedPost post;
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
  late bool isLiked;
  late int likeCount;
  late int commentCount;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLiked;
    likeCount = widget.post.likes;
    commentCount = widget.post.comments;

    _checkForVideo();
  }

  void _checkForVideo() {
    final videoAttachment = widget.post.attachments.firstWhere(
      (a) => a.type == 'video',
      orElse: () => Attachment(type: '', url: ''),
    );

    if (videoAttachment.url.isNotEmpty) {
      _initializeVideoController(videoAttachment.url);
    }
  }

  void _initializeVideoController(String videoUrl) {
    _videoController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
        }
      }).catchError((error) {
        debugPrint('Error initializing video: $error');
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleLike() {
    if (isLiked) {
      context.read<FeedBloc>().add(UnlikeFeedPost(postId: widget.post.id));
    } else {
      context.read<FeedBloc>().add(LikeFeedPost(postId: widget.post.id));
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

  void _toggleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Save feature coming soon'),
        duration: Duration(seconds: 1),
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
    customBottomSheetComments(context, postId: widget.post.id);
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
            child: widget.post.attachments.isEmpty
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
          arguments: widget.post.toJson(),
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
                if (widget.post.user.avatar.isNotEmpty)
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(widget.post.user.avatar),
                    onBackgroundImageError: (_, __) {},
                  ),
                if (widget.post.user.avatar.isNotEmpty)
                  const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.post.user.name,
                        style: AppTheme.blackTextStyle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.post.time,
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
              widget.post.content,
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
                    icon: Icons.bookmark_border,
                    count: 0,
                    onTap: _toggleSave,
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

  Widget _buildMediaContent() {
    final imageAttachment = widget.post.attachments.firstWhere(
      (a) => a.type == 'image',
      orElse: () => Attachment(type: '', url: ''),
    );

    final videoAttachment = widget.post.attachments.firstWhere(
      (a) => a.type == 'video',
      orElse: () => Attachment(type: '', url: ''),
    );

    if (videoAttachment.url.isNotEmpty &&
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
    } else if (imageAttachment.url.isNotEmpty) {
      return Image.network(
        imageAttachment.url,
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
          widget.post.content.isNotEmpty
              ? widget.post.content
              : 'No media content',
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
          icon: Icons.bookmark_border,
          label: 'Save',
          onTap: _toggleSave,
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
              if (widget.post.user.avatar.isNotEmpty)
                CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(widget.post.user.avatar),
                  onBackgroundImageError: (_, __) {},
                ),
              if (widget.post.user.avatar.isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.post.user.name,
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.post.content.isNotEmpty &&
                        widget.post.attachments.isNotEmpty)
                      Text(
                        widget.post.content,
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
