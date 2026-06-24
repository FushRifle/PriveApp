import 'dart:async';

import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:clique/ui/widgets/post/anonymous/anonymous_post_card.dart';
import 'package:clique/ui/pages/main/home/edit_post_page.dart';
import 'package:clique/ui/pages/main/home/post_detail_page.dart';
import 'package:clique/ui/pages/main/home/repost_page.dart';
import 'package:clique/ui/widgets/post/poll/poll_post_card.dart';
import 'package:clique/ui/widgets/post/question/question_post_card.dart';

import 'package:clique/ui/widgets/home/custom_bottom_sheet.dart';
import 'package:clique/ui/widgets/post/normal-post/post_actions.dart';
import 'package:clique/ui/widgets/post/normal-post/post_footer.dart';
import 'package:clique/ui/widgets/post/normal-post/post_header.dart';
import 'package:clique/ui/widgets/post/normal-post/post_media.dart';
import 'package:clique/ui/widgets/post/normal-post/post_reaction_picker.dart';

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
  final UserService _userService = UserService();
  final FeedService _feedService = FeedService();
  final GlobalKey _likeActionKey = GlobalKey();
  late bool _isLiked;
  late bool _isSaved;
  late bool _isReposted;
  late int _likeCount;
  late int _commentCount;
  late int _shareCount;
  late int _repostCount;
  late int _viewCount;
  IconData? _selectedReactionIcon;
  Color? _selectedReactionColor;
  String? _selectedReactionLabel;
  bool _isOwnPost = false;

  bool get _hasMedia => widget.post.attachments.isNotEmpty;
  bool get _canEditPost =>
      _isOwnPost &&
      DateTime.now().difference(widget.post.createdAt) <=
          const Duration(hours: 2);

  @override
  void initState() {
    super.initState();

    _syncPostState();
    _loadOwnership();
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
    _viewCount = widget.post.views;
    if (_isLiked) {
      _selectedReactionIcon = Icons.favorite_rounded;
      _selectedReactionColor = AppColors.redAccent;
      _selectedReactionLabel = 'Love';
    } else {
      _selectedReactionIcon = null;
      _selectedReactionColor = null;
      _selectedReactionLabel = null;
    }
  }

  Future<void> _loadOwnership() async {
    try {
      final user = await _userService.getCurrentUser();
      final currentUserId = _readInt(user['id']);
      if (!mounted || currentUserId <= 0) return;
      setState(() {
        _isOwnPost = widget.post.user.id == currentUserId;
      });
    } catch (_) {}
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _openDetail() {
    if (widget.isDetailView) return;

    unawaited(_recordView());

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

  Future<void> _recordView() async {
    try {
      final views = await _feedService.recordPostView(widget.post.id);
      if (mounted && views > 0) setState(() => _viewCount = views);
    } catch (_) {}
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

      if (_isLiked) {
        _selectedReactionIcon = Icons.favorite_rounded;
        _selectedReactionColor = AppColors.redAccent;
        _selectedReactionLabel = 'Love';
      } else {
        _selectedReactionIcon = null;
        _selectedReactionColor = null;
        _selectedReactionLabel = null;
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

  void _showReactionSheet() {
    final box = _likeActionKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      showPostReactionPicker(
        context,
        onSelected: _applyReaction,
      );
      return;
    }

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) {
      showPostReactionPicker(
        context,
        onSelected: _applyReaction,
      );
      return;
    }

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight =
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay);
    final anchor = Rect.fromLTRB(
      topLeft.dx,
      topLeft.dy,
      bottomRight.dx,
      bottomRight.dy,
    );

    showPostReactionPicker(
      context,
      onSelected: _applyReaction,
      anchorRect: anchor,
    );
  }

  void _applyReaction(PostReaction reaction) {
    final wasLiked = _isLiked;

    setState(() {
      _isLiked = true;
      _selectedReactionIcon = reaction.icon;
      _selectedReactionColor = reaction.color;
      _selectedReactionLabel = reaction.label;
      if (!wasLiked) {
        _likeCount += 1;
      }
    });

    if (!wasLiked) {
      context.read<FeedBloc>().add(
            LikeFeedPost(postId: widget.post.id),
          );
    }

    _showComingSoon('${reaction.label} reaction added');
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
    final editWindowRemaining = widget.post.createdAt
        .add(const Duration(hours: 2))
        .difference(DateTime.now());

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (_) {
        return _PostOptionsSheet(
          canEdit: _canEditPost,
          canDelete: _isOwnPost,
          editWindowRemaining: editWindowRemaining,
          onEdit: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<FeedBloc>(),
                  child: EditPostPage(
                    postId: widget.post.id,
                    ownerId: widget.post.user.id,
                    initialContent: widget.post.content,
                    createdAt: widget.post.createdAt,
                  ),
                ),
              ),
            );
          },
          onDelete: () {
            Navigator.pop(context);
            if (_isOwnPost) {
              _confirmDelete();
            }
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
    _showRepostSheet();
  }

  void _showRepostSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.repeat_rounded),
                  title: Text(
                    'Repost',
                    style: TextStyle(color: AppColors.text),
                  ),
                  subtitle: Text(
                    'Share this post instantly',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _performRepost(
                      postType: widget.post.postType,
                      isAnonymous: widget.post.isAnonymous,
                      anonymousCategory: widget.post.anonymousCategory,
                      pollOptions: widget.post.pollOptions.isNotEmpty
                          ? widget.post.pollOptions
                          : null,
                      pollExpirationHours: widget.post.pollExpirationHours,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded),
                  title: Text(
                    'Repost with caption',
                    style: TextStyle(color: AppColors.text),
                  ),
                  subtitle: Text(
                    'Add your own text before reposting',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openRepostPage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openRepostPage() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<FeedBloc>(),
          child: RepostPage(post: widget.post),
        ),
      ),
    );
  }

  void _performRepost({
    String content = '',
    String postType = 'standard',
    bool isAnonymous = false,
    String? anonymousCategory,
    List<String>? pollOptions,
    int? pollExpirationHours,
  }) {
    setState(() {
      _isReposted = true;
      _repostCount += 1;
    });

    context.read<FeedBloc>().add(
          RepostFeedPost(
            postId: widget.post.id,
            content: content,
            postType: postType,
            isAnonymous: isAnonymous,
            anonymousCategory: anonymousCategory,
            pollOptions: pollOptions,
            pollExpirationHours: pollExpirationHours,
          ),
        );
    _showComingSoon(
      content.isEmpty ? 'Reposted' : 'Reposted with caption',
    );
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardColor.withOpacity(0.98),
                AppColors.cardColor,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.cardBorderColor.withOpacity(0.88),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowElevated.withOpacity(0.78),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PostHeader(
                post: widget.post,
                isOwnProfile: _isOwnPost,
                onMoreTap: widget.isDetailView ? null : _showPostOptions,
              ),
              if (widget.post.isPoll)
                PollPostBody(
                  post: widget.post,
                  isDetailView: widget.isDetailView,
                )
              else if (widget.post.isQuestion)
                QuestionPostBody(
                  post: widget.post,
                  isDetailView: widget.isDetailView,
                )
              else if (widget.post.isAnonymousPost)
                AnonymousPostBody(
                  post: widget.post,
                  isDetailView: widget.isDetailView,
                )
              else if (widget.post.content.trim().isNotEmpty)
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
                viewCount: _viewCount,
                repostCount: _repostCount,
                isSaved: _isSaved,
                isReposted: _isReposted,
                onLike: _toggleLike,
                onLikeLongPress: _showReactionSheet,
                likeActionKey: _likeActionKey,
                onComment: _openComments,
                onSave: _toggleSave,
                onShare: _share,
                onRepost: _repost,
                selectedReactionIcon: _selectedReactionIcon,
                selectedReactionColor: _selectedReactionColor,
                selectedReactionLabel: _selectedReactionLabel,
                showLikeAction: !widget.post.isPoll,
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
  final bool canDelete;
  final Duration editWindowRemaining;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRepost;
  final VoidCallback onShare;
  final VoidCallback onReport;

  const _PostOptionsSheet({
    required this.canEdit,
    required this.canDelete,
    required this.editWindowRemaining,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardColor,
            AppColors.backgroundColor.withOpacity(0.96),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyColor.withOpacity(0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (canEdit)
              Column(
                children: [
                  _PostOptionTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Post',
                    onTap: onEdit,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Edit expires in ${_formatEditWindow(editWindowRemaining)}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (canDelete) ...[
              _PostOptionTile(
                icon: Icons.delete_outline,
                title: 'Delete Post',
                color: AppColors.redColor,
                onTap: onDelete,
              ),
              Divider(height: 1, color: AppColors.divider),
            ],
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

String _formatEditWindow(Duration duration) {
  if (duration <= Duration.zero) return '0m';

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours > 0 && minutes > 0) {
    return '$hours h $minutes m';
  }

  if (hours > 0) {
    return '$hours h';
  }

  return '$minutes m';
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
