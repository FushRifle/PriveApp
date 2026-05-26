import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/data/models/feeds_models.dart';

void customBottomSheetComments(BuildContext context, {required int postId}) =>
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (builder) => CommentBottomSheetContent(postId: postId),
    );

class CommentBottomSheetContent extends StatefulWidget {
  final int postId;

  const CommentBottomSheetContent({super.key, required this.postId});

  @override
  State<CommentBottomSheetContent> createState() =>
      _CommentBottomSheetContentState();
}

class _CommentBottomSheetContentState extends State<CommentBottomSheetContent> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  bool _isPosting = false;
  int _currentPage = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadComments() {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    context
        .read<FeedBloc>()
        .add(GetPostComments(postId: widget.postId, page: 1));
  }

  void _loadMoreComments() {
    if (_isLoadingMore || !_hasMore) return;
    if (!mounted) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    context
        .read<FeedBloc>()
        .add(GetPostComments(postId: widget.postId, page: _currentPage));
  }

  void _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    if (!mounted) return;

    setState(() => _isPosting = true);
    context.read<FeedBloc>().add(CreatePostComment(
          postId: widget.postId,
          content: content,
        ));

    // Clear input
    _commentController.clear();
    _focusNode.unfocus();

    // Refresh comments after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _currentPage = 1;
      _loadComments();
      setState(() => _isPosting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FeedBloc, FeedState>(
      listener: (context, state) {
        // Update comments when loaded
        if (state.comments.containsKey(widget.postId)) {
          if (!mounted) return;
          setState(() {
            _comments = state.comments[widget.postId]!;
            _hasMore = state.hasMoreComments[widget.postId] ?? false;
            _isLoading = false;
            _isLoadingMore = false;
            _error = null;
          });
        }

        // Handle errors
        if (state.commentsError != null && _isLoading) {
          if (!mounted) return;
          setState(() {
            _error = state.commentsError;
            _isLoading = false;
          });
        }

        // Handle posting error
        if (state.generalError != null && _isPosting) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.generalError!),
              backgroundColor: Colors.red,
            ),
          );
          if (mounted) {
            setState(() => _isPosting = false);
          }
        }
      },
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 6,
                margin: const EdgeInsets.only(top: 16, bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(top: 30),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Comments",
                              style: AppTheme.blackTextStyle.copyWith(
                                fontSize: 18,
                                fontWeight: AppTheme.bold,
                              ),
                            ),
                            Text(
                              "${_comments.length} comments",
                              style: AppTheme.greyTextStyle.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: _buildCommentsList(),
                      ),
                      _buildCommentInput(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_isLoading && _comments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null && _comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: AppTheme.greyTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadComments(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.greyColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
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

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoadingMore &&
            _hasMore &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadMoreComments();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        itemCount: _comments.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _comments.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          final comment = _comments[index];
          return Column(
            children: [
              _buildCommentCard(
                comment.userAvatar,
                comment.userName,
                comment.content,
                comment.formattedTimeAgo,
                false,
              ),
              if (index < _comments.length - 1)
                Divider(
                  color: AppColors.dashedLineColor.withOpacity(0.3),
                  thickness: 1,
                ),
              const SizedBox(height: 6),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        border: Border(
          top: BorderSide(
            color: AppColors.dashedLineColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: AppTheme.greyTextStyle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isPosting ? null : _submitComment,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(
      String imageUrl, String name, String comment, String time, bool isTemp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 45,
              height: 45,
              child: imageUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.greyColor.withOpacity(0.2),
                          child: const Icon(Icons.person, size: 25),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.greyColor.withOpacity(0.2),
                      child: const Icon(Icons.person, size: 25),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: AppTheme.bold,
                      ),
                    ),
                    if (isTemp) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: isTemp
                      ? AppTheme.greyTextStyle.copyWith(
                          fontSize: 12,
                          fontWeight: AppTheme.medium,
                          fontStyle: FontStyle.italic,
                        )
                      : AppTheme.greyTextStyle.copyWith(
                          fontSize: 12,
                          fontWeight: AppTheme.medium,
                        ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(12, 38),
                        backgroundColor: AppColors.backgroundColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        _commentController.text = '@$name ';
                        _focusNode.requestFocus();
                      },
                      child: Row(
                        children: [
                          Image.asset("assets/images/ic_share.png", width: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Reply",
                            style: AppTheme.blackTextStyle.copyWith(
                              fontSize: 12,
                              fontWeight: AppTheme.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      time,
                      style: AppTheme.greyTextStyle.copyWith(
                        fontSize: 12,
                        fontWeight: AppTheme.medium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset("assets/images/ic_calendar.png", width: 14),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
