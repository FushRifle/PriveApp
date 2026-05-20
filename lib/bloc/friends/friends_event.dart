part of 'friends_bloc.dart';

abstract class FriendsEvent extends Equatable {
  const FriendsEvent();

  @override
  List<Object?> get props => [];
}

// Load followers
class LoadFollowers extends FriendsEvent {
  final int page;
  final int pageSize;

  const LoadFollowers({this.page = 1, this.pageSize = 20});

  @override
  List<Object?> get props => [page, pageSize];
}

// Load following
class LoadFollowing extends FriendsEvent {
  final int page;
  final int pageSize;

  const LoadFollowing({this.page = 1, this.pageSize = 20});

  @override
  List<Object?> get props => [page, pageSize];
}

// Load friends (mutual)
class LoadFriends extends FriendsEvent {
  final int page;
  final int pageSize;

  const LoadFriends({this.page = 1, this.pageSize = 20});

  @override
  List<Object?> get props => [page, pageSize];
}

// Follow a user
class FollowUser extends FriendsEvent {
  final int userId;

  const FollowUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Unfollow a user
class UnfollowUser extends FriendsEvent {
  final int userId;

  const UnfollowUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Load follow stats
class LoadFollowStats extends FriendsEvent {}

// Load more followers (pagination)
class LoadMoreFollowers extends FriendsEvent {}

// Load more following (pagination)
class LoadMoreFollowing extends FriendsEvent {}

// Clear error
class ClearFriendsError extends FriendsEvent {}

// Reset state
class ResetFriendsState extends FriendsEvent {}
