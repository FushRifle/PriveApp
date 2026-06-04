import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/ui/pages/main/home/hashtag_feed_page.dart';
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
      child: _HashtagText(
        text: content,
        maxLines: maxLines,
        baseStyle: AppTheme.blackTextStyle.copyWith(
          fontSize: isTextOnly ? 16 : 14,
          height: 1.45,
          fontWeight: isTextOnly ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _HashtagText extends StatelessWidget {
  final String text;
  final int? maxLines;
  final TextStyle baseStyle;

  const _HashtagText({
    required this.text,
    required this.maxLines,
    required this.baseStyle,
  });

  static final RegExp _hashtagPattern = RegExp(r'#[A-Za-z0-9_]+');

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _hashtagPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      final tag = match.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HashtagFeedPage(tag: tag),
                ),
              );
            },
            child: Text(
              tag,
              style: baseStyle.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return RichText(
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.visible : TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }
}
