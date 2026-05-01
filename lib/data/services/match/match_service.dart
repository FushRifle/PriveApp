import 'package:dio/dio.dart';
import '../api_service.dart';

class MatchService {
  final ApiService _api = ApiService();

  // Get my matches
  Future<List<dynamic>> getMatches() async {
    try {
      final response = await _api.get('/api/matches');
      return response.data['matches'] ?? response.data ?? [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get matches';
    }
  }

  // Like a user
  Future<Map<String, dynamic>> likeUser(int userId) async {
    try {
      final response = await _api.post('/api/matches/like', data: {
        'userId': userId,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to like user';
    }
  }

  // Accept match
  Future<Map<String, dynamic>> acceptMatch(int matchId) async {
    try {
      final response = await _api.post('/api/matches/$matchId/accept');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to accept match';
    }
  }

  // Reject match
  Future<Map<String, dynamic>> rejectMatch(int matchId) async {
    try {
      final response = await _api.post('/api/matches/$matchId/reject');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to reject match';
    }
  }

  // Get recommendations
  Future<List<dynamic>> getRecommendations() async {
    try {
      final response = await _api.get('/api/recommendations');
      return response.data['recommendations'] ?? response.data ?? [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get recommendations';
    }
  }
}
