import 'package:clique/core/models/calls.dart';
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
      onSelected: (value) =>
          initiateCall(context, receiver: receiver, callType: value),
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
    final navigator = Navigator.of(context);

    final isVideo = callType == 'video';
    final hasPermissions =
        await PermissionService.checkPermissions(video: isVideo);
    if (!context.mounted) return;

    if (!hasPermissions) {
      final granted =
          await PermissionService.requestPermissions(video: isVideo);
      if (!context.mounted) return;

      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Required call permission was not granted'),
          ),
        );
        return;
      }
    }

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => OutgoingCallScreen(
          receiver: receiver,
          callType: callType,
        ),
      ),
    );
  }
}
