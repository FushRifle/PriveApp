import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'package:clique/ui/widgets/common/token_suggestion_field.dart';

void customBottomSheetComments(BuildContext context, {required int postId}) =>
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (builder) => BlocProvider<FeedBloc>.value(
        value: context.read<FeedBloc>(),
        child: CommentBottomSheetContent(postId: postId),
      ),
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
  final FeedService _feedService = FeedService();
  final UserService _userService = UserService();

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

  Future<List<ComposerTokenSuggestion>> _suggestCommentTokens(
    ComposerTokenType type,
    String query,
  ) async {
    final normalizedQuery = query.trim().toLowerCase();

    try {
      if (type == ComposerTokenType.mention) {
        if (normalizedQuery.isEmpty) {
          return const [];
        }

        final users = await _userService.searchUsers(
          normalizedQuery,
          limit: 8,
        );

        return users.map((user) {
          final name = (user['name'] ?? user['displayName'] ?? 'User')
              .toString()
              .trim();
          final username = (user['username'] ?? user['handle'] ?? '')
              .toString()
              .trim();
          final bioValue = user['bio']?.toString();
          final subtitle =
              bioValue != null ? bioValue.trim() : '';

          return ComposerTokenSuggestion(
            value: username.isNotEmpty ? username : name.replaceAll(' ', '_'),
            label: username.isNotEmpty ? '@$username' : '@$name',
            subtitle: subtitle.isNotEmpty ? subtitle : null,
          );
        }).where((suggestion) => suggestion.value.isNotEmpty).toList();
      }

      final hashtags = await _feedService.getTrendingHashtags(limit: 12);
      final seen = <String>{};
      final values = <String>[
        ...hashtags.map((item) => item['tag']?.toString().trim() ?? ''),
        'flutter',
        'technology',
        'design',
        'business',
        'community',
        'startup',
        'gaming',
        'music',
      ]
          .where((tag) => tag.isNotEmpty)
          .where((tag) => seen.add(tag.toLowerCase()))
          .toList();

      final filtered = normalizedQuery.isEmpty
          ? values
          : values.where((tag) => tag.toLowerCase().contains(normalizedQuery));

      return filtered
          .map(
            (tag) => ComposerTokenSuggestion(
              value: tag.startsWith('#') ? tag.substring(1) : tag,
              label: '#$tag',
              subtitle: 'Hashtag',
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
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
              backgroundColor: AppColors.red,
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
                comment.id,
                comment.userAvatar,
                comment.userName,
                comment.content,
                comment.formattedTimeAgo,
                comment.likes,
                comment.dislikes,
                comment.replyCount,
                comment.isLiked,
                comment.isDisliked,
                false,
                index == 0,
                index == _comments.length - 1,
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
            child: TokenSuggestionField(
              controller: _commentController,
              focusNode: _focusNode,
              enabled: !_isPosting,
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
              style: AppTheme.blackTextStyle,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
              suggestionsBuilder: _suggestCommentTokens,
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
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: AppColors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(
    int commentId,
    String imageUrl,
    String name,
    String comment,
    String time,
    int likes,
    int dislikes,
    int replyCount,
    bool isLiked,
    bool isDisliked,
    bool isTemp,
    bool isFirst,
    bool isLast,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          Positioned(
            left: 22,
            top: isFirst ? 22 : 0,
            bottom: isLast ? 22 : 0,
            child: Container(
              width: 1.5,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.backgroundColor,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.16),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
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
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.blackTextStyle.copyWith(
                              fontSize: 14,
                              fontWeight: AppTheme.bold,
                            ),
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
                        _CommentActionButton(
                          icon: Icons.thumb_up_outlined,
                          selectedIcon: Icons.thumb_up,
                          selected: isLiked,
                          label: likes > 0 ? '$likes' : 'Like',
                          onTap: () => context.read<FeedBloc>().add(
                                LikePostComment(
                                  postId: widget.postId,
                                  commentId: commentId,
                                ),
                              ),
                        ),
                        const SizedBox(width: 8),
                        _CommentActionButton(
                          icon: Icons.thumb_down_outlined,
                          selectedIcon: Icons.thumb_down,
                          selected: isDisliked,
                          label: dislikes > 0 ? '$dislikes' : 'Dislike',
                          onTap: () => context.read<FeedBloc>().add(
                                DislikePostComment(
                                  postId: widget.postId,
                                  commentId: commentId,
                                ),
                              ),
                        ),
                        const SizedBox(width: 8),
                        _CommentActionButton(
                          icon: Icons.reply_rounded,
                          selectedIcon: Icons.reply_rounded,
                          selected: false,
                          label: replyCount > 0 ? '$replyCount replies' : 'Reply',
                          onTap: () {
                            _commentController.text = '@$name ';
                            _focusNode.requestFocus();
                          },
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
        ],
      ),
    );
  }
}

class _CommentActionButton extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _CommentActionButton({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(12, 38),
        backgroundColor: selected
            ? AppColors.primary.withOpacity(0.12)
            : AppColors.backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected
                ? AppColors.primary.withOpacity(0.2)
                : AppColors.transparent,
          ),
        ),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(selected ? selectedIcon : icon, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.bold,
            ),
          ),
        ],
      ),
    );
  }
}
