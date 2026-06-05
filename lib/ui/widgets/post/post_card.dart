import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/ui/pages/main/home/post_detail_page.dart';
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
  late bool _isSaved;
  late bool _isReposted;
  late int _likeCount;
  late int _commentCount;
  late int _shareCount;
  late int _repostCount;

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
        oldWidget.post.shares != widget.post.shares ||
        oldWidget.post.reposts != widget.post.reposts ||
        oldWidget.post.isLiked != widget.post.isLiked ||
        oldWidget.post.isSaved != widget.post.isSaved ||
        oldWidget.post.isReposted != widget.post.isReposted) {
      _syncPostState();
    }
  }

  void _syncPostState() {
    _isLiked = widget.post.isLiked;
    _isSaved = widget.post.isSaved;
    _isReposted = widget.post.isReposted;
    _likeCount = widget.post.likes;
    _commentCount = widget.post.comments;
    _shareCount = widget.post.shares;
    _repostCount = widget.post.reposts;
  }

  void _openDetail() {
    if (widget.isDetailView) return;

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

  void _toggleLike() {
    if (!mounted) return;

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

  void _showPostOptions() {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (_) {
        return _PostOptionsSheet(
          canEdit: !_hasMedia,
          onEdit: () {
            Navigator.pop(context);
            _showEditDialog();
          },
          onDelete: () {
            Navigator.pop(context);
            _confirmDelete();
          },
          onRepost: () {
            Navigator.pop(context);
            _repost();
          },
          onShare: () {
            Navigator.pop(context);
            _share();
          },
          onReport: () {
            Navigator.pop(context);
            _showComingSoon('Report submitted');
          },
        );
      },
    );
  }

  void _toggleSave() {
    HapticFeedback.lightImpact();

    final wasSaved = _isSaved;

    setState(() {
      _isSaved = !wasSaved;
    });

    if (wasSaved) {
      context.read<FeedBloc>().add(UnsaveFeedPost(postId: widget.post.id));
      _showComingSoon('Removed from saved posts');
    } else {
      context.read<FeedBloc>().add(SaveFeedPost(postId: widget.post.id));
      _showComingSoon('Post saved');
    }
  }

  void _share() {
    HapticFeedback.lightImpact();

    setState(() {
      _shareCount += 1;
    });

    context.read<FeedBloc>().add(ShareFeedPost(postId: widget.post.id));
    _showComingSoon('Share recorded');
  }

  void _repost() {
    if (_isReposted) {
      _showComingSoon('Already reposted');
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _isReposted = true;
      _repostCount += 1;
    });

    context.read<FeedBloc>().add(RepostFeedPost(postId: widget.post.id));
    _showComingSoon('Reposted');
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Post',
            style: TextStyle(color: AppColors.text),
          ),
          content: Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.greyColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<FeedBloc>().add(
                      DeleteFeedPost(postId: widget.post.id),
                    );
                _showComingSoon('Post deleted');
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.redColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: widget.post.content);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit Post',
            style: TextStyle(color: AppColors.text),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            maxLength: 2200,
            style: TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Update your post...',
              hintStyle: TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.backgroundColor,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.greyColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final content = controller.text.trim();

                if (content.isEmpty) return;

                Navigator.pop(context);
                context.read<FeedBloc>().add(
                      UpdateFeedPost(
                        postId: widget.post.id,
                        content: content,
                      ),
                    );
                _showComingSoon('Post updated');
              },
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _showComingSoon(String message) {
    if (!mounted) return;

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
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.cardBorderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowElevated,
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
                onMoreTap: widget.isDetailView ? null : _showPostOptions,
              ),
              if (widget.post.content.trim().isNotEmpty)
                PostFooter(
                  post: widget.post,
                  isTextOnly: !_hasMedia,
                  maxLines: widget.isDetailView ? null : (_hasMedia ? 3 : 5),
                ),
              if (_hasMedia)
                PostMedia(
                  post: widget.post,
                  isDetailView: widget.isDetailView,
                ),
              PostActions(
                isLiked: _isLiked,
                likeCount: _likeCount,
                commentCount: _commentCount,
                shareCount: _shareCount,
                repostCount: _repostCount,
                isSaved: _isSaved,
                isReposted: _isReposted,
                onLike: _toggleLike,
                onComment: _openComments,
                onSave: _toggleSave,
                onShare: _share,
                onRepost: _repost,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostOptionsSheet extends StatelessWidget {
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRepost;
  final VoidCallback onShare;
  final VoidCallback onReport;

  const _PostOptionsSheet({
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    required this.onRepost,
    required this.onShare,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (canEdit)
              _PostOptionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Post',
                onTap: onEdit,
              ),
            _PostOptionTile(
              icon: Icons.delete_outline,
              title: 'Delete Post',
              color: AppColors.redColor,
              onTap: onDelete,
            ),
            Divider(height: 1, color: AppColors.divider),
            _PostOptionTile(
              icon: Icons.repeat_rounded,
              title: 'Repost',
              onTap: onRepost,
            ),
            _PostOptionTile(
              icon: Icons.share_outlined,
              title: 'Share',
              onTap: onShare,
            ),
            Divider(height: 1, color: AppColors.divider),
            _PostOptionTile(
              icon: Icons.flag_outlined,
              title: 'Report Post',
              color: AppColors.redColor,
              onTap: onReport,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _PostOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;

  const _PostOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.text;

    return ListTile(
      leading: Icon(
        icon,
        color: effectiveColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}
