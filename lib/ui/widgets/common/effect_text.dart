import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/ui/pages/main/home/hashtag_feed_page.dart';

class EffectText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int? maxLines;
  final TextAlign textAlign;
  final TextOverflow overflow;
  final Color? hashtagColor;
  final Color? mentionColor;
  final List<Shadow>? effectShadows;

  const EffectText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.visible,
    this.hashtagColor,
    this.mentionColor,
    this.effectShadows,
  });

  static final RegExp _effectPattern = RegExp(
    r'(?<![A-Za-z0-9_])([#@][A-Za-z0-9_]+)',
  );

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _effectPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      final token = match.group(1)!;
      final isHashtag = token.startsWith('#');
      final tokenStyle = style.copyWith(
        color: isHashtag
            ? hashtagColor ?? AppColors.primary
            : mentionColor ?? AppColors.secondary,
        fontWeight: FontWeight.w800,
        shadows: effectShadows,
      );

      if (isHashtag) {
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
                    builder: (_) => HashtagFeedPage(tag: token),
                  ),
                );
              },
              child: Text(token, style: tokenStyle),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: token, style: tokenStyle));
      }

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return RichText(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(
        style: style,
        children: spans,
      ),
    );
  }
}
