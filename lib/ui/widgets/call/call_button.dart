import 'dart:async';

import 'package:clique/core/models/calls.dart';
import 'package:clique/core/services/calls/call_service.dart';
import 'package:clique/core/services/calls/permission_service.dart';
import 'package:clique/ui/pages/main/chat/call/outgoing_call_screen.dart';
import 'package:flutter/material.dart';

class CallButton extends StatelessWidget {
  final UserInfo receiver;

  const CallButton({
    super.key,
    required this.receiver,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.call),
      onSelected: (value) => initiateCall(context, receiver: receiver, callType: value),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'voice',
          child: Row(
            children: [
              Icon(Icons.call),
              SizedBox(width: 12),
              Text('Voice Call'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'video',
          child: Row(
            children: [
              Icon(Icons.videocam),
              SizedBox(width: 12),
              Text('Video Call'),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> initiateCall(
    BuildContext context, {
    required UserInfo receiver,
    required String callType,
  }) async {
    final hasPermissions = await PermissionService.requestPermissions();
    if (!context.mounted) return;

    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera and microphone permissions required'),
        ),
      );
      return;
    }

    try {
      final callService = CallService();
      final response = await callService.startCall(
        receiverId: receiver.id,
        callType: callType,
      );

      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OutgoingCallScreen(
            callResponse: response,
            receiver: receiver,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start call: $e')),
      );
    }
  }
}
