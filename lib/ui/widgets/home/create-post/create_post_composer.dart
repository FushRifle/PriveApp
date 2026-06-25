part of '../../../pages/main/home/create_post_page.dart';

class _TextPostComposer extends StatelessWidget {
  final PostComposerType postType;
  final String anonymousCategory;
  final TextEditingController textController;
  final TextEditingController hashtagController;
  final List<TextEditingController> pollOptionControllers;
  final List<String> hashtags;
  final bool enabled;
  final ValueChanged<PostComposerType> onPostTypeChanged;
  final ValueChanged<String> onAnonymousCategoryChanged;
  final ValueChanged<String> onAddHashtag;
  final ValueChanged<String> onRemoveHashtag;
  final int pollExpirationHours;
  final ValueChanged<int> onPollExpirationHoursChanged;
  final VoidCallback onAddPollOption;
  final ValueChanged<int> onRemovePollOption;
  final ComposerTokenSuggestionsBuilder suggestionsBuilder;

  const _TextPostComposer({
    super.key,
    required this.postType,
    required this.anonymousCategory,
    required this.textController,
    required this.hashtagController,
    required this.pollOptionControllers,
    required this.hashtags,
    required this.enabled,
    required this.onPostTypeChanged,
    required this.onAnonymousCategoryChanged,
    required this.onAddHashtag,
    required this.onRemoveHashtag,
    required this.pollExpirationHours,
    required this.onPollExpirationHoursChanged,
    required this.onAddPollOption,
    required this.onRemovePollOption,
    required this.suggestionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompactWidth = size.width < 390;
    final textBoxHeight = (size.height * 0.28).clamp(170.0, 260.0);
    final horizontalPadding = isCompactWidth ? 14.0 : 16.0;
    final titleFontSize = isCompactWidth ? 17.0 : 18.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        4,
        horizontalPadding,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        children: [
          _ComposerTypeSelector(
            selectedType: postType,
            anonymousCategory: anonymousCategory,
            enabled: enabled,
            onChanged: onPostTypeChanged,
            onAnonymousCategoryChanged: onAnonymousCategoryChanged,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: textBoxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 8),
                  child: Text(
                    _composerTitle(postType),
                    style: AppTheme.blackTextStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _composerAccent(postType),
                    ),
                  ),
                ),
                Expanded(
                  child: TokenSuggestionField(
                    controller: textController,
                    enabled: enabled,
                    suggestionsBuilder: suggestionsBuilder,
                    maxLines: null,
                    style: AppTheme.blackTextStyle.copyWith(
                      fontSize: titleFontSize,
                      height: 1.42,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: _composerHint(postType),
                      hintStyle: AppTheme.greyTextStyle.copyWith(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary.withOpacity(0.55),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (postType == PostComposerType.poll) ...[
            const SizedBox(height: 14),
            _PollComposerPanel(
              enabled: enabled,
              optionControllers: pollOptionControllers,
              expirationHours: pollExpirationHours,
              onExpirationHoursChanged: onPollExpirationHoursChanged,
              onAddOption: onAddPollOption,
              onRemoveOption: onRemovePollOption,
            ),
          ],
          if (postType == PostComposerType.question) ...[
            const SizedBox(height: 14),
            _QuestionPromptPanel(
              enabled: enabled,
            ),
          ],
          const SizedBox(height: 8),
          _HashtagInput(
            controller: hashtagController,
            hashtags: hashtags,
            enabled: enabled,
            compact: false,
            onAddHashtag: onAddHashtag,
            onRemoveHashtag: onRemoveHashtag,
            suggestionsBuilder: suggestionsBuilder,
          ),
        ],
      ),
    );
  }
}

class _MediaPostComposer extends StatelessWidget {
  final PostComposerType postType;
  final String anonymousCategory;
  final List<MediaItem> mediaItems;
  final TextEditingController textController;
  final TextEditingController hashtagController;
  final List<TextEditingController> pollOptionControllers;
  final List<String> hashtags;
  final bool enabled;
  final ValueChanged<PostComposerType> onPostTypeChanged;
  final ValueChanged<String> onAnonymousCategoryChanged;
  final ValueChanged<String> onAddHashtag;
  final ValueChanged<String> onRemoveHashtag;
  final VoidCallback onChangeMedia;
  final int pollExpirationHours;
  final ValueChanged<int> onPollExpirationHoursChanged;
  final VoidCallback onAddPollOption;
  final ValueChanged<int> onRemovePollOption;
  final ComposerTokenSuggestionsBuilder suggestionsBuilder;

  const _MediaPostComposer({
    super.key,
    required this.postType,
    required this.anonymousCategory,
    required this.mediaItems,
    required this.textController,
    required this.hashtagController,
    required this.pollOptionControllers,
    required this.hashtags,
    required this.enabled,
    required this.onPostTypeChanged,
    required this.onAnonymousCategoryChanged,
    required this.onAddHashtag,
    required this.onRemoveHashtag,
    required this.onChangeMedia,
    required this.pollExpirationHours,
    required this.onPollExpirationHoursChanged,
    required this.onAddPollOption,
    required this.onRemovePollOption,
    required this.suggestionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ComposerTypeSelector(
            selectedType: postType,
            anonymousCategory: anonymousCategory,
            enabled: enabled,
            onChanged: onPostTypeChanged,
            onAnonymousCategoryChanged: onAnonymousCategoryChanged,
          ),
          const SizedBox(height: 10),
          _MediaPreview(
            mediaItems: mediaItems,
            onChangeMedia: onChangeMedia,
          ),
          const SizedBox(height: 10),
          _CaptionInput(
            controller: textController,
            enabled: enabled,
            suggestionsBuilder: suggestionsBuilder,
          ),
          if (postType == PostComposerType.poll) ...[
            const SizedBox(height: 14),
            _PollComposerPanel(
              enabled: enabled,
              optionControllers: pollOptionControllers,
              expirationHours: pollExpirationHours,
              onExpirationHoursChanged: onPollExpirationHoursChanged,
              onAddOption: onAddPollOption,
              onRemoveOption: onRemovePollOption,
            ),
          ],
          if (postType == PostComposerType.question) ...[
            const SizedBox(height: 14),
            _QuestionPromptPanel(
              enabled: enabled,
            ),
          ],
          const SizedBox(height: 8),
          _HashtagInput(
            controller: hashtagController,
            hashtags: hashtags,
            enabled: enabled,
            compact: true,
            onAddHashtag: onAddHashtag,
            onRemoveHashtag: onRemoveHashtag,
            suggestionsBuilder: suggestionsBuilder,
          ),
        ],
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final List<MediaItem> mediaItems;
  final VoidCallback onChangeMedia;

  const _MediaPreview({
    required this.mediaItems,
    required this.onChangeMedia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 460,
        minHeight: 260,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.cardBorderColor,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildPreviewContent(),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: AppColors.black.withOpacity(0.58),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onChangeMedia,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.white,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (mediaItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final media = mediaItems.first;

    if (mediaItems.length > 1 &&
        mediaItems.every((item) => item.type == MediaType.image)) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mediaItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          final item = mediaItems[index];

          if (kIsWeb && item.fileBytes != null) {
            return Image.memory(item.fileBytes!, fit: BoxFit.cover);
          }

          if (item.file != null) {
            return Image.file(item.file!, fit: BoxFit.cover);
          }

          return const SizedBox.shrink();
        },
      );
    }

    if (media.type == MediaType.image) {
      if (kIsWeb && media.fileBytes != null) {
        return Image.memory(
          media.fileBytes!,
          fit: BoxFit.contain,
        );
      }

      if (media.file != null) {
        return Image.file(
          media.file!,
          fit: BoxFit.contain,
        );
      }
    }

    if (media.type == MediaType.video) {
      return _LargeFilePreview(
        icon: Icons.play_circle_fill_rounded,
        title: media.fileName ?? 'Selected video',
        subtitle: 'Video will be uploaded with your post',
      );
    }

    return const SizedBox.shrink();
  }
}

class _LargeFilePreview extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LargeFilePreview({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 76,
              ),
              const SizedBox(height: 18),
              Text(
                title.split('/').last,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptionInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ComposerTokenSuggestionsBuilder suggestionsBuilder;

  const _CaptionInput({
    required this.controller,
    required this.enabled,
    required this.suggestionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.short_text_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Caption',
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TokenSuggestionField(
            controller: controller,
            enabled: enabled,
            suggestionsBuilder: suggestionsBuilder,
            maxLines: 4,
            minLines: 2,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 15,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText: 'Write a caption...',
              hintStyle: AppTheme.greyTextStyle.copyWith(
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _HashtagInput extends StatelessWidget {
  final TextEditingController controller;
  final List<String> hashtags;
  final bool enabled;
  final bool compact;
  final ValueChanged<String> onAddHashtag;
  final ValueChanged<String> onRemoveHashtag;
  final ComposerTokenSuggestionsBuilder suggestionsBuilder;

  const _HashtagInput({
    required this.controller,
    required this.hashtags,
    required this.enabled,
    required this.compact,
    required this.onAddHashtag,
    required this.onRemoveHashtag,
    required this.suggestionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TokenSuggestionField(
          controller: controller,
          enabled: enabled,
          suggestionsBuilder: suggestionsBuilder,
          supportedTokenTypes: const [ComposerTokenType.hashtag],
          textInputAction: TextInputAction.done,
          onSubmitted: onAddHashtag,
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 15,
          ),
          textAlign: TextAlign.start,
          decoration: InputDecoration(
            hintText: 'Add hashtags',
            hintStyle: AppTheme.greyTextStyle.copyWith(
              fontSize: 14,
            ),
            border: InputBorder.none,
            prefixIcon: const Icon(
              Icons.tag_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: AppColors.cardColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.cardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        if (hashtags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hashtags.map((tag) {
                return _HashtagChip(
                  tag: tag,
                  onRemove: () => onRemoveHashtag(tag),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;

  const _HashtagChip({
    required this.tag,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerTypeSelector extends StatelessWidget {
  final PostComposerType selectedType;
  final String anonymousCategory;
  final bool enabled;
  final ValueChanged<PostComposerType> onChanged;
  final ValueChanged<String> onAnonymousCategoryChanged;

  const _ComposerTypeSelector({
    required this.selectedType,
    required this.anonymousCategory,
    required this.enabled,
    required this.onChanged,
    required this.onAnonymousCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PostComposerType.values.map((type) {
            final isSelected = type == selectedType;
            return ChoiceChip(
              label: Text(type.label),
              selected: isSelected,
              onSelected: enabled
                  ? (_) {
                      HapticFeedback.selectionClick();
                      onChanged(type);
                    }
                  : null,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.text,
                fontWeight: FontWeight.w700,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.cardColor,
              side: BorderSide(
                color: AppColors.cardBorderColor,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }).toList(),
        ),
        if (selectedType == PostComposerType.anonymous) ...[
          const SizedBox(height: 14),
          Text(
            'Anonymous Category',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _anonymousCategories.map((category) {
              final isSelected =
                  category.toLowerCase() == anonymousCategory.toLowerCase();
              return _AnonymousCategoryChip(
                label: category,
                selected: isSelected,
                enabled: enabled,
                onSelected: () =>
                    onAnonymousCategoryChanged(category.toLowerCase()),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  static const List<String> _anonymousCategories = [
    'Confession',
    'Advice',
    'Relationship',
    'Rant',
    'Question',
  ];
}

class _AnonymousCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  const _AnonymousCategoryChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? (_) => onSelected() : null,
      backgroundColor: AppColors.cardColor,
      selectedColor: AppColors.primary.withOpacity(0.16),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.text,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: AppColors.cardBorderColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _QuestionPromptPanel extends StatelessWidget {
  final bool enabled;

  const _QuestionPromptPanel({
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderColor),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardColor,
            AppColors.secondary.withOpacity(0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.question_mark_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              enabled
                  ? 'Write a sharp question and let the feed handle the discussion.'
                  : 'Question cards are being prepared.',
              style: AppTheme.greyTextStyle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollComposerPanel extends StatelessWidget {
  final bool enabled;
  final List<TextEditingController> optionControllers;
  final int expirationHours;
  final ValueChanged<int> onExpirationHoursChanged;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;

  const _PollComposerPanel({
    required this.enabled,
    required this.optionControllers,
    required this.expirationHours,
    required this.onExpirationHoursChanged,
    required this.onAddOption,
    required this.onRemoveOption,
  });

  @override
  Widget build(BuildContext context) {
    final durations = [12, 24, 48, 72];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Poll Options',
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: enabled ? onAddOption : null,
                icon: const Icon(Icons.add),
                label: const Text('Add option'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Polls are active and will appear in the feed as soon as you post them.',
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expires in $expirationHours hours',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...optionControllers.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PollOptionField(
                  controller: controller,
                  enabled: enabled,
                  index: index + 1,
                  canRemove: optionControllers.length > 2,
                  onRemove: () => onRemoveOption(index),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Expiration',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: durations.map((hours) {
              final selected = hours == expirationHours;
              return ChoiceChip(
                label: Text('${hours}h'),
                selected: selected,
                onSelected:
                    enabled ? (_) => onExpirationHoursChanged(hours) : null,
                selectedColor: AppColors.primary.withOpacity(0.16),
                backgroundColor: AppColors.backgroundColor,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: selected
                      ? AppColors.primary.withOpacity(0.26)
                      : AppColors.cardBorderColor,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PollOptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  const _PollOptionField({
    required this.controller,
    required this.enabled,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Option $index',
              hintStyle: AppTheme.greyTextStyle.copyWith(
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.cardBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.cardBorderColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (canRemove) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: enabled ? onRemove : null,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ],
    );
  }
}

String _composerTitle(PostComposerType type) {
  return switch (type) {
    PostComposerType.post => 'Write your post',
    PostComposerType.poll => 'Build your poll',
    PostComposerType.question => 'Ask the feed',
    PostComposerType.anonymous => 'Anonymous draft',
  };
}

String _composerHint(PostComposerType type) {
  return switch (type) {
    PostComposerType.post => 'What are you thinking about?',
    PostComposerType.poll => 'Write the question people should vote on...',
    PostComposerType.question => 'Ask something worth answering...',
    PostComposerType.anonymous => 'Say what you need to say...',
  };
}

Color _composerAccent(PostComposerType type) {
  return switch (type) {
    PostComposerType.post => AppColors.primary,
    PostComposerType.poll => AppColors.orange,
    PostComposerType.question => AppColors.secondary,
    PostComposerType.anonymous => AppColors.teal,
  };
}
