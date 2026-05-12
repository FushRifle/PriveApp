import 'package:dio/dio.dart';
import '../../../core/api_service.dart';

class FriendsService {
  final ApiService _api = ApiService();

  // Follow user
  Future<Map<String, dynamic>> followUser(int userId) async {
    try {
      final response = await _api.post('/friends/follow/$userId');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to follow user';
    }
  }

  // Unfollow user
  Future<Map<String, dynamic>> unfollowUser(int userId) async {
    try {
      final response = await _api.delete('/friends/follow/$userId');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to unfollow user';
    }
  }

  // Get followers
  Future<Map<String, dynamic>> getFollowers(
      {int page = 1, int pageSize = 20}) async {
    try {
      final response = await _api.get('/friends/followers', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get followers';
    }
  }

  // Get following
  Future<Map<String, dynamic>> getFollowing(
      {int page = 1, int pageSize = 20}) async {
    try {
      final response = await _api.get('/friends/following', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get following';
    }
  }

  // Get friends
  Future<Map<String, dynamic>> getFriends(
      {int page = 1, int pageSize = 20}) async {
    try {
      final response = await _api.get('/friends/friends', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get friends';
    }
  }

  // Get follow stats
  Future<Map<String, dynamic>> getFollowStats() async {
    try {
      final response = await _api.get('/friends/stats');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get stats';
    }
  }

  // Check relationship with user
  Future<Map<String, dynamic>> checkRelationship(int userId) async {
    try {
      final response = await _api.get('/friends/relationship/$userId');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to check relationship';
    }
  }

  // Send friend request
  Future<Map<String, dynamic>> sendFriendRequest(int userId,
      {String? message}) async {
    try {
      final response = await _api.post('/friends/requests', data: {
        'userId': userId,
        if (message != null) 'message': message,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to send request';
    }
  }

  // Get pending requests
  Future<Map<String, dynamic>> getPendingRequests(
      {int page = 1, int pageSize = 20}) async {
    try {
      final response =
          await _api.get('/friends/requests/pending', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get pending requests';
    }
  }

  // Respond to friend request
  Future<Map<String, dynamic>> respondToRequest(
      int requestId, String action) async {
    try {
      final response =
          await _api.put('/friends/requests/$requestId/respond', data: {
        'action': action,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to respond to request';
    }
  }
}
