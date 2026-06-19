import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:flutter/material.dart';

class CreateStatusComposerPanel extends StatelessWidget {
  final TextEditingController textController;
  final TextAlign textAlign;
  final Widget? footer;

  const CreateStatusComposerPanel({
    super.key,
    required this.textController,
    required this.textAlign,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    maxLines: 6,
                    minLines: 5,
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
                      hintText:
                          'Write something short, visual, and worth pausing for...',
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
                      contentPadding: const EdgeInsets.only(top: 4, bottom: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
