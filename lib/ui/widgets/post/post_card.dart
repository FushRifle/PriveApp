import 'package:clique/core/router/named_routes.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/data/models/feeds_models.dart';
import 'package:clique/ui/widgets/home/custom_bottom_sheet.dart';
import 'package:clique/ui/widgets/post/post_actions.dart';
import 'package:clique/ui/widgets/post/post_footer.dart';
import 'package:clique/ui/widgets/post/post_header.dart';
import 'package:clique/ui/widgets/post/post_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CardPost extends StatefulWidget {
  final FeedPost post;
  final bool isDetailView;

  const CardPost({
    super.key,
    required this.post,
    this.isDetailView = false,
  });

  @override
  State<CardPost> createState() => _CardPostState();
}

class _CardPostState extends State<CardPost> {
  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;

  bool get _hasMedia => widget.post.attachments.isNotEmpty;

  @override
  void initState() {
    super.initState();

    _syncPostState();
  }

  @override
  void didUpdateWidget(covariant CardPost oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likes != widget.post.likes ||
        oldWidget.post.comments != widget.post.comments ||
        oldWidget.post.isLiked != widget.post.isLiked) {
      _syncPostState();
    }
  }

  void _syncPostState() {
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
    _commentCount = widget.post.comments;
  }

  void _openDetail() {
    if (widget.isDetailView) return;

    Navigator.pushNamed(
      context,
      NamedRoutes.postDetailScreen,
      arguments: widget.post.id,
    );
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();

    final wasLiked = _isLiked;

    setState(() {
      _isLiked = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;

      if (_likeCount < 0) {
        _likeCount = 0;
      }
    });

    if (wasLiked) {
      context.read<FeedBloc>().add(
            UnlikeFeedPost(postId: widget.post.id),
          );
    } else {
      context.read<FeedBloc>().add(
            LikeFeedPost(postId: widget.post.id),
          );
    }
  }

  void _openComments() {
    HapticFeedback.lightImpact();

    if (widget.isDetailView) return;

    customBottomSheetComments(
      context,
      postId: widget.post.id,
    );
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openDetail,
        child: Container(
          margin: EdgeInsets.only(
            bottom: widget.isDetailView ? 0 : 18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PostHeader(
                post: widget.post,
                onMoreTap: () => _showComingSoon('Post options coming soon'),
              ),
              if (_hasMedia)
                PostMedia(
                  post: widget.post,
                  isDetailView: widget.isDetailView,
                ),
              if (widget.post.content.trim().isNotEmpty)
                PostFooter(
                  post: widget.post,
                  isTextOnly: !_hasMedia,
                  maxLines: widget.isDetailView ? null : (_hasMedia ? 3 : 5),
                ),
              PostActions(
                isLiked: _isLiked,
                likeCount: _likeCount,
                commentCount: _commentCount,
                onLike: _toggleLike,
                onComment: _openComments,
                onSave: () => _showComingSoon('Save feature coming soon'),
                onShare: () => _showComingSoon('Share feature coming soon'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
