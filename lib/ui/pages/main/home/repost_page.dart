import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/core/models/feeds_models.dart';

class RepostPage extends StatefulWidget {
  final FeedPost post;

  const RepostPage({
    super.key,
    required this.post,
  });

  @override
  State<RepostPage> createState() => _RepostPageState();
}

class _RepostPageState extends State<RepostPage> {
  final TextEditingController _captionController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _submitted = true;
    });

    context.read<FeedBloc>().add(
          RepostFeedPost(
            postId: widget.post.id,
            content: _captionController.text.trim(),
            postType: widget.post.postType,
            isAnonymous: widget.post.isAnonymous,
            anonymousCategory: widget.post.anonymousCategory,
            pollOptions: widget.post.pollOptions.isNotEmpty
                ? widget.post.pollOptions
                : null,
            pollExpirationHours: widget.post.pollExpirationHours,
          ),
        );
  }

  void _handleStateChange(BuildContext context, FeedState state) {
    if (!_submitted) return;

    final error = state.generalError;
    if (error != null && error.isNotEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.card,
        ),
      );
      context.read<FeedBloc>().add(ClearFeedError());
      _submitted = false;
      return;
    }

    if (!state.isReposting && _isSubmitting) {
      setState(() => _isSubmitting = false);
      _submitted = false;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.post;

    return BlocConsumer<FeedBloc, FeedState>(
      listenWhen: (previous, current) {
        return previous.generalError != current.generalError ||
            previous.isReposting != current.isReposting;
      },
      listener: _handleStateChange,
      builder: (context, state) {
        final isBusy = _isSubmitting || state.isReposting;
        final hasPreferences =
            source.isPoll || source.isQuestion || source.isAnonymousPost;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text('Repost'),
            actions: [
              TextButton(
                onPressed: isBusy ? null : _submit,
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Post'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SectionCard(
                title: 'Your caption',
                subtitle: 'Add context before you share it again',
                child: TextField(
                  controller: _captionController,
                  minLines: 4,
                  maxLines: 8,
                  textInputAction: TextInputAction.newline,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 15,
                    height: 1.45,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Say something about this post...',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Source post',
                subtitle: hasPreferences
                    ? 'This repost keeps the original post type and preferences.'
                    : 'This repost keeps the original post type.',
                child: _SourcePostPreview(post: source),
              ),
              const SizedBox(height: 14),
              _PreferenceSummary(post: source),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: isBusy ? null : _submit,
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.repeat_rounded),
                label: Text(isBusy ? 'Reposting...' : 'Repost now'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            title,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 16,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTheme.greyTextStyle.copyWith(fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PreferenceSummary extends StatelessWidget {
  final FeedPost post;

  const _PreferenceSummary({
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      _Chip(label: post.contentTypeLabel),
      if (post.isAnonymousPost && post.anonymousCategory != null)
        _Chip(
            label: post.anonymousCategory!.trim().isEmpty
                ? 'Anonymous'
                : post.anonymousCategory!.trim()),
      if (post.isPoll && post.pollOptions.isNotEmpty)
        _Chip(label: '${post.pollOptions.length} poll options'),
      if (post.pollExpirationHours != null)
        _Chip(label: 'Expires in ${post.pollExpirationHours}h'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges,
    );
  }
}

class _SourcePostPreview extends StatelessWidget {
  final FeedPost post;

  const _SourcePostPreview({
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final previewText = post.content.trim().isNotEmpty
        ? post.content.trim()
        : post.pollQuestion?.trim().isNotEmpty == true
            ? post.pollQuestion!.trim()
            : post.contentTypeLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.user.name,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 14,
              fontWeight: AppTheme.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            previewText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: post.contentTypeLabel),
              if (post.isAnonymousPost) const _Chip(label: 'Anonymous'),
              if (post.isPoll)
                _Chip(label: '${post.pollOptions.length} poll options'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
      ),
      child: Text(
        label,
        style: AppTheme.blackTextStyle.copyWith(
          fontSize: 11,
          fontWeight: AppTheme.bold,
        ),
      ),
    );
  }
}
