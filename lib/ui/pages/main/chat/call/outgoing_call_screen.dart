import 'dart:async';

import 'package:clique/core/models/calls.dart';
import 'package:clique/core/services/calls/call_service.dart';
import 'package:clique/core/services/calls/stream_call_service.dart';
import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' as stream;
import 'package:clique/ui/widgets/call/clique_call_content.dart';

class OutgoingCallScreen extends StatefulWidget {
  final CallResponse? callResponse;
  final UserInfo receiver;
  final String? callType;

  const OutgoingCallScreen({
    super.key,
    this.callResponse,
    required this.receiver,
    this.callType,
  }) : assert(callResponse != null || callType != null);

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  final CallService _callService = CallService();
  stream.Call? _call;
  CallResponse? _backendCall;
  bool _isBootstrapping = true;
  bool _isCancelling = false;
  String _status = 'Preparing call...';
  Timer? _unansweredTimer;

  @override
  void initState() {
    super.initState();
    _backendCall = widget.callResponse;
    _startBootstrapTimeout();
    unawaited(_bootstrapCall());
  }

  void _startBootstrapTimeout() {
    _unansweredTimer?.cancel();
    _unansweredTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || _call != null || _isCancelling) return;
      setState(() {
        _isBootstrapping = false;
        _status = 'Call could not connect';
      });
      unawaited(_showErrorAndExit('The call took too long to connect.'));
    });
  }

  Future<void> _bootstrapCall() async {
    if (_backendCall == null && widget.callType == null) return;

    setState(() {
      _isBootstrapping = true;
      _status = _backendCall == null ? 'Starting call...' : 'Connecting...';
    });

    try {
      final backendCall = _backendCall ??
          await _callService.startCall(
            receiverId: widget.receiver.id,
            callType: widget.callType ?? 'voice',
          );

      if (!mounted) return;
      if (_isCancelling) {
        return;
      }

      final streamCall = await StreamCallService.instance.prepareOutgoingCall(
        callId: backendCall.roomId,
        memberIds: [widget.receiver.id.toString()],
        isVideo: backendCall.call.callType == 'video',
      );

      if (!mounted) return;
      setState(() {
        _backendCall = backendCall;
        _call = streamCall;
        _isBootstrapping = false;
        _status = 'Calling...';
      });
      _unansweredTimer?.cancel();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = e.toString();
        _isBootstrapping = false;
      });
      await _showErrorAndExit(_status);
    }
  }

  Future<void> _cancelCall() async {
    if (_isCancelling) return;
    _isCancelling = true;
    _unansweredTimer?.cancel();

    try {
      await _call?.reject(reason: stream.CallRejectReason.cancel());
    } catch (_) {}

    final backendCall = _backendCall;
    if (backendCall != null) {
      try {
        await _callService.endCall(callId: backendCall.call.id);
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pop(context);
    }

    _isCancelling = false;
  }

  Future<void> _showErrorAndExit(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.pop(context);
  }

  Future<void> _handleDisconnected(
    stream.CallDisconnectedProperties properties,
  ) async {
    if (_isCancelling) return;

    final backendCall = _backendCall;
    if (backendCall != null) {
      try {
        await _callService.endCall(callId: backendCall.call.id);
      } catch (_) {}
    }

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _unansweredTimer?.cancel();
    final backendCall = _backendCall;
    if (!_isCancelling && backendCall != null) {
      unawaited(_callService.endCall(callId: backendCall.call.id));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = _call;
    if (call != null) {
      _unansweredTimer?.cancel();
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: stream.StreamCallContainer(
            call: call,
            onCancelCallTap: _cancelCall,
            onCallDisconnected: _handleDisconnected,
            callContentWidgetBuilder: (context, activeCall) =>
                CliqueCallContent(
              call: activeCall,
              isVideo: _backendCall?.call.callType == 'video',
              onLeave: _cancelCall,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.receiver.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.receiver.username,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green, width: 3),
                    ),
                    child: CircleAvatar(
                      backgroundImage: widget.receiver.avatar.isNotEmpty
                          ? NetworkImage(widget.receiver.avatar)
                          : null,
                      backgroundColor: Colors.grey[800],
                      child: widget.receiver.avatar.isEmpty
                          ? Text(
                              widget.receiver.name.isNotEmpty
                                  ? widget.receiver.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isBootstrapping
                        ? 'Checking permissions, creating the call, and joining the room.'
                        : 'Waiting for ${widget.receiver.name} to answer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.58),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isBootstrapping)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
