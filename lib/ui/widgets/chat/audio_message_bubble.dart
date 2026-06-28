import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:clique/app/configs/colors.dart';

class AudioMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final Color chatColor;

  const AudioMessageBubble({
    super.key,
    required this.audioUrl,
    required this.isMe,
    required this.chatColor,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  late AudioPlayer _player;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _player = AudioPlayer();

    // Set up listeners
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _positionSubscription = _player.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _duration = duration;
          _isLoading = false;
        });
      }
    });

    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(widget.audioUrl)));
    } catch (e) {
      debugPrint('Error loading audio: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final durationMs = _duration.inMilliseconds;
    final progress = durationMs <= 0
        ? 0.0
        : (_position.inMilliseconds / durationMs).clamp(0.0, 1.0);

    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isMe ? widget.chatColor : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: BoxBorder.all(color: AppColors.cardBorderColor)
      ),
      child: _isLoading
          ? const SizedBox(
              height: 50,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : Row(
              children: [
                GestureDetector(
                  onTap: _togglePlayback,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.isMe ? AppColors.white : widget.chatColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 18,
                      color: widget.isMe ? widget.chatColor : AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: widget.isMe
                            ? AppColors.white24
                            : AppColors.grey.shade300,
                        color: widget.isMe ? AppColors.white : widget.chatColor,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.isMe
                                  ? AppColors.text
                                  : AppColors.text,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.isMe
                                  ? AppColors.text
                                  : AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
