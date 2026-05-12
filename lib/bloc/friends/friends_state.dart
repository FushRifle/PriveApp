part of 'friends_bloc.dart';

class FriendUser {
  final int id;
  final String name;
  final String? username;
  final String? avatar;
  final bool isVerified;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? followedAt;
  final String? relationshipStatus;

  const FriendUser({
    required this.id,
    required this.name,
    this.username,
    this.avatar,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
    this.followedAt,
    this.relationshipStatus,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'User',
      username: json['username']?.toString(),
      avatar: json['avatar']?.toString(),
      isVerified: json['verified'] == true || json['isVerified'] == true,
      isOnline: json['isOnline'] == true,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      followedAt: json['followedAt'] != null
          ? DateTime.tryParse(json['followedAt'].toString())
          : null,
      relationshipStatus: json['relationshipStatus']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (username != null) 'username': username,
        if (avatar != null) 'avatar': avatar,
        'isVerified': isVerified,
        'isOnline': isOnline,
        if (lastSeen != null) 'lastSeen': lastSeen?.toIso8601String(),
        if (followedAt != null) 'followedAt': followedAt?.toIso8601String(),
        if (relationshipStatus != null)
          'relationshipStatus': relationshipStatus,
      };

  FriendUser copyWith({
    int? id,
    String? name,
    String? username,
    String? avatar,
    bool? isVerified,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? followedAt,
    String? relationshipStatus,
  }) {
    return FriendUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      followedAt: followedAt ?? this.followedAt,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
    );
  }
}

class FriendRequest {
  final int id;
  final int fromUserId;
  final FriendUser fromUser;
  final String? message;
  final DateTime createdAt;
  final String status;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUser,
    this.message,
    required this.createdAt,
    this.status = 'pending',
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] ?? 0,
      fromUserId: json['fromUserId'] ?? json['from_user_id'] ?? 0,
      fromUser:
          FriendUser.fromJson(json['fromUser'] ?? json['from_user'] ?? {}),
      message: json['message']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
    );
  }

  FriendRequest copyWith({
    int? id,
    int? fromUserId,
    FriendUser? fromUser,
    String? message,
    DateTime? createdAt,
    String? status,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUser: fromUser ?? this.fromUser,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

class FollowStats {
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final int pendingRequestsCount;

  const FollowStats({
    this.followersCount = 0,
    this.followingCount = 0,
    this.friendsCount = 0,
    this.pendingRequestsCount = 0,
  });

  factory FollowStats.fromJson(Map<String, dynamic> json) {
    return FollowStats(
      followersCount: json['followersCount'] ?? json['followers'] ?? 0,
      followingCount: json['followingCount'] ?? json['following'] ?? 0,
      friendsCount: json['friendsCount'] ?? json['friends'] ?? 0,
      pendingRequestsCount: json['pendingRequestsCount'] ?? 0,
    );
  }
}

class Relationship {
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isFriend;
  final bool hasPendingRequest;
  final bool hasReceivedRequest;

  const Relationship({
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
      hasPendingRequest: json['hasPendingRequest'] == true,
      hasReceivedRequest: json['hasReceivedRequest'] == true,
    );
  }

  String get buttonText {
    if (isFriend) return 'Friends';
    if (hasReceivedRequest) return 'Accept Request';
    if (hasPendingRequest) return 'Request Sent';
    if (isFollowing) return 'Following';
    if (isFollowedBy) return 'Follow Back';
    return 'Follow';
  }
}

class FriendsState extends Equatable {
  // Followers
  final List<FriendUser> followers;
  final bool hasMoreFollowers;
  final int followersPage;

  // Following
  final List<FriendUser> following;
  final bool hasMoreFollowing;
  final int followingPage;

  // Friends (mutual)
  final List<FriendUser> friends;
  final bool hasMoreFriends;
  final int friendsPage;

  // Pending requests
  final List<FriendRequest> pendingRequests;
  final bool hasMorePendingRequests;
  final int pendingRequestsPage;

  // Stats
  final FollowStats? stats;
  final Map<int, Relationship> relationships;

  // Status
  final FriendsStatus status;
  final FriendsStatus friendsStatus;
  final FriendsStatus requestsStatus;
  final String? error;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final Set<int> pendingActions;

  const FriendsState({
    this.followers = const [],
    this.hasMoreFollowers = true,
    this.followersPage = 1,
    this.following = const [],
    this.hasMoreFollowing = true,
    this.followingPage = 1,
    this.friends = const [],
    this.hasMoreFriends = true,
    this.friendsPage = 1,
    this.pendingRequests = const [],
    this.hasMorePendingRequests = true,
    this.pendingRequestsPage = 1,
    this.stats,
    this.relationships = const {},
    this.status = FriendsStatus.initial,
    this.friendsStatus = FriendsStatus.initial,
    this.requestsStatus = FriendsStatus.initial,
    this.error,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.pendingActions = const {},
  });

  FriendsState copyWith({
    List<FriendUser>? followers,
    bool? hasMoreFollowers,
    int? followersPage,
    List<FriendUser>? following,
    bool? hasMoreFollowing,
    int? followingPage,
    List<FriendUser>? friends,
    bool? hasMoreFriends,
    int? friendsPage,
    List<FriendRequest>? pendingRequests,
    bool? hasMorePendingRequests,
    int? pendingRequestsPage,
    FollowStats? stats,
    Map<int, Relationship>? relationships,
    FriendsStatus? status,
    FriendsStatus? friendsStatus,
    FriendsStatus? requestsStatus,
    String? error,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    Set<int>? pendingActions,
  }) {
    return FriendsState(
      followers: followers ?? this.followers,
      hasMoreFollowers: hasMoreFollowers ?? this.hasMoreFollowers,
      followersPage: followersPage ?? this.followersPage,
      following: following ?? this.following,
      hasMoreFollowing: hasMoreFollowing ?? this.hasMoreFollowing,
      followingPage: followingPage ?? this.followingPage,
      friends: friends ?? this.friends,
      hasMoreFriends: hasMoreFriends ?? this.hasMoreFriends,
      friendsPage: friendsPage ?? this.friendsPage,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      hasMorePendingRequests:
          hasMorePendingRequests ?? this.hasMorePendingRequests,
      pendingRequestsPage: pendingRequestsPage ?? this.pendingRequestsPage,
      stats: stats ?? this.stats,
      relationships: relationships ?? this.relationships,
      status: status ?? this.status,
      friendsStatus: friendsStatus ?? this.friendsStatus,
      requestsStatus: requestsStatus ?? this.requestsStatus,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      pendingActions: pendingActions ?? this.pendingActions,
    );
  }

  @override
  List<Object?> get props => [
        followers,
        hasMoreFollowers,
        followersPage,
        following,
        hasMoreFollowing,
        followingPage,
        friends,
        hasMoreFriends,
        friendsPage,
        pendingRequests,
        hasMorePendingRequests,
        pendingRequestsPage,
        stats,
        relationships,
        status,
        friendsStatus,
        requestsStatus,
        error,
        isLoading,
        isRefreshing,
        isLoadingMore,
        pendingActions,
      ];
}

enum FriendsStatus {
  initial,
  loading,
  loadingMore,
  refreshing,
  success,
  error,
}
