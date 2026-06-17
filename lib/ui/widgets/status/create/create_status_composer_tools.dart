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
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _ToolButton(
            icon: Icons.photo_library_outlined,
            label: 'Media',
            onTap: onAddMedia,
          ),
          const SizedBox(height: 10),
          _ToolButton(
            icon: Icons.tag_rounded,
            label: 'Tags',
            onTap: onAddHashtags,
          ),
          const SizedBox(height: 10),
          _ToolButton(
            icon: Icons.clear_all_rounded,
            label: 'Clear',
            onTap: onClearAll,
            destructive: true,
          ),
          const SizedBox(height: 14),
          _AlignStack(
            activeAlignment: activeAlignment,
            onChanged: onTextAlignChanged,
          ),
        ],
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
    final color = destructive ? AppColors.text : AppColors.primary;
    return Material(
      color: AppColors.backgroundColor.withOpacity(0.7),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 12,
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

class _AlignStack extends StatelessWidget {
  final TextAlign activeAlignment;
  final ValueChanged<TextAlign> onChanged;

  const _AlignStack({
    required this.activeAlignment,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _AlignButton(
            icon: Icons.format_align_left_rounded,
            active: activeAlignment == TextAlign.left,
            onTap: () => onChanged(TextAlign.left),
          ),
          const SizedBox(height: 6),
          _AlignButton(
            icon: Icons.format_align_center_rounded,
            active: activeAlignment == TextAlign.center,
            onTap: () => onChanged(TextAlign.center),
          ),
          const SizedBox(height: 6),
          _AlignButton(
            icon: Icons.format_align_right_rounded,
            active: activeAlignment == TextAlign.right,
            onTap: () => onChanged(TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _AlignButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _AlignButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: active ? AppColors.primary.withOpacity(0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 36,
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
