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
  final VoidCallback onReels;
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
    required this.onReels,
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
        icon: Icons.movie_rounded,
        title: 'Reels',
        subtitle: 'Open the reel studio',
        color: AppColors.primary,
        onTap: onReels,
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          physics: const BouncingScrollPhysics(),
          children: [
            _HeroPanel(currentType: currentType),
            const SizedBox(height: 24),
            _SectionLabel(
              title: 'Choose content type',
              subtitle: 'Pick the kind of post you want to create.',
            ),
            const SizedBox(height: 16),
            ...contentOptions.map((action) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ComposerTypeTile(
                    action: action,
                    selected: currentType == action.type,
                  ),
                )),
            const SizedBox(height: 24),
            _SectionLabel(
              title: 'Media tools',
              subtitle:
                  'Attach photos, clips, or audio to make the post stand out.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: mediaActions
                  .map(
                    (action) => SizedBox(
                      width: (MediaQuery.of(context).size.width - 50) / 2,
                      child: _MediaActionCard(action: action),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        if (isPicking)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading media tools',
                        textAlign: TextAlign.center,
                        style: AppTheme.blackTextStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
    final config = switch (currentType) {
      PostComposerType.post => (
          title: 'Standard post',
          subtitle: 'A clean post for text, media, or both.',
          icon: Icons.article_rounded,
          accent: AppColors.primary,
        ),
      PostComposerType.poll => (
          title: 'Poll mode',
          subtitle: 'Create a poll and publish it to the feed.',
          icon: Icons.how_to_vote_rounded,
          accent: AppColors.orange,
        ),
      PostComposerType.question => (
          title: 'Question mode',
          subtitle: 'Keep it direct and let replies do the rest.',
          icon: Icons.live_help_rounded,
          accent: AppColors.secondary,
        ),
      PostComposerType.anonymous => (
          title: 'Anonymous mode',
          subtitle: 'Your name stays hidden from the feed.',
          icon: Icons.visibility_off_rounded,
          accent: AppColors.teal,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: config.accent.withOpacity(0.04),
        border: Border.all(
          color: config.accent.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: config.accent.withOpacity(0.1),
                  border: Border.all(
                    color: config.accent.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  config.icon,
                  color: config.accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.title,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      config.subtitle,
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
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComposerTypeTile extends StatelessWidget {
  final _ComposerAction action;
  final bool selected;

  const _ComposerTypeTile({
    required this.action,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: action.color.withOpacity(0.1),
        highlightColor: action.color.withOpacity(0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color:
                selected ? action.color.withOpacity(0.06) : AppColors.cardColor,
            border: Border.all(
              color: selected
                  ? action.color.withOpacity(0.3)
                  : AppColors.cardBorderColor.withOpacity(0.5),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: action.color.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.subtitle,
                      style: AppTheme.greyTextStyle.copyWith(
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: action.color,
                    boxShadow: [
                      BoxShadow(
                        color: action.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(18),
        splashColor: action.color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.cardColor,
            border: Border.all(
              color: AppColors.cardBorderColor.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: action.color.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      action.title,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      style: AppTheme.greyTextStyle.copyWith(
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
