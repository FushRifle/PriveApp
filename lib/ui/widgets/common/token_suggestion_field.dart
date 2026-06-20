import 'dart:async';

import 'package:flutter/material.dart';

import 'package:clique/app/configs/colors.dart';

enum ComposerTokenType {
  mention,
  hashtag,
}

class ComposerTokenSuggestion {
  final String value;
  final String label;
  final String? subtitle;

  const ComposerTokenSuggestion({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

typedef ComposerTokenSuggestionsBuilder = Future<List<ComposerTokenSuggestion>>
    Function(ComposerTokenType type, String query);

class HighlightTokenTextEditingController extends TextEditingController {
  HighlightTokenTextEditingController({super.text});

  static final RegExp _tokenPattern = RegExp(r'([#@][A-Za-z0-9_]+)');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final children = <TextSpan>[];
    var lastIndex = 0;

    for (final match in _tokenPattern.allMatches(text)) {
      if (match.start > lastIndex) {
        children.add(
          TextSpan(text: text.substring(lastIndex, match.start), style: style),
        );
      }

      children.add(
        TextSpan(
          text: match.group(0),
          style: style?.copyWith(color: AppColors.primary) ??
              TextStyle(color: AppColors.primary),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      children.add(TextSpan(text: text.substring(lastIndex), style: style));
    }

    return TextSpan(style: style, children: children);
  }
}

class TokenSuggestionField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration decoration;
  final TextStyle style;
  final TextStyle? suggestionTitleStyle;
  final TextStyle? suggestionSubtitleStyle;
  final TextAlign textAlign;
  final int? maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;
  final ComposerTokenSuggestionsBuilder suggestionsBuilder;
  final List<ComposerTokenType> supportedTokenTypes;
  final double suggestionMaxHeight;

  const TokenSuggestionField({
    super.key,
    required this.controller,
    required this.decoration,
    required this.style,
    required this.suggestionsBuilder,
    this.focusNode,
    this.suggestionTitleStyle,
    this.suggestionSubtitleStyle,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.minLines,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.supportedTokenTypes = const [
      ComposerTokenType.mention,
      ComposerTokenType.hashtag,
    ],
    this.suggestionMaxHeight = 220,
  });

  @override
  State<TokenSuggestionField> createState() => _TokenSuggestionFieldState();
}

class _TokenSuggestionFieldState extends State<TokenSuggestionField> {
  final List<ComposerTokenSuggestion> _suggestions = [];
  Timer? _debounceTimer;
  ComposerTokenType? _activeType;
  String _activeQuery = '';
  int _tokenStart = -1;
  int _tokenEnd = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    widget.focusNode?.addListener(_handleFocusChanged);
    _handleTextChanged();
  }

  @override
  void didUpdateWidget(covariant TokenSuggestionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    widget.focusNode?.removeListener(_handleFocusChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (widget.focusNode != null && !widget.focusNode!.hasFocus) {
      _clearSuggestions();
    }
  }

  void _handleTextChanged() {
    if (!widget.enabled) {
      _clearSuggestions();
      return;
    }

    final selection = widget.controller.selection;
    if (!selection.isValid || selection.start < 0) {
      _clearSuggestions();
      return;
    }

    final text = widget.controller.text;
    final cursor = selection.start.clamp(0, text.length);
    final beforeCursor = text.substring(0, cursor);

    final match =
        RegExp(r'(^|\s)([@#])([A-Za-z0-9_]*)$').firstMatch(beforeCursor);
    if (match == null) {
      _clearSuggestions();
      return;
    }

    final token = match.group(2);
    final query = match.group(3) ?? '';
    final type =
        token == '@' ? ComposerTokenType.mention : ComposerTokenType.hashtag;

    if (!widget.supportedTokenTypes.contains(type)) {
      _clearSuggestions();
      return;
    }

    _activeType = type;
    _activeQuery = query;
    _tokenEnd = cursor;
    _tokenStart = beforeCursor.length - query.length - 1;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: 240),
      () async {
        final currentType = _activeType;
        if (currentType == null || !mounted) return;

        final suggestions =
            await widget.suggestionsBuilder(currentType, _activeQuery);

        if (!mounted) return;
        if (widget.controller.text
                .substring(0, widget.controller.selection.start)
                .isEmpty &&
            suggestions.isEmpty) {
          return;
        }

        setState(() {
          _suggestions
            ..clear()
            ..addAll(suggestions);
        });
      },
    );
  }

  void _clearSuggestions() {
    _debounceTimer?.cancel();
    if (_suggestions.isEmpty && _activeType == null) return;
    setState(() {
      _suggestions.clear();
      _activeType = null;
      _activeQuery = '';
      _tokenStart = -1;
      _tokenEnd = -1;
    });
  }

  void _insertSuggestion(ComposerTokenSuggestion suggestion) {
    final type = _activeType;
    if (type == null) return;

    final prefix = type == ComposerTokenType.mention ? '@' : '#';
    final replacement = '$prefix${suggestion.value} ';
    final text = widget.controller.text;

    final start = _tokenStart >= 0 ? _tokenStart : 0;
    final end = _tokenEnd >= 0 ? _tokenEnd : widget.controller.selection.start;
    final safeStart = start.clamp(0, text.length);
    final safeEnd = end.clamp(safeStart, text.length);

    final updatedText = text.replaceRange(safeStart, safeEnd, replacement);
    widget.controller.value = TextEditingValue(
      text: updatedText,
      selection:
          TextSelection.collapsed(offset: safeStart + replacement.length),
    );

    _clearSuggestions();
    FocusScope.of(context).requestFocus(widget.focusNode);
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = widget.suggestionTitleStyle ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            );
    final subtitleStyle = widget.suggestionSubtitleStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted,
          autofocus: widget.autofocus,
          decoration: widget.decoration,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 10),
            constraints: BoxConstraints(maxHeight: widget.suggestionMaxHeight),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.white10,
              ),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return ListTile(
                  dense: true,
                  onTap: () => _insertSuggestion(item),
                  title: Text(
                    item.label,
                    style: titleStyle,
                  ),
                  subtitle: item.subtitle == null
                      ? null
                      : Text(
                          item.subtitle!,
                          style: subtitleStyle,
                        ),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white12,
                    child: Icon(
                      _activeType == ComposerTokenType.mention
                          ? Icons.alternate_email_rounded
                          : Icons.tag_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
