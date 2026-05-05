import 'package:flutter/material.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/hooks/home/comment_hook.dart';

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
  late CommentsHook _commentsHook;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _commentsHook = CommentsHook(postId: widget.postId);
    _commentsHook.fetchComments();
  }

  @override
  void dispose() {
    _commentsHook.dispose();
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final success =
        await _commentsHook.addComment(_commentController.text.trim());
    if (success) {
      _commentController.clear();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 30),
              decoration: const BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.vertical(
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
                          "${_commentsHook.comments.length} comments",
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
    );
  }

  Widget _buildCommentsList() {
    if (_commentsHook.loading && _commentsHook.comments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.purpleColor),
      );
    }

    if (_commentsHook.error != null && _commentsHook.comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _commentsHook.error!,
              style: AppTheme.greyTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _commentsHook.fetchComments(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleColor,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_commentsHook.comments.isEmpty) {
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
        if (!_commentsHook.loadingMore &&
            _commentsHook.hasMore &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _commentsHook.loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        itemCount:
            _commentsHook.comments.length + (_commentsHook.loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _commentsHook.comments.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.purpleColor),
              ),
            );
          }
          final comment = _commentsHook.comments[index];
          return Column(
            children: [
              _buildCommentCard(
                comment['user']?['avatar'] ?? '',
                comment['user']?['name'] ?? 'User',
                comment['content'] ?? '',
                _formatTime(comment['createdAt']),
                comment['isTemp'] == true,
              ),
              if (index < _commentsHook.comments.length - 1)
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
            onTap: _commentsHook.posting ? null : _submitComment,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.purpleColor,
                shape: BoxShape.circle,
              ),
              child: _commentsHook.posting
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
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
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
                          color: AppColors.purpleColor,
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
                        // Reply to specific comment
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

  String _formatTime(String? isoString) {
    if (isoString == null) return 'Just now';

    final DateTime time = DateTime.parse(isoString);
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
