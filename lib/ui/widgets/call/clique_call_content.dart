import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' as stream;

class CliqueCallContent extends StatelessWidget {
  final stream.Call call;
  final bool isVideo;
  final VoidCallback onLeave;

  const CliqueCallContent({
    super.key,
    required this.call,
    required this.isVideo,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return stream.StreamCallContent(
      call: call,
      onLeaveCallTap: onLeave,
      extendBody: true,
      callControlsWidgetBuilder: (context, call) {
        return SafeArea(
          top: false,
          child: stream.StreamCallControls(
            backgroundColor: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            spacing: 6,
            options: [
              stream.ToggleSpeakerphoneOption(call: call),
              stream.ToggleMicrophoneOption(call: call),
              if (isVideo) stream.ToggleCameraOption(call: call),
              if (isVideo) stream.FlipCameraOption(call: call),
              if (isVideo) stream.ToggleScreenShareOption(call: call),
              stream.LeaveCallOption(call: call, onLeaveCallTap: onLeave),
            ],
          ),
        );
      },
    );
  }
}
