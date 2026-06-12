import 'dart:async';

import 'package:clique/app/configs/api_config.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/core/models/calls.dart';
import 'package:clique/core/services/calls/call_service.dart';
import 'package:clique/core/services/calls/permission_service.dart';
import 'package:clique/ui/pages/main/chat/call/active_call_screen.dart';
import 'package:clique/ui/pages/main/chat/call/outgoing_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final hasPermissions = await PermissionService.checkPermissions();
    if (!context.mounted) return;

    if (!hasPermissions) {
      final granted = await PermissionService.requestPermissions();
      if (!context.mounted) return;

      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and microphone permissions required'),
          ),
        );
        return;
      }
    }

    try {
      final callService = CallService();
      final currentUserId = _readCurrentUserId(
        context.read<AuthBloc>().state.user,
      );

      final activeCall = await callService.getActiveCall();
      if (!context.mounted) return;

      if (activeCall != null &&
          (activeCall.callerId == receiver.id ||
              activeCall.receiverId == receiver.id)) {
        final tokenResponse =
            await callService.getToken(roomId: activeCall.roomId);
        if (!context.mounted) return;

        final response = CallResponse(
          call: activeCall,
          roomId: tokenResponse.roomId,
          token: tokenResponse.token,
          liveKitUrl: tokenResponse.url,
        );

        final isCaller =
            currentUserId != null && activeCall.callerId == currentUserId;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isCaller
                ? OutgoingCallScreen(
                    callResponse: response,
                    receiver: receiver,
                  )
                : ActiveCallScreen(
                    callResponse: response,
                    isCaller: false,
                  ),
          ),
        );
        return;
      }

      final response = await callService.startCall(
        receiverId: receiver.id,
        callType: callType,
      );

      if (!context.mounted) return;

      if (response.liveKitUrl.trim().isEmpty &&
          ApiConfig.liveKitUrl.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call service is not configured for LiveKit'),
          ),
        );
        return;
      }

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

  static int? _readCurrentUserId(Map<String, dynamic>? user) {
    final rawId = user?['id'];
    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId);
    return null;
  }
}
