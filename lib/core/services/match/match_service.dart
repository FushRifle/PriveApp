import 'package:dio/dio.dart';
import '../../clients/api_service.dart';

class MatchService {
  final ApiService _api = ApiService();

  // Get my matches
  Future<List<dynamic>> getMatches() async {
    try {
      final response = await _api.get('/api/matches');
      return _readList(response.data, keys: const ['matches', 'data', 'items']);
    } on DioException catch (e) {
      throw _readError(e, 'Failed to get matches');
    }
  }

  // Like a user
  Future<Map<String, dynamic>> likeUser(int userId) async {
    try {
      final response = await _api.post('/api/matches/like', data: {
        'userId': userId,
      });
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readError(e, 'Failed to like user');
    }
  }

  // Accept match
  Future<Map<String, dynamic>> acceptMatch(int matchId) async {
    try {
      final response = await _api.post('/api/matches/$matchId/accept');
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readError(e, 'Failed to accept match');
    }
  }

  // Reject match
  Future<Map<String, dynamic>> rejectMatch(int matchId) async {
    try {
      final response = await _api.post('/api/matches/$matchId/reject');
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readError(e, 'Failed to reject match');
    }
  }

  // Get recommendations
  Future<List<dynamic>> getRecommendations() async {
    try {
      final response = await _api.get('/api/recommendations');
      return _readList(
        response.data,
        keys: const ['recommendations', 'profiles', 'users', 'data', 'items'],
      );
    } on DioException catch (e) {
      throw _readError(e, 'Failed to get recommendations');
    }
  }

  List<dynamic> _readList(
    dynamic data, {
    required List<String> keys,
  }) {
    if (data is List) return data;

    if (data is Map) {
      for (final key in keys) {
        final value = data[key];
        if (value is List) return value;
        if (value is Map) {
          final nested = _readList(value, keys: keys);
          if (nested.isNotEmpty) return nested;
        }
      }
    }

    return [];
  }

  Map<String, dynamic> _readMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  String _readError(DioException error, String fallback) {
    final data = error.response?.data;

    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }

    if (data is String && data.isNotEmpty) return data;

    return fallback;
  }
}
