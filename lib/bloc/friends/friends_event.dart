part of 'friends_bloc.dart';

abstract class FriendsEvent extends Equatable {
  const FriendsEvent();

  @override
  List<Object?> get props => [];
}

// Follow user
class FollowUser extends FriendsEvent {
  final int userId;

  const FollowUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Unfollow user
class UnfollowUser extends FriendsEvent {
  final int userId;

  const UnfollowUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Load followers
class LoadFollowers extends FriendsEvent {
  final int page;

  const LoadFollowers({this.page = 1});

  @override
  List<Object?> get props => [page];
}

// Load more followers
class LoadMoreFollowers extends FriendsEvent {}

// Refresh followers
class RefreshFollowers extends FriendsEvent {}

// Load following
class LoadFollowing extends FriendsEvent {
  final int page;

  const LoadFollowing({this.page = 1});

  @override
  List<Object?> get props => [page];
}

// Load more following
class LoadMoreFollowing extends FriendsEvent {}

// Refresh following
class RefreshFollowing extends FriendsEvent {}

// Load friends (mutual)
class LoadFriends extends FriendsEvent {
  final int page;

  const LoadFriends({this.page = 1});

  @override
  List<Object?> get props => [page];
}

// Load more friends
class LoadMoreFriends extends FriendsEvent {}

// Refresh friends
class RefreshFriends extends FriendsEvent {}

// Load follow stats
class LoadFollowStats extends FriendsEvent {}

// Check relationship with user
class CheckRelationship extends FriendsEvent {
  final int userId;

  const CheckRelationship({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Send friend request
class SendFriendRequest extends FriendsEvent {
  final int userId;
  final String? message;

  const SendFriendRequest({
    required this.userId,
    this.message,
  });

  @override
  List<Object?> get props => [userId, message];
}

// Load pending requests
class LoadPendingRequests extends FriendsEvent {
  final int page;

  const LoadPendingRequests({this.page = 1});

  @override
  List<Object?> get props => [page];
}

// Load more pending requests
class LoadMorePendingRequests extends FriendsEvent {}

// Refresh pending requests
class RefreshPendingRequests extends FriendsEvent {}

// Accept friend request
class AcceptFriendRequest extends FriendsEvent {
  final int requestId;

  const AcceptFriendRequest({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

// Reject friend request
class RejectFriendRequest extends FriendsEvent {
  final int requestId;

  const RejectFriendRequest({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

// Clear friends error
class ClearFriendsError extends FriendsEvent {}

// Reset friends state
class ResetFriendsState extends FriendsEvent {}
