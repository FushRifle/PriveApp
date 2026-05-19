import 'package:dio/dio.dart';
import '../../../core/api_service.dart';
import 'package:clique/data/models/profile_model.dart';

class ExploreService {
  final ApiService _api = ApiService();

  // Get explore profiles
  Future<Map<String, dynamic>> getExploreProfiles({
    int page = 1,
    String filter = 'all',
    int? minAge,
    int? maxAge,
    int? distance,
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
      if (verifiedOnly == true) queryParams['verifiedOnly'] = true;
      if (sortBy != null) queryParams['sortBy'] = sortBy;

      final response =
          await _api.get('/api/explore', queryParameters: queryParams);
      return {
        'profiles': (response.data['profiles'] as List?)
                ?.map((json) => ProfileModel.fromJson(json))
                .toList() ??
            [],
        'hasMore': response.data['hasMore'] ?? false,
        'page': response.data['page'] ?? 1,
        'total': response.data['total'] ?? 0,
      };
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get profiles';
    }
  }

  // Get filters
  Future<List<dynamic>> getFilters() async {
    try {
      final response = await _api.get('/api/explore/filters');
      return response.data ?? [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get filters';
    }
  }

  // Swipe
  Future<Map<String, dynamic>> swipe(int profileId, String action) async {
    try {
      final response = await _api.post('/api/explore/swipe', data: {
        'profileId': profileId,
        'action': action,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to swipe';
    }
  }

  // Get matches
  Future<Map<String, dynamic>> getMatches({int page = 1}) async {
    try {
      final response = await _api.get('/api/explore/matches', queryParameters: {
        'page': page,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get matches';
    }
  }

  // Get liked profiles
  Future<Map<String, dynamic>> getLikedProfiles({int page = 1}) async {
    try {
      final response = await _api.get('/api/explore/likes', queryParameters: {
        'page': page,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get liked profiles';
    }
  }

  // Get liked by profiles
  Future<Map<String, dynamic>> getLikedByProfiles({int page = 1}) async {
    try {
      final response =
          await _api.get('/api/explore/liked-by', queryParameters: {
        'page': page,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get liked by profiles';
    }
  }

  // Get swipe stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _api.get('/api/explore/stats');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get stats';
    }
  }
}
