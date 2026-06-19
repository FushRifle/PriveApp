import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:flutter/material.dart';

class CreateStatusComposerTools extends StatelessWidget {
  final VoidCallback onAddMedia;
  final VoidCallback onAddHashtags;
  final VoidCallback onClearAll;
  final ValueChanged<TextAlign> onTextAlignChanged;
  final TextAlign activeAlignment;

  const CreateStatusComposerTools({
    super.key,
    required this.onAddMedia,
    required this.onAddHashtags,
    required this.onClearAll,
    required this.onTextAlignChanged,
    required this.activeAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.14,
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
        _ToolButton(
          icon: Icons.clear_all_rounded,
          label: 'Clear',
          onTap: onClearAll,
          destructive: true,
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
      ],
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
    final color = destructive ? AppColors.text : AppColors.primary;
    return Material(
      color: AppColors.backgroundColor.withOpacity(0.7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
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

    return Material(
      color: AppColors.backgroundColor.withOpacity(0.7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
