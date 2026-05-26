part of 'friends_bloc.dart';

enum FriendsStatus {
  initial,
  loading,
  success,
  error,
}

enum FollowersStatus {
  initial,
  loading,
  success,
  error,
  loadingMore,
}

enum FollowingStatus {
  initial,
  loading,
  success,
  error,
  loadingMore,
}

class FriendsState extends Equatable {
  // Followers
  final FollowersStatus followersStatus;
  final List<FriendUser> followers;
  final int followersPage;
  final bool followersHasMore;
  final int followersTotal;

  // Following
  final FollowingStatus followingStatus;
  final List<FriendUser> following;
  final int followingPage;
  final bool followingHasMore;
  final int followingTotal;

  // Friends (mutual)
  final FriendsStatus friendsStatus;
  final List<FriendUser> friends;
  final int friendsPage;
  final bool friendsHasMore;
  final int friendsTotal;

  // Stats
  final FollowStats? stats;

  // General
  final String? error;

  const FriendsState({
    this.followersStatus = FollowersStatus.initial,
    this.followers = const [],
    this.followersPage = 1,
    this.followersHasMore = true,
    this.followersTotal = 0,
    this.followingStatus = FollowingStatus.initial,
    this.following = const [],
    this.followingPage = 1,
    this.followingHasMore = true,
    this.followingTotal = 0,
    this.friendsStatus = FriendsStatus.initial,
    this.friends = const [],
    this.friendsPage = 1,
    this.friendsHasMore = true,
    this.friendsTotal = 0,
    this.stats,
    this.error,
  });

  FriendsState copyWith({
    FollowersStatus? followersStatus,
    List<FriendUser>? followers,
    int? followersPage,
    bool? followersHasMore,
    int? followersTotal,
    FollowingStatus? followingStatus,
    List<FriendUser>? following,
    int? followingPage,
    bool? followingHasMore,
    int? followingTotal,
    FriendsStatus? friendsStatus,
    List<FriendUser>? friends,
    int? friendsPage,
    bool? friendsHasMore,
    int? friendsTotal,
    FollowStats? stats,
    String? error,
    bool clearError = false,
  }) {
    return FriendsState(
      followersStatus: followersStatus ?? this.followersStatus,
      followers: followers ?? this.followers,
      followersPage: followersPage ?? this.followersPage,
      followersHasMore: followersHasMore ?? this.followersHasMore,
      followersTotal: followersTotal ?? this.followersTotal,
      followingStatus: followingStatus ?? this.followingStatus,
      following: following ?? this.following,
      followingPage: followingPage ?? this.followingPage,
      followingHasMore: followingHasMore ?? this.followingHasMore,
      followingTotal: followingTotal ?? this.followingTotal,
      friendsStatus: friendsStatus ?? this.friendsStatus,
      friends: friends ?? this.friends,
      friendsPage: friendsPage ?? this.friendsPage,
      friendsHasMore: friendsHasMore ?? this.friendsHasMore,
      friendsTotal: friendsTotal ?? this.friendsTotal,
      stats: stats ?? this.stats,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        followersStatus,
        followers,
        followersPage,
        followersHasMore,
        followersTotal,
        followingStatus,
        following,
        followingPage,
        followingHasMore,
        followingTotal,
        friendsStatus,
        friends,
        friendsPage,
        friendsHasMore,
        friendsTotal,
        stats,
        error,
      ];
}
