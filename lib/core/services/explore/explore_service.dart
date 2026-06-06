import 'package:dio/dio.dart';
import '../../clients/api_service.dart';
import 'package:clique/core/models/profile_model.dart';

class ExploreService {
  final ApiService _api = ApiService();

  // Get explore profiles
  Future<Map<String, dynamic>> getExploreProfiles({
    int page = 1,
    String filter = 'all',
    int? minAge,
    int? maxAge,
    int? distance,
    List<String>? interests,
    bool? verifiedOnly,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'filter': filter,
      };
      if (minAge != null) queryParams['minAge'] = minAge;
      if (maxAge != null) queryParams['maxAge'] = maxAge;
      if (distance != null) queryParams['distance'] = distance;
      if (interests != null && interests.isNotEmpty) {
        queryParams['interests'] = interests.join(',');
      }
      if (verifiedOnly == true) queryParams['verifiedOnly'] = true;
      if (sortBy != null) queryParams['sortBy'] = sortBy;

      final response =
          await _api.get('/api/explore', queryParameters: queryParams);
      final data = _readMap(response.data);
      return {
        'profiles': _readList(data['profiles'] ?? data['data'])
            .map((json) => ProfileModel.fromJson(json))
            .toList(),
        'hasMore': data['hasMore'] ?? data['has_more'] ?? false,
        'page': data['page'] ?? 1,
        'total': data['total'] ?? 0,
      };
    } on DioException catch (e) {
      throw _readError(e, 'Failed to get profiles');
    }
  }

  // Get filters
  Future<List<dynamic>> getFilters() async {
    try {
      final response = await _api.get('/api/explore/filters');
      return response.data ?? [];
    } on DioException catch (e) {
      throw _readError(e, 'Failed to get filters');
    }
  }

  // Swipe
  Future<Map<String, dynamic>> swipe(int profileId, String action) async {
    try {
      final response = await _api.post('/api/explore/swipe', data: {
        'profileId': profileId,
        'action': action,
      });
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readError(e, 'Failed to swipe');
    }
  }

  // Get matches
  Future<Map<String, dynamic>> getMatches({int page = 1}) async {
    try {
      final response = await _api.get('/api/explore/matches', queryParameters: {
        'page': page,
      });
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readError(e, 'Failed to get matches');
    }
  }

  // Get liked profiles
  Future<Map<String, dynamic>> getLikedProfiles({int page = 1}) async {
    try {
      final response = await _api.get('/api/explore/likes', queryParameters: {
        'page': page,
      });
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readError(e, 'Failed to get liked profiles');
    }
  }

  // Get liked by profiles
  Future<Map<String, dynamic>> getLikedByProfiles({int page = 1}) async {
    try {
      final response =
          await _api.get('/api/explore/liked-by', queryParameters: {
        'page': page,
      });
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readError(e, 'Failed to get liked by profiles');
    }
  }

  // Get swipe stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _api.get('/api/explore/stats');
      return _readMap(response.data);
    } on DioException catch (e) {
      throw _readError(e, 'Failed to get stats');
    }
  }

  Map<String, dynamic> _readMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  List<Map<String, dynamic>> _readList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  String _readError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return fallback;
  }
}
