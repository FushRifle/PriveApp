import 'dart:async';

import 'package:clique/app/configs/api_config.dart';
import 'package:clique/core/clients/api_service.dart';
import 'package:dio/dio.dart';
import 'package:stream_chat/stream_chat.dart' as stream;

class StreamChatService {
  StreamChatService._();

  static final StreamChatService instance = StreamChatService._();

  final ApiService _api = ApiService();

  stream.StreamChatClient? _client;
  String? _connectedUserId;
  Future<void>? _connectFuture;

  bool get isConnected => _client != null && _connectedUserId != null;

  stream.StreamChatClient get client {
    final client = _client;
    if (client == null) {
      throw StateError('Stream Chat is not connected');
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
    final auth = await _getStreamAuth();
    final userId = auth.user.id.toString();

    if (_client != null && _connectedUserId == userId) {
      return;
    }

    await disconnect();

    if (auth.apiKey.trim().isEmpty || auth.token.trim().isEmpty) {
      throw StateError('Stream Chat auth is not configured');
    }

    final user = stream.User(
      id: userId,
      name: auth.user.name.isEmpty ? auth.user.username : auth.user.name,
      image: auth.user.avatar.isEmpty ? null : auth.user.avatar,
    );

    final client = stream.StreamChatClient(
      auth.apiKey,
      logLevel: stream.Level.WARNING,
    );

    await client.connectUser(user, auth.token);

    _client = client;
    _connectedUserId = userId;
  }

  Future<_StreamAuthResponse> _getStreamAuth() async {
    try {
      final response = await _api.get(
        '${ApiConfig.apiPrefix}${ApiConfig.chatEndpoint}/stream-auth',
        forceRefresh: true,
        useCache: false,
      );
      return _StreamAuthResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> disconnect() async {
    final client = _client;
    _client = null;
    _connectedUserId = null;

    if (client == null) {
      return;
    }

    try {
      await client.disconnectUser();
    } catch (_) {}

    try {
      await client.dispose();
    } catch (_) {}
  }

  String? get currentUserId => _connectedUserId;

  int currentUserIdAsInt() {
    final userId = _connectedUserId;
    if (userId == null) {
      return 0;
    }

    return int.tryParse(userId) ?? userId.hashCode;
  }

  stream.Channel channelForConversation(
    int conversationId, {
    int? receiverId,
  }) {
    final members = <String>[
      if (_connectedUserId != null) _connectedUserId!,
      if (receiverId != null) receiverId.toString(),
    ];
    final extraData = members.isEmpty
        ? const <String, Object?>{}
        : <String, Object?>{'members': members};

    return client.channel(
      'messaging',
      id: conversationId.toString(),
      extraData: extraData.isEmpty ? null : extraData,
    );
  }

  Future<stream.ChannelState> watchChannel(
    int conversationId, {
    int? receiverId,
    int messageLimit = 50,
  }) async {
    await connect();
    final channel = channelForConversation(
      conversationId,
      receiverId: receiverId,
    );
    return channel.watch(
      presence: true,
      messagesPagination: stream.PaginationParams(limit: messageLimit),
    );
  }

  Future<stream.ChannelState> queryChannelMessages(
    int conversationId, {
    int? receiverId,
    required int page,
    int messageLimit = 50,
  }) async {
    await connect();
    final channel = channelForConversation(
      conversationId,
      receiverId: receiverId,
    );
    final offset = page <= 1 ? 0 : (page - 1) * messageLimit;
    return channel.query(
      presence: true,
      messagesPagination: stream.PaginationParams(
        limit: messageLimit,
        offset: offset,
      ),
    );
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return e.message ?? 'Stream chat request failed';
  }
}

class _StreamAuthResponse {
  final String apiKey;
  final String token;
  final _StreamUser user;

  const _StreamAuthResponse({
    required this.apiKey,
    required this.token,
    required this.user,
  });

  factory _StreamAuthResponse.fromJson(Map<String, dynamic> json) {
    return _StreamAuthResponse(
      apiKey: json['apiKey']?.toString().trim() ?? '',
      token: json['token'] as String,
      user:
          _StreamUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }
}

class _StreamUser {
  final int id;
  final String name;
  final String username;
  final String avatar;

  const _StreamUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
  });

  factory _StreamUser.fromJson(Map<String, dynamic> json) {
    return _StreamUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
    );
  }
}
