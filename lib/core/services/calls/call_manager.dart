import 'package:audioplayers/audioplayers.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:vibration/vibration.dart';

class CallManager {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  Room? _room;
  EventsListener<RoomEvent>? _roomListener;
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  final AudioPlayer _dialTonePlayer = AudioPlayer();

  void Function(Participant participant)? _onParticipantJoined;
  void Function(Participant participant)? _onParticipantLeft;
  void Function(ConnectionState state)? _onConnectionStateChanged;
  void Function(Track track)? _onTrackSubscribed;

  Room? get room => _room;

  bool get isInCall =>
      _room != null && _room!.connectionState == ConnectionState.connected;

  Future<void> joinCall({
    required String url,
    required String token,
    required String roomId,
    required bool isPublisher,
    bool enableVideo = true,
  }) async {
    try {
      await leaveCall();

      final room = Room();
      _room = room;
      _attachRoomListener(room);

      await room.connect(url, token);

      if (isPublisher) {
        await room.localParticipant?.setMicrophoneEnabled(true);
        if (enableVideo) {
          await room.localParticipant?.setCameraEnabled(true);
        }
      }
    } catch (e) {
      await leaveCall();
      rethrow;
    }
  }

  void _attachRoomListener(Room room) {
    _roomListener?.dispose();
    _roomListener = room.createListener()
      ..on<ParticipantConnectedEvent>((event) {
        _onParticipantJoined?.call(event.participant);
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        _onParticipantLeft?.call(event.participant);
      })
      ..on<RoomDisconnectedEvent>((_) {
        _onConnectionStateChanged?.call(ConnectionState.disconnected);
        _room = null;
      })
      ..on<TrackSubscribedEvent>((event) {
        _onTrackSubscribed?.call(event.track);
      });

    room.addListener(() {
      _onConnectionStateChanged?.call(room.connectionState);
      if (room.connectionState == ConnectionState.disconnected) {
        _room = null;
      }
    });
  }

  Future<void> leaveCall() async {
    _roomListener?.dispose();
    _roomListener = null;

    if (_room != null) {
      await _room?.disconnect();
      _room = null;
    }
  }

  Future<void> toggleMicrophone() async {
    final local = _room?.localParticipant;
    if (local == null) return;
    await local.setMicrophoneEnabled(!local.isMicrophoneEnabled());
  }

  Future<void> toggleCamera() async {
    final local = _room?.localParticipant;
    if (local == null) return;
    await local.setCameraEnabled(!local.isCameraEnabled());
  }

  bool get isMicrophoneEnabled =>
      _room?.localParticipant?.isMicrophoneEnabled() ?? false;

  bool get isCameraEnabled =>
      _room?.localParticipant?.isCameraEnabled() ?? false;

  List<RemoteParticipant> get remoteParticipants {
    if (_room == null) return [];
    return _room!.remoteParticipants.values.toList();
  }

  void onParticipantJoined(void Function(Participant participant) callback) {
    _onParticipantJoined = callback;
  }

  void onParticipantLeft(void Function(Participant participant) callback) {
    _onParticipantLeft = callback;
  }

  void onConnectionStateChanged(void Function(ConnectionState state) callback) {
    _onConnectionStateChanged = callback;
  }

  void onTrackSubscribed(void Function(Track track) callback) {
    _onTrackSubscribed = callback;
  }

  static VideoTrack? videoTrackFor(Participant participant) {
    for (final publication in participant.videoTrackPublications) {
      final track = publication.track;
      if (track is VideoTrack) {
        return track;
      }
    }
    return null;
  }

  Future<void> playRingtone() async {
    try {
      await _ringtonePlayer.play(AssetSource('sounds/ringtone.mp3'));
      await _ringtonePlayer.setVolume(1.0);
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(pattern: [1000, 1000], repeat: 0);
      }
    } catch (_) {}
  }

  Future<void> stopRingtone() async {
    try {
      await _ringtonePlayer.stop();
      await Vibration.cancel();
    } catch (_) {}
  }

  Future<void> playDialTone() async {
    try {
      await _dialTonePlayer.play(AssetSource('sounds/dial_tone.mp3'));
      await _dialTonePlayer.setVolume(0.5);
    } catch (_) {}
  }

  Future<void> stopDialTone() async {
    try {
      await _dialTonePlayer.stop();
    } catch (_) {}
  }

  void dispose() {
    _ringtonePlayer.dispose();
    _dialTonePlayer.dispose();
    leaveCall();
  }
}
