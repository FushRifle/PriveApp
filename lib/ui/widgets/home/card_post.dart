import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/ui/pages/main/home/post_detail_page.dart';
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
    if (!mounted) return;

    if (isLiked) {
      context.read<FeedBloc>().add(UnlikeFeedPost(postId: widget.post.id));
    } else {
      context.read<FeedBloc>().add(LikeFeedPost(postId: widget.post.id));
    }
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
      if (likeCount < 0) likeCount = 0;
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<FeedBloc>(),
                child: PostDetailPage(
                  postId: widget.post.id,
                ),
              ),
            ),
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
              color: AppColors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  count: likeCount,
                  color: isLiked ? AppColors.redAccent : AppColors.white,
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: commentCount,
                  color: AppColors.white,
                  onTap: _openComments,
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.bookmark_border,
                  count: null,
                  color: AppColors.white,
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
                  color: AppColors.white,
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
                  color: AppColors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.2),
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
                        color: AppColors.white,
                        width: 0.1,
                      ),
                    ),
                    child: Text(
                      _formatCount(count),
                      style: const TextStyle(
                        color: AppColors.white,
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
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (!widget.isDetailView) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<FeedBloc>(),
                    child: PostDetailPage(
                      postId: widget.post.id,
                    ),
                  ),
                ),
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
                    _UserAvatar(
                      avatar: widget.post.user.avatar,
                      radius: 20,
                      iconSize: 18,
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
                      color:
                          isLiked ? AppColors.redAccent : AppColors.greyColor,
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
              CachedNetworkImage(
                imageUrl: videoAttachment.thumbnail!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.grey.shade900,
                  child: const Center(
                    child: Icon(Icons.video_library,
                        size: 40, color: AppColors.grey),
                  ),
                ),
              )
            else
              Container(
                color: AppColors.grey.shade900,
                child: const Center(
                  child: Icon(Icons.video_library,
                      size: 40, color: AppColors.grey),
                ),
              ),
            Positioned.fill(
              child: Container(
                color: AppColors.black.withOpacity(0.2),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: AppColors.white,
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
          child: CachedNetworkImage(
            imageUrl: imageAttachment.url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorWidget: (_, __, ___) => Container(
              color: AppColors.grey.shade200,
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
                fileName: _fileNameFromUrl(documentAttachment.url),
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
      color: AppColors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image, size: 40, color: AppColors.grey),
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
            AppColors.black.withOpacity(0.3),
            AppColors.transparent,
            AppColors.transparent,
            AppColors.black.withOpacity(0.4),
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
          _UserAvatar(
            avatar: widget.post.user.avatar,
            radius: 14,
            iconSize: 12,
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

  String _fileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final name = Uri.decodeComponent(uri.pathSegments.last).trim();
      if (name.isNotEmpty) return name;
    }

    final fallback = url.split('/').last.trim();
    return fallback.isEmpty ? 'Document' : fallback;
  }
}

class _UserAvatar extends StatelessWidget {
  final String avatar;
  final double radius;
  final double iconSize;

  const _UserAvatar({
    required this.avatar,
    required this.radius,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    if (avatar.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(avatar),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.greyColor.withOpacity(0.2),
      child: Icon(Icons.person, size: iconSize, color: AppColors.grey),
    );
  }
}
