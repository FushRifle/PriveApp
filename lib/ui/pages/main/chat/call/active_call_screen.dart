import 'dart:async';

import 'package:clique/core/services/calls/call_manager.dart';
import 'package:clique/core/services/calls/call_service.dart';
import 'package:clique/ui/widgets/call/video_view.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:livekit_client/livekit_client.dart';

class ActiveCallScreen extends StatefulWidget {
  final CallResponse callResponse;
  final bool isCaller;

  const ActiveCallScreen({
    super.key,
    required this.callResponse,
    required this.isCaller,
  });

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  late final CallManager _callManager;
  late final CallService _callService;
  bool _isMuted = false;
  bool _isCameraOn = true;
  bool _isSpeakerOn = true;
  Duration _callDuration = Duration.zero;
  Timer? _timer;
  String? _callStatus;

  @override
  void initState() {
    super.initState();
    _callManager = CallManager();
    _callService = CallService();
    _joinCall();
    _startTimer();
    _setupCallManagerCallbacks();
  }

  Future<void> _joinCall() async {
    final isVideo = widget.callResponse.call.callType == 'video';
    if (widget.callResponse.liveKitUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Call service is not configured for LiveKit'),
        ),
      );
      Navigator.pop(context);
      return;
    }

    await _callManager.joinCall(
      url: widget.callResponse.liveKitUrl,
      token: widget.callResponse.token,
      roomId: widget.callResponse.roomId,
      isPublisher: true,
      enableVideo: isVideo,
    );

    _callManager.onConnectionStateChanged((state) {
      if (!mounted) return;
      setState(() {
        _callStatus = state.toString();
        _isMuted = !_callManager.isMicrophoneEnabled;
        _isCameraOn = _callManager.isCameraEnabled;
      });
      if (state == ConnectionState.disconnected) {
        _endCall(notifyBackend: false);
      }
    });
  }

  void _setupCallManagerCallbacks() {
    _callManager.onParticipantJoined((_) {
      if (mounted) setState(() {});
    });

    _callManager.onParticipantLeft((_) {
      if (mounted) setState(() {});
    });

    _callManager.onTrackSubscribed((_) {
      if (mounted) setState(() {});
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _callDuration = Duration(seconds: timer.tick);
      });
    });
  }

  Future<void> _toggleMute() async {
    await _callManager.toggleMicrophone();
    if (!mounted) return;
    setState(() {
      _isMuted = !_callManager.isMicrophoneEnabled;
    });
  }

  Future<void> _toggleCamera() async {
    await _callManager.toggleCamera();
    if (!mounted) return;
    setState(() {
      _isCameraOn = _callManager.isCameraEnabled;
    });
  }

  Future<void> _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
  }

  Future<void> _endCall({bool notifyBackend = true}) async {
    _timer?.cancel();
    await _callManager.leaveCall();
    if (notifyBackend) {
      try {
        await _callService.endCall(callId: widget.callResponse.call.id);
      } catch (_) {}
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final remoteParticipants = _callManager.remoteParticipants;
    final hasVideo = widget.callResponse.call.callType == 'video';
    final remoteTrack = remoteParticipants.isNotEmpty
        ? CallManager.videoTrackFor(remoteParticipants.first)
        : null;
    final localTrack = _callManager.room?.localParticipant != null
        ? CallManager.videoTrackFor(_callManager.room!.localParticipant!)
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (hasVideo && remoteTrack != null)
            Positioned.fill(
              child: VideoView(
                track: remoteTrack,
                fit: BoxFit.cover,
              ),
            ),
          if (hasVideo && _isCameraOn)
            Positioned(
              top: 60,
              right: 16,
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: VideoView(
                    track: localTrack,
                    fit: BoxFit.cover,
                    mirrored: true,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  hasVideo ? 'Video call' : 'Voice call',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(_callDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_callStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _callStatus!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.red : Colors.grey[800]!,
                    onTap: _toggleMute,
                  ),
                  _buildControlButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    size: 56,
                    onTap: () => _endCall(),
                  ),
                  if (hasVideo)
                    _buildControlButton(
                      icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                      color: _isCameraOn ? Colors.grey[800]! : Colors.red,
                      onTap: _toggleCamera,
                    ),
                  if (!hasVideo)
                    _buildControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      color: _isSpeakerOn ? Colors.grey[800]! : Colors.red,
                      onTap: _toggleSpeaker,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    double size = 48,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_callManager.leaveCall());
    super.dispose();
  }
}
