import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditPostPage extends StatefulWidget {
  final int postId;
  final int ownerId;
  final String initialContent;
  final DateTime createdAt;

  const EditPostPage({
    super.key,
    required this.postId,
    required this.ownerId,
    required this.initialContent,
    required this.createdAt,
  });

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;
  bool _didRequestSave = false;

  bool get _canEdit =>
      DateTime.now().difference(widget.createdAt) <= const Duration(hours: 2);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    if (!_canEdit) {
      _showSnack(
        'You can only edit a post within 2 hours of posting.',
        isError: true,
      );
      return;
    }

    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _didRequestSave = true;
    });

    context.read<FeedBloc>().add(
          UpdateFeedPost(
            postId: widget.postId,
            ownerId: widget.ownerId,
            content: content,
            createdAt: widget.createdAt,
          ),
        );
  }

  void _showSnack(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.card,
      ),
    );
  }

  void _handleStateChange(BuildContext context, FeedState state) {
    if (!_didRequestSave) return;

    if (state.isUpdatingPost) return;

    _didRequestSave = false;

    final error = state.generalError;
    if (error != null && error.isNotEmpty) {
      setState(() => _isSubmitting = false);
      _showSnack(error, isError: true);
      context.read<FeedBloc>().add(ClearFeedError());
      return;
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);
    _showSnack('Post updated');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _canEdit;
    final draftText = _controller.text.trim();
    final remaining = widget.createdAt
            .add(const Duration(hours: 2))
            .difference(DateTime.now())
            .isNegative
        ? Duration.zero
        : widget.createdAt.add(const Duration(hours: 2)).difference(
              DateTime.now(),
            );

    return BlocConsumer<FeedBloc, FeedState>(
      listenWhen: (previous, current) =>
          previous.isUpdatingPost != current.isUpdatingPost ||
          previous.generalError != current.generalError,
      listener: _handleStateChange,
      builder: (context, state) {
        final isSaving = _isSubmitting || state.isUpdatingPost;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text('Edit post'),
            actions: [
              TextButton(
                onPressed: canEdit && !isSaving ? _save : null,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  AppColors.primary.withOpacity(0.04),
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _TopSummaryCard(
                    canEdit: canEdit,
                    remaining: remaining,
                  ),
                  const SizedBox(height: 14),
                  _PostPreviewCard(
                    content:
                        draftText.isEmpty ? widget.initialContent : draftText,
                    createdAt: widget.createdAt,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.cardBorderColor),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Edit content',
                              style: AppTheme.blackTextStyle.copyWith(
                                fontSize: 16,
                                fontWeight: AppTheme.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_controller.text.trim().length} chars',
                              style: AppTheme.greyTextStyle.copyWith(
                                fontSize: 12,
                                fontWeight: AppTheme.medium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: TextField(
                            controller: _controller,
                            autofocus: canEdit,
                            enabled: canEdit,
                            readOnly: !canEdit,
                            minLines: 8,
                            maxLines: 12,
                            textInputAction: TextInputAction.newline,
                            style: AppTheme.blackTextStyle.copyWith(
                              fontSize: 16,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: canEdit
                                  ? 'Refine your post copy...'
                                  : 'Editing window has closed.',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          canEdit
                              ? 'You can edit this post until the 2-hour window closes.'
                              : 'This post can no longer be edited.',
                          style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: canEdit && !isSaving ? _save : null,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      canEdit
                          ? (isSaving ? 'Saving...' : 'Save changes')
                          : 'Editing closed',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopSummaryCard extends StatelessWidget {
  final bool canEdit;
  final Duration remaining;

  const _TopSummaryCard({
    required this.canEdit,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final remainingLabel =
        canEdit ? _formatRemaining(remaining) : 'Editing closed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardColor,
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: (canEdit ? AppColors.primary : AppColors.redColor)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              canEdit ? Icons.edit_outlined : Icons.lock_outline,
              color: canEdit ? AppColors.primary : AppColors.redColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canEdit ? 'Editing is open' : 'Editing is closed',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: AppTheme.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  canEdit
                      ? 'You have a 2 hour window from the original post time.'
                      : 'Posts can only be edited within 2 hours of posting.',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 10),
                _InfoPill(
                  icon: canEdit ? Icons.timer_outlined : Icons.block_outlined,
                  label: remainingLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostPreviewCard extends StatelessWidget {
  final String content;
  final DateTime createdAt;

  const _PostPreviewCard({
    required this.content,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original post',
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: AppTheme.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(createdAt),
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content.isEmpty ? 'No content provided.' : content,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.medium,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRemaining(Duration duration) {
  if (duration <= Duration.zero) return '0 minutes left';

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours > 0 && minutes > 0) {
    return '$hours h $minutes m left';
  }
  if (hours > 0) {
    return '$hours h left';
  }
  return '$minutes m left';
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${months[local.month - 1]} ${local.day}, ${local.year} • $hour:$minute $period';
}
