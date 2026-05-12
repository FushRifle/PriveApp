import 'package:dio/dio.dart';
import '../../../core/api_service.dart';

class ReelService {
  final ApiService _api = ApiService();

  // Get reels with pagination
  Future<List<dynamic>> getReels({int page = 1}) async {
    try {
      final response = await _api.get('/api/reels', queryParameters: {
        'page': page,
      });
      return response.data is List ? response.data : [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get reels';
    }
  }

  // Create reel
  Future<Map<String, dynamic>> createReel(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/api/reels', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to create reel';
    }
  }

  // Like reel
  Future<Map<String, dynamic>> likeReel(String reelId) async {
    try {
      final response = await _api.post('/api/reels/$reelId/like');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to like reel';
    }
  }

  // Unlike reel
  Future<Map<String, dynamic>> unlikeReel(String reelId) async {
    try {
      final response = await _api.delete('/api/reels/$reelId/like');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to unlike reel';
    }
  }

  // Share reel
  Future<Map<String, dynamic>> shareReel(String reelId) async {
    try {
      final response = await _api.post('/api/reels/$reelId/share');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to share reel';
    }
  }

  // Get reel comments
  Future<List<dynamic>> getReelComments(String reelId, {int page = 1}) async {
    try {
      final response = await _api.get(
        '/api/reels/$reelId/comments',
        queryParameters: {'page': page},
      );
      return response.data is List ? response.data : [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get comments';
    }
  }

  // Add reel comment
  Future<Map<String, dynamic>> addReelComment({
    required String reelId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _api.post(
        '/api/reels/$reelId/comments',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to add comment';
    }
  }
}
