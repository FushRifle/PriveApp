import 'dart:async';

import 'package:clique/core/models/calls.dart';
import 'package:clique/core/services/calls/call_manager.dart';
import 'package:clique/core/services/calls/call_service.dart';
import 'package:clique/ui/pages/main/chat/call/active_call_screen.dart';
import 'package:clique/ui/widgets/chat/user_avatar.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:livekit_client/livekit_client.dart';

class OutgoingCallScreen extends StatefulWidget {
  final CallResponse callResponse;
  final UserInfo receiver;

  const OutgoingCallScreen({
    super.key,
    required this.callResponse,
    required this.receiver,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  final CallManager _callManager = CallManager();
  final CallService _callService = CallService();
  bool _isConnecting = true;
  String _status = 'Calling...';
  bool _navigatedToActiveCall = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _setupCallManagerCallbacks();
    _initCall();
    _callManager.playDialTone();
    _checkCallTimeout();
  }

  void _setupCallManagerCallbacks() {
    _callManager.onConnectionStateChanged((state) {
      if (!mounted) return;
      setState(() {
        _isConnecting = state != ConnectionState.connected;
        _status = state == ConnectionState.connected ? 'Connected' : 'Calling...';
      });
    });

    _callManager.onParticipantJoined((_) {
      _goToActiveCall();
    });

    _callManager.onParticipantLeft((_) {
      if (!mounted) return;
      setState(() {
        _status = 'Participant left';
      });
    });
  }

  Future<void> _initCall() async {
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
    if (!mounted) return;
    if (_callManager.remoteParticipants.isNotEmpty) {
      _goToActiveCall();
    }
  }

  void _goToActiveCall() {
    if (_navigatedToActiveCall || !mounted) return;
    _navigatedToActiveCall = true;
    _callManager.stopDialTone();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveCallScreen(
          callResponse: widget.callResponse,
          isCaller: true,
        ),
      ),
    );
  }

  void _checkCallTimeout() {
    Future.delayed(const Duration(seconds: 45), () async {
      if (!_isConnecting || !mounted || _navigatedToActiveCall) return;
      await _cancelCall(showNoAnswer: true);
    });
  }

  Future<void> _cancelCall({bool showNoAnswer = false}) async {
    if (_isCancelling) return;
    _isCancelling = true;
    await _callManager.stopDialTone();
    await _callManager.leaveCall();
    try {
      await _callService.endCall(callId: widget.callResponse.call.id);
    } catch (_) {}
    if (!mounted) return;
    if (showNoAnswer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No answer')),
      );
    }
    Navigator.pop(context);
    _isCancelling = false;
  }

  @override
  void dispose() {
    _callManager.stopDialTone();
    unawaited(_callManager.leaveCall());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              widget.receiver.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.receiver.username,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 3),
              ),
              child: UserAvatar(
                avatarUrl: widget.receiver.avatar,
                name: widget.receiver.name,
                size: 100,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _status,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GestureDetector(
                onTap: _cancelCall,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
