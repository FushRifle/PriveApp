import 'package:clique/app/configs/colors.dart';
import 'package:flutter/material.dart';

class StyleControls extends StatelessWidget {
  final double fontSize;
  final int textLength;
  final Color selectedColor;
  final List<Color> backgroundColors;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onFontSizeChangeEnd;
  final ValueChanged<Color> onColorSelected;

  const StyleControls({
    super.key,
    required this.fontSize,
    required this.textLength,
    required this.selectedColor,
    required this.backgroundColors,
    required this.onFontSizeChanged,
    required this.onFontSizeChangeEnd,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Font size',
              style: TextStyle(
                color: AppColors.text.withOpacity(0.82),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              fontSize.round().toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Slider(
          value: fontSize.clamp(18, 42).toDouble(),
          min: 20,
          max: 42,
          divisions: 12,
          activeColor: AppColors.primary,
          inactiveColor: Colors.white.withOpacity(0.18),
          onChanged: onFontSizeChanged,
          onChangeEnd: (_) => onFontSizeChangeEnd(),
        ),
        const SizedBox(height: 32),
        Text(
          'Background color',
          style: TextStyle(
            color: AppColors.text.withOpacity(0.82),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
          children: backgroundColors.map((color) {
            final isSelected = color.value == selectedColor.value;

            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
