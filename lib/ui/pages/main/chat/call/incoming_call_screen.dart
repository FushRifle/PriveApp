import 'dart:async';

import 'package:clique/core/models/calls.dart';
import 'package:clique/core/services/calls/call_service.dart';
import 'package:clique/core/services/calls/stream_call_service.dart';
import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' as stream;

class IncomingCallScreen extends StatefulWidget {
  final IncomingCallNotification notification;
  final CallService callService;

  const IncomingCallScreen({
    super.key,
    required this.notification,
    required this.callService,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  stream.Call? _call;
  bool _isPreparing = true;
  bool _isResponding = false;
  String _status = 'Incoming call...';

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrapCall());
  }

  Future<void> _bootstrapCall() async {
    try {
      final call = await StreamCallService.instance.prepareIncomingCall(
        callId: widget.notification.roomId,
      );
      if (!mounted) return;
      setState(() {
        _call = call;
        _isPreparing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = e.toString();
        _isPreparing = false;
      });
      await _showErrorAndExit(_status);
    }
  }

  Future<void> _acceptCall() async {
    if (_isResponding || _call == null) return;
    _isResponding = true;

    try {
      await widget.callService.acceptCall(callId: widget.notification.callId);
      await _call!.accept();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      _isResponding = false;
    }
  }

  Future<void> _declineCall() async {
    if (_isResponding || _call == null) return;
    _isResponding = true;

    try {
      await widget.callService.rejectCall(callId: widget.notification.callId);
      await _call!.reject(reason: stream.CallRejectReason.decline());
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      _isResponding = false;
    }
  }

  Future<void> _handleDisconnected(
    stream.CallDisconnectedProperties properties,
  ) async {
    if (_isResponding) return;

    try {
      await widget.callService.endCall(callId: widget.notification.callId);
    } catch (_) {}

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _showErrorAndExit(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.pop(context);
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
            onAcceptCallTap: _acceptCall,
            onDeclineCallTap: _declineCall,
            onCallDisconnected: _handleDisconnected,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.notification.caller.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.notification.caller.username,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _status,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              if (_isPreparing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
