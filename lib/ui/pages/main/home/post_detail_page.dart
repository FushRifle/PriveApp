import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/models/post_model.dart';
import 'package:Prive/ui/widgets/home/card_post.dart';

class PostDetailPage extends StatefulWidget {
  final dynamic post;

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

  final List<Map<String, dynamic>> _comments = [];

  late PostModel _post;
  bool _isLiked = false;
  bool _isSaved = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _post = _parsePost(widget.post);
    _isLiked = _post.isLiked;
    _likeCount = _post.likeCount;
    _isSaved = _post.isSaved;
    _loadSampleComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  PostModel _parsePost(dynamic value) {
    if (value is PostModel) return value;

    if (value is Map<String, dynamic>) {
      return PostModel.fromJson(value);
    }

    if (value is Map) {
      return PostModel.fromJson(Map<String, dynamic>.from(value));
    }

    return PostModel(
      name: 'User',
      imgProfile: '',
      picture: '',
      caption: '',
      createdAt: DateTime.now(),
    );
  }

  void _loadSampleComments() {
    _comments.addAll([
      {
        'name': 'Sarah Johnson',
        'avatar': 'https://randomuser.me/api/portraits/women/1.jpg',
        'comment': 'Absolutely stunning! 🔥',
        'time': '30m ago',
        'likes': 24,
        'isLiked': false,
      },
      {
        'name': 'Michael Chen',
        'avatar': 'https://randomuser.me/api/portraits/men/2.jpg',
        'comment': 'This is so inspiring. Keep up the great work! 👏',
        'time': '1h ago',
        'likes': 12,
        'isLiked': false,
      },
    ]);
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  void _toggleSave() {
    setState(() {
      _isSaved = !_isSaved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSaved ? 'Saved to collection' : 'Removed from saved'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
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
              if (_comments.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyComments(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildModernComment(_comments[index], index);
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
            icon: _isSaved ? Icons.bookmark : Icons.bookmark_outline,
            count: 0,
            label: 'Save',
            color: AppColors.secondary,
            isActive: _isSaved,
            onTap: _toggleSave,
          ),
          _buildModernStatItem(
            icon: Icons.share_outlined,
            count: _post.shareCount,
            label: 'Shares',
            color: Colors.blueAccent,
            isActive: false,
            onTap: _onShare,
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
          Row(
            children: [
              const SizedBox(width: 8),
              Text(
                'COMMENTS',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontSize: 13,
                  color: AppColors.blackTextColor,
                ),
              ),
            ],
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

  Widget _buildModernComment(Map<String, dynamic> comment, int index) {
    final isLiked = comment['isLiked'] ?? false;
    final likes = comment['likes'] ?? 0;

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
          _buildAvatar(comment['avatar'] ?? '', size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment['name'] ?? 'User',
                        style: AppTheme.blackTextStyle.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      comment['time'] ?? '',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment['comment'] ?? '',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildCommentAction(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      label: likes > 0 ? '$likes' : 'Like',
                      isActive: isLiked,
                      onTap: () {
                        setState(() {
                          _comments[index]['isLiked'] = !isLiked;
                          _comments[index]['likes'] =
                              isLiked ? likes - 1 : likes + 1;
                        });
                      },
                    ),
                    const SizedBox(width: 24),
                    _buildCommentAction(
                      icon: Icons.reply,
                      label: 'Reply',
                      onTap: () {
                        _commentController.text = '@${comment['name']} ';
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentAction({
    required IconData icon,
    required String label,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? Colors.redAccent : AppColors.greyColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.redAccent : AppColors.greyColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
              _buildAvatar(_post.imgProfile, size: 40),
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

  void _addComment(String text) {
    final value = text.trim();
    if (value.isEmpty) return;

    HapticFeedback.lightImpact();

    setState(() {
      _comments.insert(0, {
        'name': 'You',
        'avatar': _post.imgProfile,
        'comment': value,
        'time': 'Just now',
        'likes': 0,
        'isLiked': false,
      });

      _commentController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment added!'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.primary,
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
              _buildOptionTile(
                  Icons.bookmark_border, 'Save Post', Colors.black87),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title tapped'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
