import 'package:clique/core/models/calls.dart';
import 'package:clique/core/services/calls/call_manager.dart';
import 'package:clique/core/services/calls/call_service.dart';
import 'package:clique/ui/pages/main/chat/call/active_call_screen.dart';
import 'package:clique/ui/widgets/chat/user_avatar.dart';
import 'package:flutter/material.dart';

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

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final CallManager _callManager = CallManager();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _callManager.playRingtone();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _callManager.stopRingtone();
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
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 120 + (20 * _animationController.value),
                  height: 120 + (20 * _animationController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green
                          .withOpacity(1 - _animationController.value),
                      width: 3,
                    ),
                  ),
                  child: UserAvatar(
                    avatarUrl: widget.notification.caller.avatar,
                    name: widget.notification.caller.name,
                    size: 100,
                  ),
                );
              },
            ),
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Incoming ${widget.notification.callType} call',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    onTap: () async {
                      await _callManager.stopRingtone();
                      await widget.callService.rejectCall(
                        callId: widget.notification.callId,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  _buildActionButton(
                    icon: widget.notification.callType == 'video'
                        ? Icons.videocam
                        : Icons.call,
                    color: Colors.green,
                    onTap: () async {
                      await _callManager.stopRingtone();
                      final response = await widget.callService.acceptCall(
                        callId: widget.notification.callId,
                      );
                      if (!context.mounted) return;
                      if (response.liveKitUrl.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Call service is not configured for LiveKit'),
                          ),
                        );
                        Navigator.pop(context);
                        return;
                      }
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActiveCallScreen(
                            callResponse: response,
                            isCaller: false,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
