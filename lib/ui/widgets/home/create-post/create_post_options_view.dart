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
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final action = contentOptions[index];
                return _ComposerTypeCard(
                  action: action,
                  selected: currentType == action.type,
                );
              },
            ),
            const SizedBox(height: 20),
            _SectionLabel(
              title: 'Media tools',
              subtitle: 'Attach photos, clips, or audio to make the post stand out.',
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
                childAspectRatio: 1.28,
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
              color: AppColors.black.withOpacity(0.46),
              child: Center(
                child: Container(
                  width: 170,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading media tools',
                        textAlign: TextAlign.center,
                        style: AppTheme.blackTextStyle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
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
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardColor,
            AppColors.primary.withOpacity(0.06),
            AppColors.secondary.withOpacity(0.04),
          ],
        ),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.16),
                  AppColors.secondary.withOpacity(0.12),
                ],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.secondary,
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
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.greyTextStyle.copyWith(
                    fontSize: 13,
                    height: 1.4,
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [
                      action.color.withOpacity(0.16),
                      AppColors.cardColor,
                    ]
                  : [
                      AppColors.cardColor,
                      AppColors.cardColor.withOpacity(0.96),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? action.color.withOpacity(0.10)
                    : AppColors.black.withOpacity(0.04),
                blurRadius: selected ? 18 : 12,
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: action.color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
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
                      color: action.color,
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
                  height: 1.35,
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorderColor),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardColor,
                action.color.withOpacity(0.06),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
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
