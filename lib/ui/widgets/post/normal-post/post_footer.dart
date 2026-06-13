import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/ui/widgets/common/effect_text.dart';
import 'package:flutter/material.dart';

class PostFooter extends StatelessWidget {
  final FeedPost post;
  final bool isTextOnly;
  final int? maxLines;

  const PostFooter({
    super.key,
    required this.post,
    this.isTextOnly = false,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final content = post.content.trim();

    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        isTextOnly ? 4 : 0,
        16,
        12,
      ),
      child: EffectText(
        text: content,
        maxLines: maxLines,
        overflow:
            maxLines == null ? TextOverflow.visible : TextOverflow.ellipsis,
        style: AppTheme.blackTextStyle.copyWith(
          fontSize: isTextOnly ? 16 : 14,
          height: 1.45,
          fontWeight: isTextOnly ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }
}
