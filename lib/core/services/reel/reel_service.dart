import 'package:dio/dio.dart';
import '../../clients/api_service.dart';

class ReelService {
  final ApiService _api = ApiService();
  final Map<int, List<dynamic>> _reelsCache = {};

  List<dynamic>? readCachedReels({int page = 1}) {
    final cached = _reelsCache[page];
    if (cached == null || cached.isEmpty) return null;
    return List<dynamic>.from(cached);
  }

  // Get reels with pagination
  Future<List<dynamic>> getReels({
    int page = 1,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh && _reelsCache.containsKey(page)) {
        return _reelsCache[page]!;
      }

      final response = await _api.get('/api/reels',
          queryParameters: {
            'page': page,
            'scope': 'all',
            'includeFollowing': true,
            'includeOthers': true,
          },
          forceRefresh: forceRefresh);
      final reels = _readList(response.data);
      _reelsCache[page] = reels;
      return reels;
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to get reels');
    }
  }

  // Create reel
  Future<Map<String, dynamic>> createReel(Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      final text = [
        payload['caption'],
        payload['content'],
      ].whereType<Object>().join(' ');
      final mentions = _extractMentions(text);
      if (mentions.isNotEmpty) {
        payload['mentions'] = mentions;
      }

      final response = await _api.post('/api/reels', data: payload);
      _invalidateReelCaches();
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to create reel');
    }
  }

  // Like reel
  Future<Map<String, dynamic>> likeReel(String reelId) async {
    try {
      final response = await _api.post('/api/reels/$reelId/like');
      _invalidateReelCaches(reelId);
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to like reel');
    }
  }

  // Unlike reel
  Future<Map<String, dynamic>> unlikeReel(String reelId) async {
    try {
      final response = await _api.delete('/api/reels/$reelId/like');
      _invalidateReelCaches(reelId);
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to unlike reel');
    }
  }

  // Share reel
  Future<Map<String, dynamic>> shareReel(String reelId) async {
    try {
      final response = await _api.post('/api/reels/$reelId/share');
      _invalidateReelCaches(reelId);
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to share reel');
    }
  }

  Future<Map<String, dynamic>> repostReel({
    required String reelId,
    String content = '',
  }) async {
    try {
      final response = await _api.post(
        '/api/reels/$reelId/repost',
        data: {'content': content},
      );
      _invalidateReelCaches(reelId);
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readErrorMessage(e, 'Failed to repost reel');
    }
  }

  // Get reel comments
  Future<List<dynamic>> getReelComments(
    String reelId, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _api.get(
        '/api/reels/$reelId/comments',
        queryParameters: {'page': page},
        forceRefresh: forceRefresh,
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
      _invalidateReelCaches(reelId);
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

  void _invalidateReelCaches([String? reelId]) {
    _reelsCache.clear();
    _api.removeCacheByPath('/api/reels');
    if (reelId != null && reelId.isNotEmpty) {
      _api.removeCacheByPath('/api/reels/$reelId');
    }
  }

  List<String> _extractMentions(String text) {
    final seen = <String>{};
    return RegExp(r'(?<![A-Za-z0-9_])@([A-Za-z0-9_]+)')
        .allMatches(text)
        .map((match) => match.group(1)!.toLowerCase())
        .where(seen.add)
        .toList();
  }
}
