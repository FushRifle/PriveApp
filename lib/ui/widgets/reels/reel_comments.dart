import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/services/reel/reel_service.dart';
import 'package:clique/ui/widgets/common/token_suggestion_field.dart';
import 'package:clique/ui/widgets/comments/comment_widgets.dart';
import 'package:clique/ui/widgets/reels/helpers/reel_helpers.dart';
import 'package:clique/ui/widgets/reels/helpers/reel_suggestions.dart';
import 'package:clique/ui/widgets/reels/reel_actions.dart';

class ReelCommentsSheet extends StatefulWidget {
  final String reelId;
  final VoidCallback onCommentAdded;

  const ReelCommentsSheet({
    super.key,
    required this.reelId,
    required this.onCommentAdded,
  });

  @override
  State<ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<ReelCommentsSheet> {
  final ReelService _reelService = ReelService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _comments = const [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final comments = await _reelService.getReelComments(widget.reelId);

      if (!mounted) return;

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final comment = await _reelService.addReelComment(
        reelId: widget.reelId,
        data: {
          'content': text,
          'comment': text,
          'text': text,
        },
      );

      if (!mounted) return;

      _controller.clear();
      widget.onCommentAdded();

      setState(() {
        _comments = [
          if (comment.isNotEmpty) comment else {'content': text},
          ..._comments,
        ];
        _isSending = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.card,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, sheetController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Comments',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildComments(sheetController),
                ),
                _buildCommentInput(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComments(ScrollController controller) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_error != null) {
      return SheetMessage(
        icon: Icons.error_outline,
        title: 'Could not load comments',
        subtitle: _error!,
        actionLabel: 'Retry',
        onAction: _loadComments,
      );
    }

    if (_comments.isEmpty) {
      return const SheetMessage(
        icon: Icons.mode_comment_outlined,
        title: 'No comments yet',
        subtitle: 'Start the conversation.',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadComments,
      child: ListView.separated(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _comments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          return CommentTile(comment: _comments[index]);
        },
      ),
    );
  }

  Widget _buildCommentInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TokenSuggestionField(
                controller: _controller,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (!_isSending) _sendComment();
                },
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
                suggestionsBuilder: suggestReelComposerTokens,
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _isSending ? null : _sendComment,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.divider,
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_upward,
                      color: AppColors.white,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentTile extends StatelessWidget {
  final dynamic comment;

  const CommentTile({
    super.key,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final data = asMap(comment);
    final user = asMap(data['user']);
    final name = data['username']?.toString() ??
        user['username']?.toString() ??
        user['name']?.toString() ??
        'User';
    final avatar =
        data['avatar']?.toString() ?? user['avatar']?.toString() ?? '';
    final text = data['content']?.toString() ??
        data['comment']?.toString() ??
        data['text']?.toString() ??
        '';
    final timeLabel = data['createdAt']?.toString() ??
        data['created_at']?.toString() ??
        data['time']?.toString() ??
        '';
    final likes = readCommentInt(
      data['likes'] ?? data['likesCount'] ?? data['_count']?['likes'],
    );
    final replies = readCommentInt(
      data['replyCount'] ?? data['repliesCount'] ?? data['_count']?['replies'],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommentAvatar(
            imageUrl: avatar,
            fallback: name,
            size: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (timeLabel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                if (likes > 0 || replies > 0) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (likes > 0)
                        MiniStat(
                          icon: Icons.favorite_rounded,
                          label: formatCommentCount(likes),
                        ),
                      if (replies > 0)
                        MiniStat(
                          icon: Icons.reply_rounded,
                          label: formatCommentCount(replies),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}