import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/clients/cloudinary_service.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'package:clique/ui/widgets/comments/comment_widgets.dart';
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
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final UserService _userService = UserService();
  final RecorderController _recorderController = RecorderController();
  StreamSubscription<Duration>? _recordingDurationSubscription;

  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  bool _isPosting = false;
  bool _isRecordingVoice = false;
  bool _isStartingVoiceRecording = false;
  Duration _voiceDuration = Duration.zero;
  String? _voicePath;
  int _currentPage = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recordingDurationSubscription =
        _recorderController.onCurrentDuration.listen((duration) {
      if (!mounted) return;
      setState(() => _voiceDuration = duration);
    });
    _loadComments();
  }

  @override
  void dispose() {
    _recordingDurationSubscription?.cancel();
    if (_isRecordingVoice) {
      _recorderController.stop();
    }
    _recorderController.dispose();
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

  Future<void> _startVoiceRecording() async {
    if (_isRecordingVoice || _isStartingVoiceRecording) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isStartingVoiceRecording = true;
      _voiceDuration = Duration.zero;
    });

    try {
      final hasPermission = await _recorderController.checkPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission is required');
      }

      final file = File(
        '${Directory.systemTemp.path}/Prive_comment_${DateTime.now().microsecondsSinceEpoch}.m4a',
      );

      _voicePath = file.path;
      await _recorderController.record(path: file.path);

      if (!mounted) return;

      setState(() {
        _isRecordingVoice = true;
        _isStartingVoiceRecording = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isRecordingVoice = false;
        _isStartingVoiceRecording = false;
        _voicePath = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.card,
        ),
      );
    }
  }

  Future<void> _cancelVoiceRecording() async {
    final path = _voicePath;

    if (_isRecordingVoice) {
      await _recorderController.stop();
    }
    _recorderController.reset();

    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (!mounted) return;

    setState(() {
      _isRecordingVoice = false;
      _isStartingVoiceRecording = false;
      _voiceDuration = Duration.zero;
      _voicePath = null;
    });
  }

  Future<void> _finishVoiceRecording() async {
    if (!_isRecordingVoice) return;

    final fallbackPath = _voicePath;
    final recordedDuration = _voiceDuration;
    final path = await _recorderController.stop();
    _recorderController.reset();

    if (!mounted) return;

    setState(() {
      _isRecordingVoice = false;
      _isStartingVoiceRecording = false;
      _voiceDuration = Duration.zero;
      _voicePath = null;
      _isPosting = true;
    });

    final resolvedPath = path ?? fallbackPath;
    if (resolvedPath == null) {
      if (mounted) {
        setState(() => _isPosting = false);
      }
      return;
    }

    final file = File(resolvedPath);
    if (!await file.exists()) {
      if (mounted) {
        setState(() => _isPosting = false);
      }
      return;
    }

    if (recordedDuration < const Duration(seconds: 1)) {
      await file.delete();
      if (!mounted) return;
      setState(() => _isPosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice note is too short')),
      );
      return;
    }

    try {
      final audioUrl = await _cloudinaryService.uploadAudio(
        file,
        customFolder: 'audio',
      );
      if (!mounted) return;

      context.read<FeedBloc>().add(
            CreatePostComment(
              postId: widget.postId,
              content: '',
              audioUrl: audioUrl,
              duration: recordedDuration.inSeconds,
            ),
          );

      _commentController.clear();
      _focusNode.unfocus();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send voice note: $error'),
          backgroundColor: AppColors.card,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
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

        return users
            .map((user) {
              final name = (user['name'] ?? user['displayName'] ?? 'User')
                  .toString()
                  .trim();
              final username =
                  (user['username'] ?? user['handle'] ?? '').toString().trim();
              final bioValue = user['bio']?.toString();
              final subtitle = bioValue != null ? bioValue.trim() : '';

              return ComposerTokenSuggestion(
                value:
                    username.isNotEmpty ? username : name.replaceAll(' ', '_'),
                label: username.isNotEmpty ? '@$username' : '@$name',
                subtitle: subtitle.isNotEmpty ? subtitle : null,
              );
            })
            .where((suggestion) => suggestion.value.isNotEmpty)
            .toList();
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
    if (content.isEmpty || _isPosting || _isRecordingVoice) return;

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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
              backgroundColor: AppColors.card,
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
          height: MediaQuery.of(context).size.height * 0.88,
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
    final threads = groupCommentsIntoThreads(_comments);

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
        itemCount: threads.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == threads.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          return CommentThreadCard(
            thread: threads[index],
            isFirst: index == 0,
            isLast: index == threads.length - 1,
            onLike: (comment) => context.read<FeedBloc>().add(
                  LikePostComment(
                    postId: widget.postId,
                    commentId: comment.id,
                  ),
                ),
            onDislike: (comment) => context.read<FeedBloc>().add(
                  DislikePostComment(
                    postId: widget.postId,
                    commentId: comment.id,
                  ),
                ),
            onReply: (comment) {
              _commentController.text = '@${comment.userName} ';
              _focusNode.requestFocus();
            },
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecordingVoice)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.red.withOpacity(0.16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: AppColors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recording voice note ${_formatDuration(_voiceDuration)}',
                      style: AppTheme.greyTextStyle.copyWith(
                        color: AppColors.red,
                        fontWeight: AppTheme.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _cancelVoiceRecording,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TokenSuggestionField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  enabled: !_isPosting && !_isRecordingVoice,
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
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isPosting
                    ? null
                    : (_isRecordingVoice
                        ? _finishVoiceRecording
                        : _startVoiceRecording),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isRecordingVoice
                        ? AppColors.red
                        : AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: _isStartingVoiceRecording
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Icon(
                          _isRecordingVoice ? Icons.stop : Icons.mic,
                          color: _isRecordingVoice
                              ? AppColors.white
                              : AppColors.primary,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 10),
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
        ],
      ),
    );
  }
}
