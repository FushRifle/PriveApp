import 'dart:async';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/models/poll_model.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PollPostBody extends StatefulWidget {
  final FeedPost post;
  final bool isDetailView;

  const PollPostBody({
    super.key,
    required this.post,
    required this.isDetailView,
  });

  @override
  State<PollPostBody> createState() => _PollPostBodyState();
}

class _PollPostBodyState extends State<PollPostBody> {
  final FeedService _feedService = FeedService();
  final Set<int> _selectedOptionIds = <int>{};
  Timer? _autoSubmitTimer;

  FeedPoll? _poll;
  bool _isLoading = true;
  bool _isVoting = false;
  String? _error;

  bool get _canVote => _poll != null && !_poll!.userVoted && !_poll!.hasExpired;

  @override
  void initState() {
    super.initState();
    _loadPoll();
  }

  @override
  void didUpdateWidget(covariant PollPostBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _loadPoll();
    }
  }

  @override
  void dispose() {
    _autoSubmitTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPoll({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final poll = await _feedService.getPostPoll(
        widget.post.id,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _poll = poll;
        _selectedOptionIds
          ..clear()
          ..addAll(_initialSelection(poll));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Iterable<int> _initialSelection(FeedPoll? poll) {
    if (poll == null) return const [];
    final voteId = poll.userVoteOptionId;
    if (voteId != null) return [voteId];
    return const [];
  }

  void _toggleOption(FeedPollOption option) {
    if (!_canVote || _isVoting) return;

    HapticFeedback.selectionClick();

    setState(() {
      if (_poll?.isMultipleChoice == true) {
        if (_selectedOptionIds.contains(option.id)) {
          _selectedOptionIds.remove(option.id);
        } else {
          _selectedOptionIds.add(option.id);
        }
      } else {
        _selectedOptionIds
          ..clear()
          ..add(option.id);
      }
    });

    _scheduleAutoSubmit();
  }

  void _scheduleAutoSubmit() {
    _autoSubmitTimer?.cancel();
    _autoSubmitTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || !_canVote || _selectedOptionIds.isEmpty) return;
      _submitVote();
    });
  }

  Future<void> _submitVote() async {
    final poll = _poll;
    if (poll == null || !_canVote || _selectedOptionIds.isEmpty) {
      return;
    }

    setState(() {
      _isVoting = true;
    });

    try {
      await _feedService.votePoll(
        postId: widget.post.id,
        pollId: poll.id,
        optionIds: _selectedOptionIds.toList(),
      );
      await _loadPoll(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _poll?.question.trim().isNotEmpty == true
        ? _poll!.question.trim()
        : widget.post.content.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(widget.isDetailView ? 18 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.card.withOpacity(0.92),
              AppColors.cardColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorderColor),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : _buildPollContent(question),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      key: const ValueKey('poll_loading'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopRow(isLoading: true),
        const SizedBox(height: 14),
        _skeletonLine(widthFactor: 0.76),
        const SizedBox(height: 10),
        _skeletonLine(widthFactor: 0.92),
        const SizedBox(height: 18),
        _skeletonOption(),
        const SizedBox(height: 10),
        _skeletonOption(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      key: const ValueKey('poll_error'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopRow(),
        const SizedBox(height: 14),
        Text(
          'Poll failed to load.',
          style: AppTheme.blackTextStyle.copyWith(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _error ?? '',
          style: AppTheme.greyTextStyle.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: () => _loadPoll(forceRefresh: true),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildPollContent(String question) {
    final poll = _poll;
    if (poll == null) {
      return _buildErrorState();
    }

    final showResults = poll.userVoted || poll.hasExpired;

    return Column(
      key: const ValueKey('poll_content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopRow(),
        const SizedBox(height: 14),
        Text(
          question.isEmpty ? 'Poll question' : question,
          style: AppTheme.blackTextStyle.copyWith(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        if (poll.options.isNotEmpty)
          Column(
            children: poll.options
                .map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildOptionTile(
                      option,
                      showResults: showResults,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildTopRow({bool isLoading = false}) {
    final poll = _poll;
    final expiryLabel = poll == null
        ? null
        : poll.hasExpired
            ? 'Ended'
            : _formatExpiry(poll.expiresAt);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.primary.withOpacity(0.12),
          ),
          child: Icon(
            Icons.poll_rounded,
            color: AppColors.text,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Poll',
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (poll?.isMultipleChoice == true)
              Text(
                'Multiple choice',
                style: AppTheme.greyTextStyle.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const Spacer(),
        if (!isLoading && expiryLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: poll != null && poll.hasExpired
                  ? AppColors.redAccent.withOpacity(0.1)
                  : AppColors.text.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              expiryLabel,
              style: AppTheme.greyTextStyle.copyWith(
                color: poll != null && poll.hasExpired
                    ? AppColors.redAccent
                    : AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionTile(
    FeedPollOption option, {
    required bool showResults,
  }) {
    final poll = _poll;
    final selected = _selectedOptionIds.contains(option.id) ||
        (poll?.userVoteOptionId == option.id);
    final fill = showResults ? (option.percentage / 100).clamp(0.0, 1.0) : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: showResults ? null : () => _toggleOption(option),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.08)
                : AppColors.cardColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withOpacity(0.35)
                  : AppColors.cardBorderColor,
            ),
          ),
          child: Stack(
            children: [
              if (showResults)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: fill,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.16),
                                AppColors.cardBorder.withOpacity(0.12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.primary
                          : AppColors.transparent,
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.text.isEmpty ? 'Option' : option.text,
                          style: AppTheme.blackTextStyle.copyWith(
                            color: AppColors.text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (showResults) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${option.votes} votes',
                                style: AppTheme.greyTextStyle.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${option.percentage.toStringAsFixed(1)}%',
                                style: AppTheme.greyTextStyle.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonLine({required double widthFactor}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _skeletonOption() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
    );
  }

  String _formatExpiry(DateTime? expiresAt) {
    if (expiresAt == null) {
      return 'No expiry';
    }

    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'Ended';
    }

    final totalHours = remaining.inHours;
    if (totalHours >= 24) {
      final days = totalHours ~/ 24;
      return days == 1 ? '1 day left' : '$days days left';
    }

    final hours = totalHours <= 0 ? 1 : totalHours;
    return hours == 1 ? '1 hour left' : '$hours hours left';
  }
}
