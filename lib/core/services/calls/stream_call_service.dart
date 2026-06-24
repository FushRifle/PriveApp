import 'dart:async';

import 'package:clique/core/services/calls/call_service.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' as stream;

class StreamCallService {
  StreamCallService._();

  static final StreamCallService instance = StreamCallService._();

  final CallService _callService = CallService();

  stream.StreamVideo? _client;
  String? _connectedUserId;
  Future<void>? _connectFuture;

  bool get isConnected => _client != null;

  void setAuthToken(String token) {
    _callService.setAuthToken(token);
  }

  void clearAuthToken() {
    _callService.clearAuthToken();
  }

  stream.StreamVideo get client {
    final client = _client;
    if (client == null) {
      throw StateError('Stream Video is not connected');
    }
    return client;
  }

  Future<void> connect() async {
    final existing = _connectFuture;
    if (existing != null) {
      return existing;
    }

    final future = _connectInternal();
    _connectFuture = future;

    try {
      await future;
    } finally {
      if (_connectFuture == future) {
        _connectFuture = null;
      }
    }
  }

  Future<void> _connectInternal() async {
    final auth = await _callService.getStreamAuth();
    final userId = auth.user.id.toString();

    if (_client != null && _connectedUserId == userId) {
      return;
    }

    await disconnect();

    if (auth.apiKey.trim().isEmpty || auth.token.trim().isEmpty) {
      throw StateError('Stream auth is not configured');
    }

    final user = stream.User.regular(
      userId: userId,
      name: auth.user.name.isEmpty ? auth.user.username : auth.user.name,
      image: auth.user.avatar.isEmpty ? null : auth.user.avatar,
    );

    _client = stream.StreamVideo(
      auth.apiKey,
      user: user,
      userToken: auth.token,
      tokenLoader: (_) async {
        final refreshed = await _callService.getStreamAuth();
        return refreshed.token;
      },
      failIfSingletonExists: false,
    );
    _connectedUserId = userId;
  }

  Future<void> disconnect() async {
    final client = _client;
    _client = null;
    _connectedUserId = null;

    if (client == null) {
      return;
    }

    try {
      await client.disconnect();
    } catch (_) {}

    try {
      await client.dispose();
    } catch (_) {}
  }

  Future<stream.Call> prepareOutgoingCall({
    required String callId,
    required List<String> memberIds,
    required bool isVideo,
  }) async {
    await connect();

    final call = client.makeCall(
      callType: stream.StreamCallType.defaultType(),
      id: callId,
    );

    final result = await call.getOrCreate(
      memberIds: memberIds,
      ringing: true,
      video: isVideo,
    );

    if (result.isFailure) {
      throw result.getErrorOrNull() ?? StateError('Failed to create call');
    }
    if (!isVideo) {
      await call.setCameraEnabled(enabled: false);
    }

    return call;
  }

  Future<stream.Call> prepareIncomingCall({
    required String callId,
    required bool isVideo,
  }) async {
    await connect();

    final call = client.makeCall(
      callType: stream.StreamCallType.defaultType(),
      id: callId,
    );

    final result = await call.getOrCreate();
    if (result.isFailure) {
      throw result.getErrorOrNull() ?? StateError('Failed to open call');
    }
    if (!isVideo) {
      await call.setCameraEnabled(enabled: false);
    }

    return call;
  }
}
