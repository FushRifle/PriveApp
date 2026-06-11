import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/status/stories_bloc.dart';
import 'package:clique/core/models/status_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditStatusPage extends StatefulWidget {
  final Story story;

  const EditStatusPage({
    super.key,
    required this.story,
  });

  @override
  State<EditStatusPage> createState() => _EditStatusPageState();
}

class _EditStatusPageState extends State<EditStatusPage> {
  late final TextEditingController _controller;
  late Color _selectedColor;
  late TextAlign _textAlign;
  late double _fontSize;
  bool _isSubmitting = false;

  static const List<Color> _backgroundColors = [
    AppColors.storyTextBackground,
    AppColors.storyPurple,
    AppColors.storyRed,
    AppColors.storyDeepPurple,
    AppColors.storyTeal,
    AppColors.storyMuted,
    AppColors.primary,
    AppColors.secondary,
    AppColors.storyYellow,
    AppColors.storyGreen,
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.story.content ?? '');
    _selectedColor = _readStoryColor(widget.story.backgroundColor);
    _textAlign = _readTextAlign(widget.story.textAlign);
    _fontSize = widget.story.fontSize ?? 28;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    context.read<StoriesBloc>().add(
          UpdateStoryEvent(
            storyId: widget.story.id,
            content: content,
            backgroundColor: _colorToHex(_selectedColor),
            textAlign: _textAlign.name,
            fontSize: _fontSize,
          ),
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Status updated'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
    Navigator.pop(context, true);
  }

  Color _readStoryColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return AppColors.storyTextBackground;
    }

    try {
      var colorStr = hexColor.trim();
      if (colorStr.startsWith('#')) {
        colorStr = colorStr.substring(1);
      }
      if (colorStr.startsWith('0x')) {
        colorStr = colorStr.substring(2);
      }
      if (colorStr.length == 6) {
        return Color(int.parse('FF$colorStr', radix: 16));
      }
      if (colorStr.length == 8) {
        return Color(int.parse(colorStr, radix: 16));
      }
    } catch (_) {}

    return AppColors.storyTextBackground;
  }

  TextAlign _readTextAlign(String? textAlign) {
    switch (textAlign?.toLowerCase()) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  String _colorToHex(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: const Text('Edit Status'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _save,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: AppColors.white),
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: _selectedColor),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.black.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.12),
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          expands: true,
                          textAlign: _textAlign,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: _fontSize,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Update your status...',
                            hintStyle: TextStyle(color: AppColors.white70),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAlignmentRow(),
                  const SizedBox(height: 12),
                  _buildFontSlider(),
                  const SizedBox(height: 12),
                  _buildBackgroundPalette(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignmentRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _PillButton(
          label: 'Left',
          selected: _textAlign == TextAlign.left,
          onTap: () => setState(() => _textAlign = TextAlign.left),
        ),
        _PillButton(
          label: 'Center',
          selected: _textAlign == TextAlign.center,
          onTap: () => setState(() => _textAlign = TextAlign.center),
        ),
        _PillButton(
          label: 'Right',
          selected: _textAlign == TextAlign.right,
          onTap: () => setState(() => _textAlign = TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildFontSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font size',
          style: TextStyle(color: AppColors.white.withOpacity(0.85)),
        ),
        Slider(
          value: _fontSize.clamp(18, 38).toDouble(),
          min: 18,
          max: 38,
          divisions: 10,
          activeColor: AppColors.white,
          inactiveColor: AppColors.white.withOpacity(0.25),
          onChanged: (value) => setState(() => _fontSize = value),
        ),
      ],
    );
  }

  Widget _buildBackgroundPalette() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _backgroundColors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final color = _backgroundColors[index];
          final selected = color.value == _selectedColor.value;
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 58 : 50,
              height: selected ? 58 : 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.white : AppColors.white24,
                  width: selected ? 3 : 1.4,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.white.withOpacity(0.18)
              : AppColors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.white.withOpacity(0.55)
                : AppColors.white.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
