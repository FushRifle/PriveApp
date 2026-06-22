import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class PostReaction {
  final String label;
  final IconData icon;
  final Color color;

  const PostReaction({
    required this.label,
    required this.icon,
    required this.color,
  });
}

final postReactions = [
  const PostReaction(
    label: 'Like',
    icon: Icons.thumb_up_alt_rounded,
    color: AppColors.primary,
  ),
  const PostReaction(
    label: 'Love',
    icon: Icons.favorite_rounded,
    color: AppColors.redAccent,
  ),
  const PostReaction(
    label: 'Care',
    icon: Icons.sentiment_very_satisfied_rounded,
    color: AppColors.orange,
  ),
  const PostReaction(
    label: 'Haha',
    icon: Icons.emoji_emotions_rounded,
    color: AppColors.amber,
  ),
  const PostReaction(
    label: 'Wow',
    icon: Icons.auto_awesome_rounded,
    color: AppColors.secondary,
  ),
  PostReaction(
    label: 'Angry',
    icon: Icons.sentiment_very_dissatisfied_rounded,
    color: AppColors.redColor,
  ),
];

Future<void> showPostReactionPicker(
  BuildContext context, {
  Rect? anchorRect,
  required ValueChanged<PostReaction> onSelected,
}) async {
  final reactions = postReactions;

  HapticFeedback.mediumImpact();

  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (overlay == null) return;

  final overlaySize = overlay.size;
  const pickerWidth = 304.0;
  const pickerHeight = 68.0;
  const gap = 12.0;
  const edgeMargin = 12.0;
  const bottomMargin = 36.0;
  const blurSigma = 18.0;

  final fallbackAnchor = Rect.fromLTWH(
    (overlaySize.width - pickerWidth) / 2,
    overlaySize.height - pickerHeight - bottomMargin,
    pickerWidth,
    pickerHeight,
  );
  final effectiveAnchor = anchorRect ?? fallbackAnchor;

  var left = effectiveAnchor.center.dx - (pickerWidth / 2);
  left = left.clamp(edgeMargin, overlaySize.width - pickerWidth - edgeMargin);

  var top = effectiveAnchor.top - pickerHeight - gap;
  if (top < bottomMargin) {
    top = effectiveAnchor.bottom + gap;
  }
  if (top + pickerHeight > overlaySize.height - bottomMargin) {
    top = overlaySize.height - pickerHeight - bottomMargin;
  }
  top =
      top.clamp(bottomMargin, overlaySize.height - pickerHeight - bottomMargin);

  final selected = await showGeneralDialog<PostReaction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss reactions',
    barrierColor: Colors.black.withOpacity(0.18),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: pickerWidth,
              child: _ReactionStrip(
                reactions: reactions,
                onSelected: (reaction) {
                  Navigator.pop(dialogContext, reaction);
                },
              ),
            ),
          ],
        ),
      );
    },
  );

  if (selected != null) {
    onSelected(selected);
  }
}

class _ReactionStrip extends StatelessWidget {
  final List<PostReaction> reactions;
  final ValueChanged<PostReaction> onSelected;

  const _ReactionStrip({
    required this.reactions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.cardColor.withOpacity(0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: reactions
            .map(
              (reaction) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelected(reaction);
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: reaction.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: reaction.color.withOpacity(0.16),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            reaction.icon,
                            color: reaction.color,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reaction.label,
                            style: AppTheme.blackTextStyle.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
