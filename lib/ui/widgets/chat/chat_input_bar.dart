import 'dart:async';
import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final Function(bool) onTyping;
  final MessageModel? replyingTo;
  final VoidCallback onCancelReply;
  final Color sendButtonColor;
  final VoidCallback onPickImage;
  final VoidCallback onPickCamera;
  final VoidCallback onPickVideo;
  final VoidCallback onPickDocument;
  final ValueChanged<File> onSendVoice;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.onTyping,
    this.replyingTo,
    required this.onCancelReply,
    required this.sendButtonColor,
    required this.onPickImage,
    required this.onPickCamera,
    required this.onPickVideo,
    required this.onPickDocument,
    required this.onSendVoice,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final FocusNode _focusNode = FocusNode();
  final RecorderController _recorderController = RecorderController();
  Timer? _typingTimer;
  StreamSubscription<Duration>? _recordingDurationSubscription;

  // Track if there's text for real-time updates
  bool _hasText = false;
  bool _isRecording = false;
  bool _isStartingRecording = false;
  Duration _recordingDuration = Duration.zero;
  String? _recordingPath;

  static const Duration _typingDebounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateTextStatus);
    _focusNode.addListener(_handleFocusChange);
    _recordingDurationSubscription =
        _recorderController.onCurrentDuration.listen((duration) {
      if (!mounted) return;
      setState(() => _recordingDuration = duration);
    });
    _updateTextStatus();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateTextStatus);
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _recordingDurationSubscription?.cancel();
    if (_isRecording) {
      _recorderController.stop();
    }
    _recorderController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _updateTextStatus() {
    final hasText = widget.controller.text.trim().isNotEmpty;
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
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendMessage(text);
    widget.controller.clear();
    _focusNode.requestFocus();

    _typingTimer?.cancel();
    widget.onTyping(false);
  }

  Future<void> _startVoiceRecording() async {
    if (_isRecording || _isStartingRecording) return;

    _focusNode.unfocus();
    widget.onTyping(false);

    setState(() {
      _isStartingRecording = true;
      _recordingDuration = Duration.zero;
    });

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Microphone permission is required');
      }

      final hasPermission = await _recorderController.checkPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission is required');
      }

      final file = File(
        '${Directory.systemTemp.path}/Clique_voice_${DateTime.now().microsecondsSinceEpoch}.m4a',
      );

      _recordingPath = file.path;
      await _recorderController.record(path: file.path);

      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _isStartingRecording = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _isStartingRecording = false;
        _recordingPath = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _cancelVoiceRecording() async {
    final path = _recordingPath;

    if (_isRecording) {
      await _recorderController.stop();
    }
    _recorderController.reset();

    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _isStartingRecording = false;
      _recordingDuration = Duration.zero;
      _recordingPath = null;
    });
  }

  Future<void> _finishVoiceRecording() async {
    if (!_isRecording) return;

    final fallbackPath = _recordingPath;
    final recordedDuration = _recordingDuration;
    final path = await _recorderController.stop();
    _recorderController.reset();

    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _isStartingRecording = false;
      _recordingDuration = Duration.zero;
      _recordingPath = null;
    });

    final resolvedPath = path ?? fallbackPath;
    if (resolvedPath == null) return;

    final file = File(resolvedPath);
    if (!await file.exists()) return;

    if (recordedDuration < const Duration(seconds: 1)) {
      await file.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice note is too short')),
      );
      return;
    }

    widget.onSendVoice(file);
  }

  void _showAttachmentMenu() {
    _focusNode.unfocus();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
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
                    Icons.image, 'Gallery', AppColors.attachmentPurple, () {
                  Navigator.pop(context);
                  widget.onPickImage();
                }),
                _buildAttachmentOption(
                    Icons.camera_alt, 'Camera', AppColors.attachmentCyan, () {
                  Navigator.pop(context);
                  widget.onPickCamera();
                }),
                _buildAttachmentOption(
                    Icons.videocam, 'Video', AppColors.attachmentGreen, () {
                  Navigator.pop(context);
                  widget.onPickVideo();
                }),
                _buildAttachmentOption(
                    Icons.folder, 'Document', AppColors.attachmentAmber, () {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.grey.shade200,
          ),
        ),
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
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.grey),
            onPressed: widget.onCancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar(Color surfaceColor, bool isDark) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _CircleIconButton(
              icon: Icons.delete_outline,
              iconColor: AppColors.red,
              backgroundColor: AppColors.red.withOpacity(0.1),
              onTap: _cancelVoiceRecording,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackgroundPress
                      : AppColors.inputLightBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(_recordingDuration),
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return AudioWaveforms(
                            size: Size(constraints.maxWidth, 36),
                            recorderController: _recorderController,
                            waveStyle: WaveStyle(
                              waveColor: widget.sendButtonColor,
                              extendWaveform: true,
                              showMiddleLine: false,
                              spacing: 5,
                              waveThickness: 3,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _CircleIconButton(
              icon: Icons.send_rounded,
              iconColor: AppColors.white,
              backgroundColor: widget.sendButtonColor,
              onTap: _finishVoiceRecording,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _hasText;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkCard : AppColors.white;
    final fieldColor =
        isDark ? AppColors.darkBackgroundPress : AppColors.inputLightBackground;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildReplyPreview(),
          if (_isRecording)
            _buildRecordingBar(surfaceColor, isDark)
          else
            Container(
              color: surfaceColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Material(
                      color: AppColors.transparent,
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
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: fieldColor,
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
                          controller: widget.controller,
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Material(
                        color: AppColors.transparent,
                        child: InkWell(
                          onTap: isActive ? _handleSend : _startVoiceRecording,
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: isActive || _isStartingRecording
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        widget.sendButtonColor,
                                        widget.sendButtonColor.withOpacity(0.8),
                                      ],
                                    )
                                  : null,
                              color: isActive || _isStartingRecording
                                  ? null
                                  : isDark
                                      ? AppColors.darkBackgroundPress
                                      : AppColors.grey.shade200,
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
                            child: _isStartingRecording
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Icon(
                                    isActive
                                        ? Icons.arrow_forward_rounded
                                        : Icons.mic_rounded,
                                    color: isActive
                                        ? AppColors.white
                                        : AppColors.grey.shade400,
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}
