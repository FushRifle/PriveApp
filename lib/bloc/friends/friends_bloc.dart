import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/core/services/friends/friends_service.dart';

part 'friends_event.dart';
part 'friends_state.dart';

class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  final FriendsService _friendsService = FriendsService();

  int _followersRequestId = 0;
  int _followingRequestId = 0;
  int _friendsRequestId = 0;
  bool _loadingFollowers = false;
  bool _loadingFollowing = false;
  bool _loadingFriends = false;

  FriendsBloc() : super(const FriendsState()) {
    on<LoadFollowers>(_onLoadFollowers);
    on<LoadFollowing>(_onLoadFollowing);
    on<LoadFriends>(_onLoadFriends);
    on<FollowUser>(_onFollowUser);
    on<UnfollowUser>(_onUnfollowUser);
    on<LoadFollowStats>(_onLoadFollowStats);
    on<LoadMoreFollowers>(_onLoadMoreFollowers);
    on<LoadMoreFollowing>(_onLoadMoreFollowing);
    on<ClearFriendsError>(_onClearFriendsError);
    on<ResetFriendsState>(_onResetFriendsState);
  }

  void setAuthToken(String token) {
    _friendsService.setAuthToken(token);
  }

  void clearAuthToken() {
    _friendsService.clearAuthToken();
  }

  Future<void> _onLoadFollowers(
    LoadFollowers event,
    Emitter<FriendsState> emit,
  ) async {
    if (_loadingFollowers) return;

    _loadingFollowers = true;
    final requestId = ++_followersRequestId;

    emit(state.copyWith(
      followersStatus: event.page == 1
          ? FollowersStatus.loading
          : FollowersStatus.loadingMore,
      followers: event.page == 1 ? [] : state.followers,
      clearError: true,
    ));

    try {
      final response = await _friendsService.getFollowers(
        page: event.page,
        pageSize: event.pageSize,
      );

      if (requestId != _followersRequestId) return;

      final newFollowers = _dedupeUsers(event.page == 1
          ? response.data
          : [...state.followers, ...response.data]);

      emit(state.copyWith(
        followersStatus: FollowersStatus.success,
        followers: newFollowers,
        followersPage: event.page,
        followersHasMore: response.data.length >= event.pageSize,
        followersTotal: response.total,
        clearError: true,
      ));
    } catch (e) {
      if (requestId != _followersRequestId) return;
      emit(state.copyWith(
        followersStatus: FollowersStatus.error,
        error: e.toString(),
      ));
    } finally {
      if (requestId == _followersRequestId) {
        _loadingFollowers = false;
      }
    }
  }

  Future<void> _onLoadFollowing(
    LoadFollowing event,
    Emitter<FriendsState> emit,
  ) async {
    if (_loadingFollowing) return;

    _loadingFollowing = true;
    final requestId = ++_followingRequestId;

    emit(state.copyWith(
      followingStatus: event.page == 1
          ? FollowingStatus.loading
          : FollowingStatus.loadingMore,
      following: event.page == 1 ? [] : state.following,
      clearError: true,
    ));

    try {
      final response = await _friendsService.getFollowing(
        page: event.page,
        pageSize: event.pageSize,
      );

      if (requestId != _followingRequestId) return;

      final newFollowing = _dedupeUsers(event.page == 1
          ? response.data
          : [...state.following, ...response.data]);

      emit(state.copyWith(
        followingStatus: FollowingStatus.success,
        following: newFollowing,
        followingPage: event.page,
        followingHasMore: response.data.length >= event.pageSize,
        followingTotal: response.total,
        clearError: true,
      ));
    } catch (e) {
      if (requestId != _followingRequestId) return;
      emit(state.copyWith(
        followingStatus: FollowingStatus.error,
        error: e.toString(),
      ));
    } finally {
      if (requestId == _followingRequestId) {
        _loadingFollowing = false;
      }
    }
  }

  Future<void> _onLoadFriends(
    LoadFriends event,
    Emitter<FriendsState> emit,
  ) async {
    if (_loadingFriends) return;

    _loadingFriends = true;
    final requestId = ++_friendsRequestId;

    emit(state.copyWith(
      friendsStatus: FriendsStatus.loading,
      friends: event.page == 1 ? [] : state.friends,
      clearError: true,
    ));

    try {
      final response = await _friendsService.getFriends(
        page: event.page,
        pageSize: event.pageSize,
      );

      if (requestId != _friendsRequestId) return;

      final newFriends = _dedupeUsers(event.page == 1
          ? response.data
          : [...state.friends, ...response.data]);

      emit(state.copyWith(
        friendsStatus: FriendsStatus.success,
        friends: newFriends,
        friendsPage: event.page,
        friendsHasMore: response.data.length >= event.pageSize,
        friendsTotal: response.total,
        clearError: true,
      ));
    } catch (e) {
      if (requestId != _friendsRequestId) return;
      emit(state.copyWith(
        friendsStatus: FriendsStatus.error,
        error: e.toString(),
      ));
    } finally {
      if (requestId == _friendsRequestId) {
        _loadingFriends = false;
      }
    }
  }

  Future<void> _onLoadMoreFollowers(
    LoadMoreFollowers event,
    Emitter<FriendsState> emit,
  ) async {
    if (!state.followersHasMore ||
        state.followersStatus == FollowersStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(
      followersStatus: FollowersStatus.loadingMore,
    ));

    final nextPage = state.followersPage + 1;
    add(LoadFollowers(page: nextPage));
  }

  Future<void> _onLoadMoreFollowing(
    LoadMoreFollowing event,
    Emitter<FriendsState> emit,
  ) async {
    if (!state.followingHasMore ||
        state.followingStatus == FollowingStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(
      followingStatus: FollowingStatus.loadingMore,
    ));

    final nextPage = state.followingPage + 1;
    add(LoadFollowing(page: nextPage));
  }

  Future<void> _onFollowUser(
    FollowUser event,
    Emitter<FriendsState> emit,
  ) async {
    // Optimistic update in followers list
    final updatedFollowers = state.followers.map((user) {
      if (user.id == event.userId) {
        return FriendUser(
          id: user.id,
          name: user.name,
          username: user.username,
          avatar: user.avatar,
          isVerified: user.isVerified,
          bio: user.bio,
          location: user.location,
          isFollowing: true,
          isFollowedBy: user.isFollowedBy,
        );
      }
      return user;
    }).toList();

    // Optimistic update in following list
    final updatedFollowing = state.following.map((user) {
      if (user.id == event.userId) {
        return FriendUser(
          id: user.id,
          name: user.name,
          username: user.username,
          avatar: user.avatar,
          isVerified: user.isVerified,
          bio: user.bio,
          location: user.location,
          isFollowing: true,
          isFollowedBy: user.isFollowedBy,
        );
      }
      return user;
    }).toList();

    emit(state.copyWith(
      followers: updatedFollowers,
      following: updatedFollowing,
      clearError: true,
    ));

    try {
      await _friendsService.followUser(event.userId);
      add(LoadFollowStats());
    } catch (e) {
      // Rollback on error - reload data
      add(LoadFollowers(page: state.followersPage));
      add(LoadFollowing(page: state.followingPage));
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUnfollowUser(
    UnfollowUser event,
    Emitter<FriendsState> emit,
  ) async {
    // Optimistic update
    final updatedFollowers = state.followers.map((user) {
      if (user.id == event.userId) {
        return FriendUser(
          id: user.id,
          name: user.name,
          username: user.username,
          avatar: user.avatar,
          isVerified: user.isVerified,
          bio: user.bio,
          location: user.location,
          isFollowing: false,
          isFollowedBy: user.isFollowedBy,
        );
      }
      return user;
    }).toList();

    final updatedFollowing = state.following.map((user) {
      if (user.id == event.userId) {
        return FriendUser(
          id: user.id,
          name: user.name,
          username: user.username,
          avatar: user.avatar,
          isVerified: user.isVerified,
          bio: user.bio,
          location: user.location,
          isFollowing: false,
          isFollowedBy: user.isFollowedBy,
        );
      }
      return user;
    }).toList();

    emit(state.copyWith(
      followers: updatedFollowers,
      following: updatedFollowing,
      clearError: true,
    ));

    try {
      await _friendsService.unfollowUser(event.userId);
      add(LoadFollowStats());
    } catch (e) {
      add(LoadFollowers(page: state.followersPage));
      add(LoadFollowing(page: state.followingPage));
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onLoadFollowStats(
    LoadFollowStats event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      final stats = await _friendsService.getFollowStats();
      emit(state.copyWith(stats: stats, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onClearFriendsError(
    ClearFriendsError event,
    Emitter<FriendsState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  void _onResetFriendsState(
    ResetFriendsState event,
    Emitter<FriendsState> emit,
  ) {
    emit(const FriendsState());
  }

  List<FriendUser> _dedupeUsers(List<FriendUser> users) {
    final seen = <int>{};
    final deduped = <FriendUser>[];

    for (final user in users) {
      if (seen.add(user.id)) {
        deduped.add(user);
      }
    }

    return deduped;
  }
}
