import 'dart:ui';

import 'package:Prive/bloc/home/feed_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/models/feeds_models.dart';
import 'package:Prive/ui/widgets/home/card_post.dart';

class PostDetailPage extends StatefulWidget {
  final FeedPost post;

  const PostDetailPage({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late FeedPost _post;
  late bool _isLiked;
  late int _likeCount;
  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  int _commentsPage = 1;
  bool _hasMoreComments = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _isLiked = _post.isLiked;
    _likeCount = _post.likes;
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadComments() {
    setState(() => _isLoadingComments = true);
    context
        .read<FeedBloc>()
        .add(GetPostComments(postId: _post.id, page: _commentsPage));
  }

  void _loadMoreComments() {
    if (!_hasMoreComments || _isLoadingComments) return;
    _commentsPage++;
    setState(() => _isLoadingComments = true);
    context
        .read<FeedBloc>()
        .add(GetPostComments(postId: _post.id, page: _commentsPage));
  }

  void _toggleLike() {
    if (_isLiked) {
      context.read<FeedBloc>().add(UnlikeFeedPost(postId: _post.id));
    } else {
      context.read<FeedBloc>().add(LikeFeedPost(postId: _post.id));
    }
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  void _addComment(String text) {
    final value = text.trim();
    if (value.isEmpty) return;

    HapticFeedback.lightImpact();
    _commentController.clear();

    context.read<FeedBloc>().add(CreatePostComment(
          postId: _post.id,
          content: value,
        ));

    // Refresh comments after adding
    _commentsPage = 1;
    _loadComments();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: BlocListener<FeedBloc, FeedState>(
        listener: (context, state) {
          if (state.comments[_post.id] != null) {
            setState(() {
              _comments = state.comments[_post.id]!;
              _hasMoreComments = state.hasMoreComments[_post.id] ?? false;
              _isLoadingComments = false;
            });
          }
          if (state.generalError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.generalError!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Stack(
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
                      post: _post,
                      isDetailView: true,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildModernEngagementStats()),
                SliverToBoxAdapter(child: _buildCommentHeader()),
                if (_isLoadingComments && _comments.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (_comments.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyComments(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _comments.length - 1 &&
                              _hasMoreComments) {
                            _loadMoreComments();
                          }
                          return _buildModernComment(_comments[index]);
                        },
                        childCount: _comments.length,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 130 + bottomInset),
                ),
              ],
            ),
            _buildModernBottomBar(),
          ],
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
      title: Text(
        'Post Details',
        style: AppTheme.blackTextStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
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

  Widget _buildModernEngagementStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildModernStatItem(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            count: _likeCount,
            label: 'Likes',
            color: Colors.redAccent,
            isActive: _isLiked,
            onTap: _toggleLike,
          ),
          _buildModernStatItem(
            icon: Icons.chat_bubble_outline,
            count: _comments.length,
            label: 'Comments',
            color: AppColors.primary,
            isActive: false,
          ),
          _buildModernStatItem(
            icon: Icons.share_outlined,
            count: 0,
            label: 'Share',
            color: Colors.blueAccent,
            isActive: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatItem({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color.withOpacity(0.15) : Colors.transparent,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive ? color : AppColors.greyColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              count > 999
                  ? '${(count / 1000).toStringAsFixed(1)}K'
                  : count.toString(),
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'COMMENTS',
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

  Widget _buildEmptyComments() {
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.backgroundColor.withOpacity(0.9),
              AppColors.backgroundColor,
            ],
            stops: const [0, 0.3, 0.6],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: [
              _buildAvatar(_post.user.avatar, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (value) => _addComment(value),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _commentController.text.trim().isNotEmpty
                      ? AppColors.primary
                      : AppColors.greyColor.withOpacity(0.2),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: _commentController.text.trim().isNotEmpty
                        ? Colors.white
                        : AppColors.greyColor,
                  ),
                  onPressed: _commentController.text.trim().isNotEmpty
                      ? () => _addComment(_commentController.text)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
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
              _buildOptionTile(Icons.link, 'Copy Link', Colors.black87),
              _buildOptionTile(
                  Icons.share_outlined, 'Share Post', Colors.black87),
              const Divider(height: 1),
              _buildOptionTile(Icons.flag_outlined, 'Report', Colors.redAccent),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(IconData icon, String title, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}
