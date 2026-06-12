import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/create_post_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreatePostOptionsView extends StatelessWidget {
  final bool isPicking;
  final PostComposerType currentType;
  final ValueChanged<PostComposerType> onTypeSelected;
  final VoidCallback onAnonymousSelected;
  final VoidCallback onQuestionSelected;
  final VoidCallback onPollSelected;
  final VoidCallback onImage;
  final VoidCallback onCamera;
  final VoidCallback onVideo;
  final VoidCallback onAudio;

  const CreatePostOptionsView({
    super.key,
    required this.isPicking,
    required this.currentType,
    required this.onTypeSelected,
    required this.onAnonymousSelected,
    required this.onQuestionSelected,
    required this.onPollSelected,
    required this.onImage,
    required this.onCamera,
    required this.onVideo,
    required this.onAudio,
  });

  @override
  Widget build(BuildContext context) {
    final contentOptions = <_ComposerAction>[
      _ComposerAction(
        type: PostComposerType.post,
        icon: Icons.edit_note_rounded,
        title: 'Post',
        subtitle: 'Start a normal feed post',
        color: AppColors.primary,
        onTap: () => onTypeSelected(PostComposerType.post),
      ),
      _ComposerAction(
        type: PostComposerType.poll,
        icon: Icons.poll_rounded,
        title: 'Poll',
        subtitle: 'Ask a question with multiple answers',
        color: AppColors.orange,
        onTap: onPollSelected,
      ),
      _ComposerAction(
        type: PostComposerType.anonymous,
        icon: Icons.visibility_off_rounded,
        title: 'Anonymous',
        subtitle: 'Post without your name',
        color: AppColors.teal,
        onTap: onAnonymousSelected,
      ),
      _ComposerAction(
        type: PostComposerType.question,
        icon: Icons.question_answer_rounded,
        title: 'Question',
        subtitle: 'Ask the community',
        color: AppColors.secondary,
        onTap: onQuestionSelected,
      ),
    ];

    final mediaActions = <_MediaAction>[
      _MediaAction(
        icon: Icons.photo_library_rounded,
        title: 'Gallery',
        subtitle: 'Pick photos',
        color: AppColors.purple,
        onTap: onImage,
      ),
      _MediaAction(
        icon: Icons.camera_alt_rounded,
        title: 'Camera',
        subtitle: 'Capture now',
        color: AppColors.blue,
        onTap: onCamera,
      ),
      _MediaAction(
        icon: Icons.videocam_rounded,
        title: 'Video',
        subtitle: 'Upload clips',
        color: AppColors.green,
        onTap: onVideo,
      ),
      _MediaAction(
        icon: Icons.music_note_rounded,
        title: 'Audio',
        subtitle: 'Coming soon',
        color: AppColors.teal,
        onTap: onAudio,
      ),
    ];

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          physics: const BouncingScrollPhysics(),
          children: [
            _HeroPanel(currentType: currentType),
            const SizedBox(height: 18),
            _SectionLabel(
              title: 'Choose content type',
              subtitle: 'Pick the kind of post you want to create.',
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contentOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.12,
              ),
              itemBuilder: (context, index) {
                final action = contentOptions[index];
                return _ComposerTypeCard(
                  action: action,
                  selected: currentType == action.type,
                );
              },
            ),
            const SizedBox(height: 18),
            _SectionLabel(
              title: 'Media',
              subtitle: 'Attach visual content if you want more reach.',
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mediaActions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, index) {
                return _MediaActionCard(action: mediaActions[index]);
              },
            ),
          ],
        ),
        if (isPicking)
          Positioned.fill(
            child: Container(
              color: AppColors.black.withOpacity(0.42),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final PostComposerType currentType;

  const _HeroPanel({
    required this.currentType,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (currentType) {
      PostComposerType.post => 'Standard post',
      PostComposerType.poll => 'Poll mode',
      PostComposerType.question => 'Question mode',
      PostComposerType.anonymous => 'Anonymous mode',
    };

    final subtitle = switch (currentType) {
      PostComposerType.post => 'A clean post for text, media, or both.',
      PostComposerType.poll => 'Create a poll and publish it to the feed.',
      PostComposerType.question =>
        'Keep it direct and let replies do the rest.',
      PostComposerType.anonymous => 'Your name stays hidden from the feed.',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.secondary.withOpacity(0.10),
            AppColors.cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowElevated,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.greyTextStyle.copyWith(
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTheme.greyTextStyle.copyWith(
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _ComposerTypeCard extends StatelessWidget {
  final _ComposerAction action;
  final bool selected;

  const _ComposerTypeCard({
    required this.action,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? action.color.withOpacity(0.38) : AppColors.cardBorderColor;

    return Material(
      color: selected ? action.color.withOpacity(0.10) : AppColors.cardColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: action.color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      action.icon,
                      color: action.color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                action.title,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaActionCard extends StatelessWidget {
  final _MediaAction action;

  const _MediaActionCard({
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      action.title,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerAction {
  final PostComposerType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ComposerAction({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _MediaAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MediaAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
