import 'dart:ui';
import 'dart:async';

import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/data/models/feeds_models.dart';
import 'package:clique/ui/widgets/home/card_post.dart';
import 'package:clique/data/services/user/user_service.dart';

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
  bool _isLoadingComments = false;
  bool _isLoadingPost = true;
  int _commentsPage = 1;
  bool _hasMoreComments = false;
  String? _commentsError;
  Timer? _commentsTimeoutTimer;
  int _currentUserId = 0;
  bool _isOwnPost = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentsTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUser();
      setState(() {
        _currentUserId = user['id'] ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  void _loadPost() {
    setState(() => _isLoadingPost = true);
    final currentPosts = context.read<FeedBloc>().state.posts;
    try {
      final existingPost =
          currentPosts.firstWhere((p) => p.id == widget.postId);
      setState(() {
        _post = existingPost;
        _isOwnPost = _currentUserId == existingPost.user;
        _isLoadingPost = false;
      });
      _loadComments();
    } catch (e) {
      setState(() {
        _isLoadingPost = false;
      });
      _loadComments();
    }
  }

  void _loadComments() {
    _commentsTimeoutTimer?.cancel();
    setState(() {
      _isLoadingComments = true;
      _commentsError = null;
    });

    _commentsTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLoadingComments) {
        setState(() {
          _isLoadingComments = false;
          _commentsError = 'Request timed out. Please try again.';
        });
      }
    });

    context
        .read<FeedBloc>()
        .add(GetPostComments(postId: widget.postId, page: _commentsPage));
  }

  void _retryLoadComments() {
    _commentsPage = 1;
    _loadComments();
  }

  void _loadMoreComments() {
    if (!_hasMoreComments || _isLoadingComments) return;
    _commentsPage++;
    _loadComments();
  }

  void _addComment(String text) {
    final value = text.trim();
    if (value.isEmpty || _post == null) return;

    HapticFeedback.lightImpact();
    _commentController.clear();

    context.read<FeedBloc>().add(CreatePostComment(
          postId: widget.postId,
          content: value,
        ));

    _commentsPage = 1;
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadComments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: BlocListener<FeedBloc, FeedState>(
        listener: (context, state) {
          if (state.comments[widget.postId] != null && mounted) {
            _commentsTimeoutTimer?.cancel();
            setState(() {
              _comments = state.comments[widget.postId]!;
              _hasMoreComments = state.hasMoreComments[widget.postId] ?? false;
              _isLoadingComments = false;
              _commentsError = null;
            });
          }
          if (state.generalError != null && mounted) {
            setState(() {
              _isLoadingComments = false;
              _commentsError = state.generalError;
            });
          }

          if (_post != null) {
            final updatedPost = state.posts.firstWhere(
              (p) => p.id == widget.postId,
              orElse: () => _post!,
            );
            if (updatedPost.id == _post!.id &&
                updatedPost.likes != _post!.likes) {
              setState(() {
                _post = updatedPost;
              });
            }
          }
        },
        child: _buildBody(bottomInset),
      ),
    );
  }

  Widget _buildBody(double bottomInset) {
    if (_isLoadingPost) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_post == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Post not found', style: AppTheme.greyTextStyle),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildModernAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: CardPost(
                  post: _post!,
                  isDetailView: true,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildCommentHeader()),
            _buildCommentsSection(),
            SliverToBoxAdapter(
              child: SizedBox(height: 130 + bottomInset),
            ),
          ],
        ),
        _buildModernBottomBar(),
      ],
    );
  }

  Widget _buildCommentsSection() {
    if (_isLoadingComments && _comments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_commentsError != null && _comments.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_commentsError!, style: AppTheme.greyTextStyle),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _retryLoadComments,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 48),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_comments.isEmpty) {
      return const SliverToBoxAdapter(
        child: _EmptyComments(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == _comments.length - 1 && _hasMoreComments) {
              _loadMoreComments();
            }
            return _buildModernComment(_comments[index]);
          },
          childCount: _comments.length,
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white.withOpacity(0.95),
      foregroundColor: Colors.black,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.more_horiz, size: 22),
            color: Colors.black,
            onPressed: _showPostOptions,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Comments',
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              fontSize: 13,
              color: AppColors.blackTextColor,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Recent First',
              style: TextStyle(
                color: AppColors.blackTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernComment(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(comment.userAvatar, size: 40),
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
                        style: AppTheme.blackTextStyle.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      comment.formattedTimeAgo,
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(_post!.user.avatar, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (value) => _addComment(value),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _commentController.text.trim().isNotEmpty
                  ? () => _addComment(_commentController.text)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _commentController.text.trim().isNotEmpty
                      ? AppColors.primary
                      : AppColors.greyColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: _commentController.text.trim().isNotEmpty
                      ? Colors.white
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String avatar, {required double size}) {
    if (avatar.isEmpty) {
      return _avatarFallback(size);
    }

    if (avatar.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(size),
        ),
      );
    }

    return ClipOval(
      child: Image.asset(
        avatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarFallback(size),
      ),
    );
  }

  Widget _avatarFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.12),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: AppColors.primary,
      ),
    );
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildOptionTile(Icons.link, 'Copy Link', Colors.black87, () {
                Navigator.pop(context);
              }),
              _buildOptionTile(
                  Icons.share_outlined, 'Share Post', Colors.black87, () {
                Navigator.pop(context);
              }),
              if (_isOwnPost) ...[
                const Divider(height: 1),
                _buildOptionTile(
                    Icons.delete_outline, 'Delete Post', Colors.redAccent, () {
                  Navigator.pop(context);
                  _confirmDelete();
                }),
              ],
              const Divider(height: 1),
              _buildOptionTile(Icons.flag_outlined, 'Report', Colors.redAccent,
                  () {
                Navigator.pop(context);
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.greyColor)),
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
      ),
    );
  }

  void _deletePost() {
    context.read<FeedBloc>().add(DeleteFeedPost(postId: widget.postId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post deleted'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildOptionTile(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.greyColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment!',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
