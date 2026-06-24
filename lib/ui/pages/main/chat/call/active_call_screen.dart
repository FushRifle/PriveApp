import 'dart:async';

import 'package:clique/core/services/calls/call_service.dart';
import 'package:clique/core/services/calls/stream_call_service.dart';
import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' as stream;
import 'package:clique/ui/widgets/call/clique_call_content.dart';

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
  final CallService _callService = CallService();
  stream.Call? _call;
  String _status = 'Joining call...';

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrapCall());
  }

  Future<void> _bootstrapCall() async {
    try {
      final call = await StreamCallService.instance.prepareIncomingCall(
        callId: widget.callResponse.roomId,
        isVideo: widget.callResponse.call.callType == 'video',
      );
      if (!mounted) return;
      setState(() {
        _call = call;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = e.toString();
      });
    }
  }

  Future<void> _handleDisconnected(
    stream.CallDisconnectedProperties properties,
  ) async {
    try {
      await _callService.endCall(callId: widget.callResponse.call.id);
    } catch (_) {}

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = _call;
    if (call != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: stream.StreamCallContainer(
            call: call,
            onCallDisconnected: _handleDisconnected,
            callContentWidgetBuilder: (context, activeCall) =>
                CliqueCallContent(
              call: activeCall,
              isVideo: widget.callResponse.call.callType == 'video',
              onLeave: () => unawaited(_endActiveCall()),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Text(
            _status,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }

  Future<void> _endActiveCall() async {
    try {
      await _call?.leave();
      await _callService.endCall(callId: widget.callResponse.call.id);
    } catch (_) {}
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
  }
}
