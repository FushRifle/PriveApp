import 'package:clique/app/configs/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StoryReplyBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isReplying;
  final ValueChanged<bool> onFocusChanged;
  final ValueChanged<String> onSend;
  final VoidCallback onLike;
  final VoidCallback onReshare;
  final bool isLiked;
  final bool isReshared;

  const StoryReplyBar({
    super.key,
    required this.controller,
    required this.isReplying,
    required this.onFocusChanged,
    required this.onSend,
    required this.onLike,
    required this.onReshare,
    this.isLiked = false,
    this.isReshared = false,
  });

  @override
  State<StoryReplyBar> createState() => _StoryReplyBarState();
}

class _StoryReplyBarState extends State<StoryReplyBar> {
  late final FocusNode _focusNode;

  bool _canSend = false;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode()
      ..addListener(() {
        widget.onFocusChanged(_focusNode.hasFocus);
      });

    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();

    super.dispose();
  }

  void _onTextChanged() {
    final canSend = widget.controller.text.trim().isNotEmpty;

    if (canSend == _canSend) return;
    if (!mounted) return;

    setState(() {
      _canSend = canSend;
    });
  }

  void _send() {
    final value = widget.controller.text.trim();

    if (value.isEmpty) return;

    widget.onSend(value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: widget.isReplying ? 50 : 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color:
                  AppColors.white.withOpacity(widget.isReplying ? 0.20 : 0.14),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.white
                    .withOpacity(widget.isReplying ? 0.42 : 0.28),
              ),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 15,
              ),
              minLines: 1,
              maxLines: 2,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Send message',
                hintStyle: TextStyle(
                  color: AppColors.white.withOpacity(0.65),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundButton(
          icon: widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border,
          backgroundColor: widget.isLiked
              ? AppColors.red.withOpacity(0.78)
              : AppColors.white.withOpacity(0.12),
          borderColor: widget.isLiked
              ? AppColors.red
              : AppColors.white.withOpacity(0.28),
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onLike();
          },
        ),
        const SizedBox(width: 10),
        _RoundButton(
          icon: Icons.repeat_rounded,
          backgroundColor: widget.isReshared
              ? AppColors.primary
              : AppColors.white.withOpacity(0.12),
          borderColor: widget.isReshared
              ? AppColors.primary
              : AppColors.white.withOpacity(0.28),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onReshare();
          },
        ),
        const SizedBox(width: 10),
        _RoundButton(
          icon: Icons.send_rounded,
          backgroundColor:
              _canSend ? AppColors.primary : AppColors.white.withOpacity(0.12),
          borderColor:
              _canSend ? AppColors.primary : AppColors.white.withOpacity(0.28),
          onTap: _canSend
              ? () {
                  HapticFeedback.lightImpact();
                  _send();
                }
              : null,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const _RoundButton({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: CircleBorder(
        side: BorderSide(
          color: borderColor,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: AppColors.white,
            size: 21,
          ),
        ),
      ),
    );
  }
}
