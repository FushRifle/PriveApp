import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:flutter/material.dart';

import 'create_status_composer_tools.dart';

class CreateStatusComposerPanel extends StatelessWidget {
  final TextEditingController textController;
  final TextAlign textAlign;
  final VoidCallback onAddMedia;
  final VoidCallback onAddHashtags;
  final VoidCallback onClearAll;
  final ValueChanged<TextAlign> onTextAlignChanged;
  final Widget? footer;

  const CreateStatusComposerPanel({
    super.key,
    required this.textController,
    required this.textAlign,
    required this.onAddMedia,
    required this.onAddHashtags,
    required this.onClearAll,
    required this.onTextAlignChanged,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                maxLines: 7,
                minLines: 6,
                cursorColor: AppColors.primary,
                textAlign: textAlign,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                style: AppTheme.blackTextStyle.copyWith(
                  color: AppColors.text,
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'Write something short, visual, and worth pausing for...',
                  hintStyle: AppTheme.greyTextStyle.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.65),
                    fontSize: 15,
                    height: 1.4,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.only(top: 12, bottom: 12),
                ),
              ),
            ),
            const SizedBox(width: 14),
            CreateStatusComposerTools(
              onAddMedia: onAddMedia,
              onAddHashtags: onAddHashtags,
              onClearAll: onClearAll,
              onTextAlignChanged: onTextAlignChanged,
              activeAlignment: textAlign,
            ),
          ],
        ),
      ],
    );
  }
}
