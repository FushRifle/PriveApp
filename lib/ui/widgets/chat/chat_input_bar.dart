import 'dart:async';
import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(bool) onTyping;
  final MessageModel? replyingTo;
  final VoidCallback onCancelReply;
  final Color sendButtonColor;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onPickDocument;

  const ChatInputBar({
    super.key,
    required this.onSendMessage,
    required this.onTyping,
    this.replyingTo,
    required this.onCancelReply,
    required this.sendButtonColor,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onPickDocument,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _typingTimer;

  // Track if there's text for real-time updates
  bool _hasText = false;

  static const Duration _typingDebounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateTextStatus);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateTextStatus);
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _updateTextStatus() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      if (!mounted) return;
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }

    if (!_focusNode.hasFocus) {
      _typingTimer?.cancel();
      widget.onTyping(false);
    }
  }

  void _handleTyping(String text) {
    _typingTimer?.cancel();

    if (text.isNotEmpty) {
      widget.onTyping(true);
    }

    _typingTimer = Timer(_typingDebounceDuration, () {
      widget.onTyping(false);
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendMessage(text);
    _controller.clear();
    _focusNode.requestFocus();

    _typingTimer?.cancel();
    widget.onTyping(false);
  }

  void _showAttachmentMenu() {
    _focusNode.unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.greyColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                    Icons.image, 'Gallery', const Color(0xFF8B5CF6), () {
                  Navigator.pop(context);
                  widget.onPickImage();
                }),
                _buildAttachmentOption(
                    Icons.camera_alt, 'Camera', const Color(0xFF06B6D4), () {
                  Navigator.pop(context);
                  widget.onPickImage();
                }),
                _buildAttachmentOption(
                    Icons.videocam, 'Video', const Color(0xFF10B981), () {
                  Navigator.pop(context);
                  widget.onPickVideo();
                }),
                _buildAttachmentOption(
                    Icons.folder, 'Document', const Color(0xFFF59E0B), () {
                  Navigator.pop(context);
                  widget.onPickDocument();
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (widget.replyingTo == null) return const SizedBox.shrink();

    final replyTo = widget.replyingTo!;
    final isReplyingToSelf = replyTo.isOwn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: widget.sendButtonColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.reply, size: 12, color: widget.sendButtonColor),
                    const SizedBox(width: 6),
                    Text(
                      isReplyingToSelf ? 'Replying to yourself' : 'Replying',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.sendButtonColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  replyTo.message,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: widget.onCancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _hasText;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildReplyPreview(),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Attachment Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showAttachmentMenu,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Text Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: _focusNode.hasFocus
                            ? [
                                BoxShadow(
                                  color:
                                      widget.sendButtonColor.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: AppTheme.blackTextStyle.copyWith(fontSize: 15),
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 1,
                        maxLines: 5,
                        onChanged: _handleTyping,
                        decoration: InputDecoration(
                          hintText: 'Message',
                          hintStyle:
                              AppTheme.greyTextStyle.copyWith(fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Button - Modern sophisticated design
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isActive ? _handleSend : null,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      widget.sendButtonColor,
                                      widget.sendButtonColor.withOpacity(0.8),
                                    ],
                                  )
                                : null,
                            color: isActive ? null : Colors.grey.shade200,
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: widget.sendButtonColor
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color:
                                isActive ? Colors.white : Colors.grey.shade400,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
