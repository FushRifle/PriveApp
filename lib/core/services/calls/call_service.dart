import 'package:clique/core/clients/api_service.dart';
import 'package:clique/core/models/calls.dart';
import 'package:dio/dio.dart';

class CallService {
  final ApiService _api = ApiService();

  Future<CallResponse> startCall({
    required int receiverId,
    required String callType,
  }) async {
    try {
      final response = await _api.post(
        '/api/calls/start',
        data: {
          'receiverId': receiverId,
          'callType': callType,
        },
      );
      return CallResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<CallResponse> acceptCall({required int callId}) async {
    try {
      final response = await _api.post(
        '/api/calls/accept',
        data: {'callId': callId},
      );
      return CallResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> rejectCall({required int callId}) async {
    try {
      await _api.post(
        '/api/calls/reject',
        data: {'callId': callId},
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> endCall({required int callId}) async {
    try {
      await _api.post(
        '/api/calls/end',
        data: {'callId': callId},
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<TokenResponse> getToken({required String roomId}) async {
    try {
      final response = await _api.get(
        '/api/calls/token',
        queryParameters: {'roomId': roomId},
        forceRefresh: true,
        useCache: false,
      );
      return TokenResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<List<CallHistory>> getCallHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        '/api/calls/history',
        queryParameters: {'page': page, 'limit': limit},
        forceRefresh: true,
        useCache: false,
      );
      final data = response.data;
      if (data is! List) return [];
      return data
          .map((json) => CallHistory.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Call?> getActiveCall() async {
    try {
      final response = await _api.get(
        '/api/calls/active',
        forceRefresh: true,
        useCache: false,
      );
      final data = response.data;
      if (data == null) return null;
      return Call.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return e.message ?? 'Call request failed';
  }
}

class CallResponse {
  final Call call;
  final String roomId;
  final String token;
  final String liveKitUrl;

  const CallResponse({
    required this.call,
    required this.roomId,
    required this.token,
    required this.liveKitUrl,
  });

  factory CallResponse.fromJson(Map<String, dynamic> json) {
    return CallResponse(
      call: Call.fromJson(Map<String, dynamic>.from(json['call'] as Map)),
      roomId: json['roomId'] as String,
      token: json['token'] as String? ?? '',
      liveKitUrl: json['liveKitUrl'] as String? ?? '',
    );
  }
}

class TokenResponse {
  final String token;
  final String url;
  final String roomId;

  const TokenResponse({
    required this.token,
    required this.url,
    required this.roomId,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      token: json['token'] as String,
      url: json['url'] as String,
      roomId: json['roomId'] as String,
    );
  }
}
