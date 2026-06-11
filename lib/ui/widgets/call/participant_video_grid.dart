import 'package:clique/core/services/calls/call_manager.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'video_view.dart';

class ParticipantVideoGrid extends StatelessWidget {
  final List<Participant> participants;
  final Participant? localParticipant;
  final bool isVideoCall;

  const ParticipantVideoGrid({
    super.key,
    required this.participants,
    this.localParticipant,
    this.isVideoCall = true,
  });

  @override
  Widget build(BuildContext context) {
    final allParticipants = [
      if (localParticipant != null) localParticipant!,
      ...participants,
    ];

    if (!isVideoCall || allParticipants.isEmpty) {
      return _buildVoiceCallBackground();
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getGridColumns(allParticipants.length),
        childAspectRatio: 9 / 16,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: allParticipants.length,
      itemBuilder: (context, index) {
        final participant = allParticipants[index];
        final videoTrack = CallManager.videoTrackFor(participant);

        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              if (videoTrack != null)
                VideoView(
                  track: videoTrack,
                  fit: BoxFit.cover,
                  mirrored: participant == localParticipant,
                )
              else
                _buildAvatarPlaceholder(participant),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!participant.isMicrophoneEnabled())
                        const Icon(Icons.mic_off, color: Colors.red, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        participant.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceCallBackground() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.headset,
              color: Colors.white54,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Voice Call in Progress',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(Participant participant) {
    final initial = participant.name.isNotEmpty
        ? participant.name.substring(0, 1).toUpperCase()
        : '?';
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  int _getGridColumns(int count) {
    if (count <= 1) return 1;
    if (count <= 4) return 2;
    return 3;
  }
}
