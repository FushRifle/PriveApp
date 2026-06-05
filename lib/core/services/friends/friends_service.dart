import 'package:dio/dio.dart';
import '../../clients/api_service.dart';

class FriendsService {
  final ApiService _api = ApiService();

  void setAuthToken(String token) {
    _api.setAuthToken(token);
  }

  void clearAuthToken() {
    _api.clearAuthToken();
  }

  // Follow a user
  Future<void> followUser(int userId) async {
    try {
      await _api.post('/api/friends/follow/$userId');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to follow user');
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(int userId) async {
    try {
      await _api.delete('/api/friends/follow/$userId');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to unfollow user');
    }
  }

  // Get followers list
  Future<FriendsResponse> getFollowers(
      {int page = 1, int pageSize = 20}) async {
    try {
      final response =
          await _api.get('/api/friends/followers', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      return FriendsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get followers');
    }
  }

  // Get following list
  Future<FriendsResponse> getFollowing(
      {int page = 1, int pageSize = 20}) async {
    try {
      final response =
          await _api.get('/api/friends/following', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      return FriendsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get following');
    }
  }

  // Get friends list (mutual follows)
  Future<FriendsResponse> getFriends({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _api.get('/api/friends/friends', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      return FriendsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get friends');
    }
  }

  // Get follow stats (followers count, following count)
  Future<FollowStats> getFollowStats() async {
    try {
      final response = await _api.get('/api/friends/stats');
      return FollowStats.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get follow stats');
    }
  }

  // Check relationship with a user
  Future<Relationship> checkRelationship(int userId) async {
    try {
      final response = await _api.get('/api/friends/relationship/$userId');
      return Relationship.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to check relationship');
    }
  }

  // Send friend request
  Future<void> sendFriendRequest(int userId, {String? message}) async {
    try {
      final data = {
        'user_id': userId,
        if (message != null && message.isNotEmpty) 'message': message,
      };
      await _api.post('/api/friends/requests', data: data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to send friend request');
    }
  }

  // Get pending friend requests
  Future<PendingRequestsResponse> getPendingRequests(
      {int page = 1, int pageSize = 20}) async {
    try {
      final response =
          await _api.get('/api/friends/requests/pending', queryParameters: {
        'page': page,
        'pageSize': pageSize,
      });
      return PendingRequestsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get pending requests');
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(int requestId) async {
    try {
      await _api.put('/api/friends/requests/$requestId/respond', data: {
        'action': 'accept',
      });
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to accept friend request');
    }
  }

  // Decline friend request
  Future<void> declineFriendRequest(int requestId) async {
    try {
      await _api.put('/api/friends/requests/$requestId/respond', data: {
        'action': 'decline',
      });
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to decline friend request');
    }
  }

  String _handleError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    return fallback;
  }
}

// Response Models
class FriendsResponse {
  final List<FriendUser> data;
  final int total;
  final int page;

  FriendsResponse({
    required this.data,
    required this.total,
    required this.page,
  });

  factory FriendsResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List? ?? [];
    return FriendsResponse(
      data: dataList.map((item) => FriendUser.fromJson(item)).toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
    );
  }
}

class FriendUser {
  final int id;
  final String name;
  final String username;
  final String? avatar;
  final bool isVerified;
  final String? bio;
  final String? location;
  final bool isFollowing;
  final bool isFollowedBy;

  FriendUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    this.isVerified = false,
    this.bio,
    this.location,
    this.isFollowing = false,
    this.isFollowedBy = false,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['username'] ?? 'User',
      username: json['username'] ?? '',
      avatar: json['avatar'],
      isVerified: json['verified'] == true || json['isVerified'] == true,
      bio: json['bio'],
      location: json['location'],
      isFollowing: json['isFollowing'] == true,
      isFollowedBy: json['isFollowedBy'] == true,
    );
  }
}

class FollowStats {
  final int followersCount;
  final int followingCount;
  final int friendsCount;

  FollowStats({
    required this.followersCount,
    required this.followingCount,
    required this.friendsCount,
  });

  factory FollowStats.fromJson(Map<String, dynamic> json) {
    return FollowStats(
      followersCount: json['followersCount'] ?? json['followers'] ?? 0,
      followingCount: json['followingCount'] ?? json['following'] ?? 0,
      friendsCount: json['friendsCount'] ?? json['friends'] ?? 0,
    );
  }
}

class Relationship {
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isFriend;
  final bool hasPendingRequest;
  final bool hasReceivedRequest;

  Relationship({
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isFriend = false,
    this.hasPendingRequest = false,
    this.hasReceivedRequest = false,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) {
    return Relationship(
      isFollowing: json['isFollowing'] == true,
      isFollowedBy: json['isFollowedBy'] == true,
      isFriend: json['isFriend'] == true,
      hasPendingRequest:
          json['hasPendingRequest'] == true || json['pendingRequest'] == true,
      hasReceivedRequest: json['hasReceivedRequest'] == true,
    );
  }
}

class PendingRequest {
  final int id;
  final int userId;
  final String name;
  final String username;
  final String? avatar;
  final String? message;
  final DateTime createdAt;

  PendingRequest({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    this.avatar,
    this.message,
    required this.createdAt,
  });

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    return PendingRequest(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? json['user_id'] ?? 0,
      name: json['name'] ?? json['username'] ?? 'User',
      username: json['username'] ?? '',
      avatar: json['avatar'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
    );
  }
}

class PendingRequestsResponse {
  final List<PendingRequest> data;
  final int page;

  PendingRequestsResponse({
    required this.data,
    required this.page,
  });

  factory PendingRequestsResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List? ?? [];
    return PendingRequestsResponse(
      data: dataList.map((item) => PendingRequest.fromJson(item)).toList(),
      page: json['page'] ?? 1,
    );
  }
}
