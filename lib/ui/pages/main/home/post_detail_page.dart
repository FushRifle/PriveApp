import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

import 'package:clique/bloc/home/feed_bloc.dart';

import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/user/user_service.dart';

import 'package:clique/ui/widgets/post/post_card.dart';

class PostDetailPage extends StatefulWidget {
  final int postId;

  const PostDetailPage({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserService _userService = UserService();

  FeedPost? _post;
  List<Comment> _comments = [];

  bool _isLoadingPost = true;
  bool _isLoadingComments = false;
  bool _isSendingComment = false;
  bool _hasMoreComments = false;
  bool _canSendComment = false;
  bool _didRequestMore = false;

  int _commentsPage = 1;
  int _currentUserId = 0;

  String? _commentsError;

  Timer? _commentsTimeoutTimer;
  Timer? _commentReloadTimer;

  @override
  void initState() {
    super.initState();

    _commentController.addListener(_onCommentChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void dispose() {
    _commentsTimeoutTimer?.cancel();
    _commentReloadTimer?.cancel();

    _commentController
      ..removeListener(_onCommentChanged)
      ..dispose();

    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadCurrentUser();
    _loadPostFromBloc();
    _loadComments(reset: true);
  }

  void _onCommentChanged() {
    final canSend = _commentController.text.trim().isNotEmpty;

    if (canSend == _canSendComment) return;

    setState(() {
      _canSendComment = canSend;
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUser();

      if (!mounted) return;

      setState(() {
        _currentUserId = _readInt(user['id']);
      });
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  void _loadPostFromBloc() {
    final posts = context.read<FeedBloc>().state.posts;

    FeedPost? found;

    for (final post in posts) {
      if (post.id == widget.postId) {
        found = post;
        break;
      }
    }

    if (!mounted) return;

    setState(() {
      _post = found;
      _isLoadingPost = false;
    });
  }

  void _loadComments({
    bool reset = false,
  }) {
    if (_isLoadingComments && !reset) return;

    _commentsTimeoutTimer?.cancel();

    if (reset) {
      _commentsPage = 1;
      _didRequestMore = false;
    }

    setState(() {
      _isLoadingComments = true;
      _commentsError = null;
    });

    _commentsTimeoutTimer = Timer(
      const Duration(seconds: 12),
      () {
        if (!mounted || !_isLoadingComments) return;

        setState(() {
          _isLoadingComments = false;
          _commentsError = 'Request timed out. Please try again.';
        });
      },
    );

    context.read<FeedBloc>().add(
          GetPostComments(
            postId: widget.postId,
            page: _commentsPage,
          ),
        );
  }

  void _loadMoreComments() {
    if (!_hasMoreComments || _isLoadingComments || _didRequestMore) return;

    _didRequestMore = true;
    _commentsPage += 1;
    _loadComments();
  }

  void _retryLoadComments() {
    _loadComments(reset: true);
  }

  void _addComment(String text) {
    final value = text.trim();

    if (value.isEmpty || _isSendingComment) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isSendingComment = true;
    });

    _commentController.clear();

    context.read<FeedBloc>().add(
          CreatePostComment(
            postId: widget.postId,
            content: value,
          ),
        );

    _commentReloadTimer?.cancel();

    _commentReloadTimer = Timer(
      const Duration(milliseconds: 550),
      () {
        if (!mounted) return;

        setState(() {
          _isSendingComment = false;
        });

        _loadComments(reset: true);
      },
    );
  }

  bool get _isOwnPost {
    final post = _post;

    if (post == null || _currentUserId <= 0) return false;

    return _readPostUserId(post) == _currentUserId;
  }

  int _readPostUserId(FeedPost post) {
    final dynamic user = post.user;

    if (user is int) return user;

    try {
      final dynamic id = user.id;
      return _readInt(id);
    } catch (_) {
      return 0;
    }
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: BlocListener<FeedBloc, FeedState>(
        listenWhen: (previous, current) {
          return previous.comments[widget.postId] !=
                  current.comments[widget.postId] ||
              previous.hasMoreComments[widget.postId] !=
                  current.hasMoreComments[widget.postId] ||
              previous.generalError != current.generalError ||
              previous.posts != current.posts;
        },
        listener: (context, state) {
          final postComments = state.comments[widget.postId];

          if (postComments != null) {
            _commentsTimeoutTimer?.cancel();

            setState(() {
              _comments = postComments;
              _hasMoreComments = state.hasMoreComments[widget.postId] ?? false;
              _isLoadingComments = false;
              _commentsError = null;
              _didRequestMore = false;
            });
          }

          if (state.generalError != null && state.generalError!.isNotEmpty) {
            _commentsTimeoutTimer?.cancel();

            setState(() {
              _isLoadingComments = false;
              _isSendingComment = false;
              _commentsError = state.generalError;
              _didRequestMore = false;
            });
          }

          final updatedPost = _findUpdatedPost(state.posts);

          if (updatedPost != null && mounted) {
            setState(() {
              _post = updatedPost;
              _isLoadingPost = false;
            });
          }
        },
        child: _buildBody(keyboardInset),
      ),
    );
  }

  FeedPost? _findUpdatedPost(List<FeedPost> posts) {
    for (final post in posts) {
      if (post.id == widget.postId) {
        return post;
      }
    }

    return null;
  }

  Widget _buildBody(double keyboardInset) {
    if (_isLoadingPost) {
      return const _LoadingScreen();
    }

    final post = _post;

    if (post == null) {
      return _PostNotFound(
        onBack: () => Navigator.pop(context),
      );
    }

    return Stack(
      children: [
        const _DetailBackdrop(),
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _PostAppBar(
              onMore: _showPostOptions,
            ),
            SliverToBoxAdapter(
              child: _PostDetailSurface(
                post: post,
              ),
            ),
            SliverToBoxAdapter(
              child: _CommentsHeader(
                count: _comments.length,
              ),
            ),
            _CommentsSection(
              comments: _comments,
              isLoading: _isLoadingComments,
              error: _commentsError,
              hasMore: _hasMoreComments,
              onRetry: _retryLoadComments,
              onLoadMore: _loadMoreComments,
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 130 + keyboardInset,
              ),
            ),
          ],
        ),
        _CommentComposer(
          avatar: post.user.avatar,
          controller: _commentController,
          canSend: _canSendComment && !_isSendingComment,
          isSending: _isSendingComment,
          onSend: () => _addComment(_commentController.text),
        ),
      ],
    );
  }

  void _showPostOptions() {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (_) {
        return _PostOptionsSheet(
          isOwnPost: _isOwnPost,
          onCopyLink: () {
            Navigator.pop(context);
            _showSnackBar('Link copied');
          },
          onShare: () {
            Navigator.pop(context);
            _showSnackBar('Share coming soon');
          },
          onReport: () {
            Navigator.pop(context);
            _showSnackBar('Report submitted');
          },
          onDelete: () {
            Navigator.pop(context);
            _confirmDelete();
          },
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Post'),
          content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
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
                _deletePost();
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

  void _deletePost() {
    context.read<FeedBloc>().add(
          DeleteFeedPost(postId: widget.postId),
        );

    _showSnackBar('Post deleted');

    Navigator.pop(context, true);
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _PostAppBar extends StatelessWidget {
  final VoidCallback onMore;

  const _PostAppBar({
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.background.withOpacity(isDark ? 0.82 : 0.9),
      foregroundColor: AppColors.text,
      centerTitle: true,
      toolbarHeight: 64,
      title: Text(
        'Thread',
        style: AppTheme.blackTextStyle.copyWith(
          color: AppColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12,
            sigmaY: 12,
          ),
          child: Container(
            color: AppColors.transparent,
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _AppBarCircleButton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _AppBarCircleButton(
            icon: Icons.more_horiz,
            onTap: onMore,
          ),
        ),
      ],
    );
  }
}

class _DetailBackdrop extends StatelessWidget {
  const _DetailBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 270,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.24),
                  AppColors.secondary.withOpacity(0.18),
                  AppColors.background.withOpacity(0.0),
                ],
                stops: const [0, 0.48, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostDetailSurface extends StatelessWidget {
  final FeedPost post;

  const _PostDetailSurface({
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      child: CardPost(
        post: post,
        isDetailView: true,
      ),
    );
  }
}

class _AppBarCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card.withOpacity(0.86),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Icon(
          icon,
          color: AppColors.text,
          size: 20,
        ),
      ),
    );
  }
}

class _CommentsHeader extends StatelessWidget {
  final int count;

  const _CommentsHeader({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.78),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.12),
              ),
              child: const Icon(
                Icons.mode_comment_outlined,
                color: AppColors.secondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Replies',
                    style: AppTheme.blackTextStyle.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count == 1
                        ? '1 comment in this thread'
                        : '$count comments in this thread',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.greyTextStyle.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.09),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.12)),
              ),
              child: Text(
                'Recent',
                style: AppTheme.greyTextStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  final List<Comment> comments;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  const _CommentsSection({
    required this.comments,
    required this.isLoading,
    required this.error,
    required this.hasMore,
    required this.onRetry,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && comments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(38),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.6,
            ),
          ),
        ),
      );
    }

    if (error != null && comments.isEmpty) {
      return SliverToBoxAdapter(
        child: _CommentsError(
          message: error!,
          onRetry: onRetry,
        ),
      );
    }

    if (comments.isEmpty) {
      return const SliverToBoxAdapter(
        child: _EmptyComments(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == comments.length) {
              if (hasMore) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onLoadMore();
                });

                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              return const SizedBox(height: 8);
            }

            return RepaintBoundary(
              child: _CommentTile(
                comment: comments[index],
                isFirst: index == 0,
                isLast: index == comments.length - 1,
              ),
            );
          },
          childCount: comments.length + 1,
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isFirst;
  final bool isLast;

  const _CommentTile({
    required this.comment,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cardBorderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 21,
                top: isFirst ? 22 : -15,
                bottom: isLast ? 22 : -15,
                child: Container(
                  width: 1.5,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ThreadAvatar(
                    avatar: comment.userAvatar,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                comment.userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.greyTextStyle.copyWith(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              comment.formattedTimeAgo,
                              style: AppTheme.greyTextStyle.copyWith(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          comment.content,
                          style: AppTheme.greyTextStyle.copyWith(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThreadAvatar extends StatelessWidget {
  final String avatar;
  final double size;

  const _ThreadAvatar({
    required this.avatar,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.card,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.16),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: _Avatar(
        avatar: avatar,
        size: size,
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  final String avatar;
  final TextEditingController controller;
  final bool canSend;
  final bool isSending;
  final VoidCallback onSend;

  const _CommentComposer({
    required this.avatar,
    required this.controller,
    required this.canSend,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        color: AppColors.transparent,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            14,
            10,
            14,
            bottomPadding + 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.94),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.cardBorderColor,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.06),
                blurRadius: 22,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _Avatar(
                  avatar: avatar,
                  size: 40,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppColors.cardBorderColor,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    enabled: !isSending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Reply to this thread...',
                      hintStyle: AppTheme.greyTextStyle.copyWith(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: canSend ? onSend : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: canSend
                        ? AppColors.primary
                        : AppColors.textHint.withOpacity(0.18),
                    shape: BoxShape.circle,
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: canSend ? AppColors.white : AppColors.grey,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String avatar;
  final double size;

  const _Avatar({
    required this.avatar,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (avatar.isEmpty) {
      return _fallback();
    }

    if (avatar.startsWith('http')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(),
          placeholder: (_, __) => _fallback(),
        ),
      );
    }

    return ClipOval(
      child: Image.asset(
        avatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.12),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.58,
        color: AppColors.primary,
      ),
    );
  }
}

class _PostOptionsSheet extends StatelessWidget {
  final bool isOwnPost;
  final VoidCallback onCopyLink;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final VoidCallback onDelete;

  const _PostOptionsSheet({
    required this.isOwnPost,
    required this.onCopyLink,
    required this.onShare,
    required this.onReport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _OptionTile(
              icon: Icons.link,
              title: 'Copy Link',
              color: AppColors.black87,
              onTap: onCopyLink,
            ),
            _OptionTile(
              icon: Icons.share_outlined,
              title: 'Share Post',
              color: AppColors.black87,
              onTap: onShare,
            ),
            if (isOwnPost) ...[
              const Divider(height: 1),
              _OptionTile(
                icon: Icons.delete_outline,
                title: 'Delete Post',
                color: AppColors.redAccent,
                onTap: onDelete,
              ),
            ],
            const Divider(height: 1),
            _OptionTile(
              icon: Icons.flag_outlined,
              title: 'Report',
              color: AppColors.redAccent,
              onTap: onReport,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _CommentsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CommentsError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.redAccent.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 28,
              color: AppColors.redAccent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTheme.greyTextStyle.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 46),
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 36,
      ),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 32,
              color: AppColors.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: AppTheme.blackTextStyle.copyWith(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment',
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostNotFound extends StatelessWidget {
  final VoidCallback onBack;

  const _PostNotFound({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Post not found',
              style: AppTheme.greyTextStyle,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Stack(
        children: [
          _DetailBackdrop(),
          Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.6,
            ),
          ),
        ],
      ),
    );
  }
}
