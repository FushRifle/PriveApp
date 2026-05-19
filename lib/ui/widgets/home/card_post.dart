import 'dart:ui';

import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/ui/widgets/ui/document_viewer.dart';
import 'package:clique/ui/widgets/ui/image_viewer.dart';
import 'package:clique/ui/widgets/ui/video_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/data/models/feeds_models.dart';
import 'package:video_player/video_player.dart';
import 'package:clique/ui/widgets/home/custom_bottom_sheet.dart';
import 'package:clique/app/resources/constant/named_routes.dart';

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
      likeCount += isLiked ? 1 : -1;
    });
  }

  void _openComments() {
    customBottomSheetComments(context, postId: widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = GestureDetector(
      onTap: () {
        if (!widget.isDetailView) {
          Navigator.pushNamed(
            context,
            NamedRoutes.postDetailScreen,
            arguments: widget.post.id,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: widget.post.attachments.isEmpty
              ? _buildTextOnlyPost()
              : Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildMediaContent(),
                          _buildOverlay(),
                        ],
                      ),
                    ),
                    _buildBottomBar(),
                    _buildActionButtons(),
                  ],
                ),
        ),
      ),
    );

    return cardContent;
  }

  Widget _buildActionButtons() {
    return Positioned(
      right: 5,
      bottom: 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  count: likeCount,
                  color: isLiked ? Colors.redAccent : Colors.white,
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: commentCount,
                  color: Colors.white,
                  onTap: _openComments,
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.bookmark_border,
                  count: null,
                  color: Colors.white,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Save feature coming soon'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  count: null,
                  color: Colors.white,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share feature coming soon'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    int? count,
    required Color color,
    required VoidCallback onTap,
  }) {
    final hasCount = count != null && count > 0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (hasCount)
                Positioned(
                  top: -1,
                  right: 2,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 10,
                      minHeight: 10,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColorDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white,
                        width: 0.1,
                      ),
                    ),
                    child: Text(
                      _formatCount(count!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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

  Widget _buildTextOnlyPost() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (!widget.isDetailView) {
              Navigator.pushNamed(
                context,
                NamedRoutes.postDetailScreen,
                arguments: widget.post.id,
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: widget.post.user.avatar.isNotEmpty
                          ? NetworkImage(widget.post.user.avatar)
                          : null,
                      child: widget.post.user.avatar.isEmpty
                          ? Icon(Icons.person, size: 18, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.post.user.name,
                                style: AppTheme.blackTextStyle.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (widget.post.user.verified)
                                Icon(Icons.verified,
                                    size: 12, color: AppColors.primary),
                            ],
                          ),
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
                const SizedBox(height: 12),
                Text(
                  widget.post.content,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 15,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInlineButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      label: likeCount > 0 ? _formatCount(likeCount) : '',
                      color: isLiked ? Colors.redAccent : AppColors.greyColor,
                      onTap: _toggleLike,
                    ),
                    const SizedBox(width: 16),
                    _buildInlineButton(
                      icon: Icons.chat_bubble_outline,
                      label: commentCount > 0 ? _formatCount(commentCount) : '',
                      color: AppColors.greyColor,
                      onTap: _openComments,
                    ),
                    const Spacer(),
                    Icon(Icons.bookmark_border,
                        size: 18, color: AppColors.greyColor),
                    const SizedBox(width: 16),
                    Icon(Icons.share_outlined,
                        size: 18, color: AppColors.greyColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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

    final documentAttachment = widget.post.attachments.firstWhere(
      (a) => a.type == 'document' || a.type == 'file' || a.type == 'pdf',
      orElse: () => Attachment(type: '', url: ''),
    );

    if (videoAttachment.url.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoViewer(
                videoUrl: videoAttachment.url,
                thumbnailUrl: videoAttachment.thumbnail,
                caption:
                    widget.post.content.isNotEmpty ? widget.post.content : null,
              ),
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isVideoInitialized && _videoController != null)
              VideoPlayer(_videoController!)
            else if (videoAttachment.thumbnail != null &&
                videoAttachment.thumbnail!.isNotEmpty)
              Image.network(
                videoAttachment.thumbnail!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade900,
                  child: const Center(
                    child:
                        Icon(Icons.video_library, size: 40, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                color: Colors.grey.shade900,
                child: const Center(
                  child:
                      Icon(Icons.video_library, size: 40, color: Colors.grey),
                ),
              ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.2),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (imageAttachment.url.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageViewer(
                imageUrl: imageAttachment.url,
                caption:
                    widget.post.content.isNotEmpty ? widget.post.content : null,
              ),
            ),
          );
        },
        child: Hero(
          tag: 'post_image_${widget.post.id}',
          child: Image.network(
            imageAttachment.url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, size: 40),
            ),
          ),
        ),
      );
    }

    if (documentAttachment.url.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentViewer(
                documentUrl: documentAttachment.url,
                fileName: documentAttachment.url.split('/').last,
                caption:
                    widget.post.content.isNotEmpty ? widget.post.content : null,
              ),
            ),
          );
        },
        child: Container(
          color: AppColors.cardColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insert_drive_file,
                  size: 48,
                  color: AppColors.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap to view document',
                  style: AppTheme.blackTextStyle.copyWith(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.4),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      left: 12,
      right: 70,
      bottom: 18,
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: widget.post.user.avatar.isNotEmpty
                ? NetworkImage(widget.post.user.avatar)
                : null,
            child: widget.post.user.avatar.isEmpty
                ? const Icon(Icons.person, size: 12)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.post.user.name,
                  style: AppTheme.whiteTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.post.content.isNotEmpty)
                  Text(
                    widget.post.content,
                    style: AppTheme.whiteTextStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
}
