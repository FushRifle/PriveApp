import 'package:clique/app/configs/api_config.dart';
import 'package:clique/core/clients/api_service.dart';
import 'package:clique/core/models/calls.dart';
import 'package:dio/dio.dart';

class CallService {
  final ApiService _api = ApiService();

  void setAuthToken(String token) {
    _api.setAuthToken(token);
  }

  void clearAuthToken() {
    _api.clearAuthToken();
  }

  Future<CallResponse> startCall({
    required int receiverId,
    required String callType,
  }) async {
    try {
      final response = await _api.post(
        '${ApiConfig.apiPrefix}${ApiConfig.callsEndpoint}/start',
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
        '${ApiConfig.apiPrefix}${ApiConfig.callsEndpoint}/accept',
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
        '${ApiConfig.apiPrefix}${ApiConfig.callsEndpoint}/reject',
        data: {'callId': callId},
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> endCall({required int callId}) async {
    try {
      await _api.post(
        '${ApiConfig.apiPrefix}${ApiConfig.callsEndpoint}/end',
        data: {'callId': callId},
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<StreamAuthResponse> getStreamAuth() async {
    try {
      final response = await _api.get(
        '${ApiConfig.apiPrefix}${ApiConfig.callsEndpoint}/stream-auth',
        forceRefresh: true,
        useCache: false,
      );
      return StreamAuthResponse.fromJson(
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
        '${ApiConfig.apiPrefix}${ApiConfig.callsEndpoint}/history',
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
        '${ApiConfig.apiPrefix}${ApiConfig.callsEndpoint}/active',
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

  const CallResponse({
    required this.call,
    required this.roomId,
  });

  factory CallResponse.fromJson(Map<String, dynamic> json) {
    return CallResponse(
      call: Call.fromJson(Map<String, dynamic>.from(json['call'] as Map)),
      roomId: json['roomId'] as String,
    );
  }
}

class StreamAuthResponse {
  final String apiKey;
  final String token;
  final UserInfo user;

  const StreamAuthResponse({
    required this.apiKey,
    required this.token,
    required this.user,
  });

  factory StreamAuthResponse.fromJson(Map<String, dynamic> json) {
    return StreamAuthResponse(
      apiKey: json['apiKey']?.toString().trim() ?? '',
      token: json['token'] as String,
      user: UserInfo.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }
}
