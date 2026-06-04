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
      return _readList(response.data);
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to get reels');
    }
  }

  // Create reel
  Future<Map<String, dynamic>> createReel(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/api/reels', data: data);
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to create reel');
    }
  }

  // Like reel
  Future<Map<String, dynamic>> likeReel(String reelId) async {
    try {
      final response = await _api.post('/api/reels/$reelId/like');
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to like reel');
    }
  }

  // Unlike reel
  Future<Map<String, dynamic>> unlikeReel(String reelId) async {
    try {
      final response = await _api.delete('/api/reels/$reelId/like');
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to unlike reel');
    }
  }

  // Share reel
  Future<Map<String, dynamic>> shareReel(String reelId) async {
    try {
      final response = await _api.post('/api/reels/$reelId/share');
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to share reel');
    }
  }

  // Get reel comments
  Future<List<dynamic>> getReelComments(String reelId, {int page = 1}) async {
    try {
      final response = await _api.get(
        '/api/reels/$reelId/comments',
        queryParameters: {'page': page},
      );
      return _readList(response.data);
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to get comments');
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
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to add comment');
    }
  }

  List<dynamic> _readList(dynamic data) {
    if (data is List) return data;

    if (data is Map) {
      for (final key in ['data', 'reels', 'comments', 'items', 'results']) {
        final value = data[key];
        if (value is List) return value;
        if (value is Map) {
          final nested = _readList(value);
          if (nested.isNotEmpty) return nested;
        }
      }
    }

    return [];
  }

  Map<String, dynamic> _readMap(dynamic data) {
    if (data is Map) {
      for (final key in ['reel', 'data', 'item']) {
        final value = data[key];
        if (value is Map) return Map<String, dynamic>.from(value);
      }

      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  String _readErrorMessage(DioException error, String fallback) {
    final data = error.response?.data;

    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return fallback;
  }
}
