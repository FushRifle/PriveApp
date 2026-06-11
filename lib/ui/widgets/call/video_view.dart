import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class VideoView extends StatelessWidget {
  final VideoTrack? track;
  final BoxFit fit;
  final bool mirrored;

  const VideoView({
    super.key,
    this.track,
    this.fit = BoxFit.cover,
    this.mirrored = false,
  });

  @override
  Widget build(BuildContext context) {
    if (track == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.videocam_off,
            color: Colors.white54,
            size: 48,
          ),
        ),
      );
    }

    return VideoTrackRenderer(
      track!,
      fit: fit == BoxFit.contain ? VideoViewFit.contain : VideoViewFit.cover,
      mirrorMode: mirrored
          ? VideoViewMirrorMode.mirror
          : VideoViewMirrorMode.auto,
    );
  }
}
