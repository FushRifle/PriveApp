import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:flutter/material.dart';

class CreateStatusComposerTools extends StatelessWidget {
  final VoidCallback onAddMedia;
  final VoidCallback onAddHashtags;
  final VoidCallback onClearAll;
  final VoidCallback onOpenStyle;
  final ValueChanged<TextAlign> onTextAlignChanged;
  final TextAlign activeAlignment;

  const CreateStatusComposerTools({
    super.key,
    required this.onAddMedia,
    required this.onAddHashtags,
    required this.onClearAll,
    required this.onOpenStyle,
    required this.onTextAlignChanged,
    required this.activeAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF181A25).withOpacity(0.94),
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      child: Container(
        width: 58,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolButton(
              icon: Icons.photo_library_outlined,
              label: 'Media',
              onTap: onAddMedia,
            ),
            _ToolButton(
              icon: Icons.tag_rounded,
              label: 'Tags',
              onTap: onAddHashtags,
            ),
            _AlignCycleButton(
              activeAlignment: activeAlignment,
              onTap: () {
                final next = switch (activeAlignment) {
                  TextAlign.left => TextAlign.center,
                  TextAlign.center => TextAlign.right,
                  _ => TextAlign.left,
                };
                onTextAlignChanged(next);
              },
            ),
            _ToolButton(
              icon: Icons.format_size_rounded,
              label: 'Style',
              onTap: onOpenStyle,
            ),
            _ToolButton(
              icon: Icons.clear_all_rounded,
              label: 'Clear',
              onTap: onClearAll,
              destructive: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.redColor : AppColors.white;
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlignCycleButton extends StatelessWidget {
  final TextAlign activeAlignment;
  final VoidCallback onTap;

  const _AlignCycleButton({
    required this.activeAlignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (activeAlignment) {
      TextAlign.left => 'Left',
      TextAlign.center => 'Center',
      TextAlign.right => 'Right',
      _ => 'Align',
    };
    final icon = switch (activeAlignment) {
      TextAlign.left => Icons.format_align_left_rounded,
      TextAlign.center => Icons.format_align_center_rounded,
      TextAlign.right => Icons.format_align_right_rounded,
      _ => Icons.format_align_center_rounded,
    };

    return Tooltip(
      message: 'Text alignment: $label',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.white),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
