import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/data/services/friends/friends_service.dart';

part 'friends_event.dart';
part 'friends_state.dart';

class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  final FriendsService _friendsService = FriendsService();
  static const int _pageSize = 20;

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
    emit(state.copyWith(
      followersStatus: FollowersStatus.loading,
      followers: event.page == 1 ? [] : state.followers,
      error: null,
    ));

    try {
      final response = await _friendsService.getFollowers(
        page: event.page,
        pageSize: event.pageSize,
      );

      final newFollowers = event.page == 1
          ? response.data
          : [...state.followers, ...response.data];

      emit(state.copyWith(
        followersStatus: FollowersStatus.success,
        followers: newFollowers,
        followersPage: event.page,
        followersHasMore: response.data.length >= event.pageSize,
        followersTotal: response.total,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        followersStatus: FollowersStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadFollowing(
    LoadFollowing event,
    Emitter<FriendsState> emit,
  ) async {
    emit(state.copyWith(
      followingStatus: FollowingStatus.loading,
      following: event.page == 1 ? [] : state.following,
      error: null,
    ));

    try {
      final response = await _friendsService.getFollowing(
        page: event.page,
        pageSize: event.pageSize,
      );

      final newFollowing = event.page == 1
          ? response.data
          : [...state.following, ...response.data];

      emit(state.copyWith(
        followingStatus: FollowingStatus.success,
        following: newFollowing,
        followingPage: event.page,
        followingHasMore: response.data.length >= event.pageSize,
        followingTotal: response.total,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        followingStatus: FollowingStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadFriends(
    LoadFriends event,
    Emitter<FriendsState> emit,
  ) async {
    emit(state.copyWith(
      friendsStatus: FriendsStatus.loading,
      friends: event.page == 1 ? [] : state.friends,
      error: null,
    ));

    try {
      final response = await _friendsService.getFriends(
        page: event.page,
        pageSize: event.pageSize,
      );

      final newFriends = event.page == 1
          ? response.data
          : [...state.friends, ...response.data];

      emit(state.copyWith(
        friendsStatus: FriendsStatus.success,
        friends: newFriends,
        friendsPage: event.page,
        friendsHasMore: response.data.length >= event.pageSize,
        friendsTotal: response.total,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        friendsStatus: FriendsStatus.error,
        error: e.toString(),
      ));
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
      emit(state.copyWith(stats: stats));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onClearFriendsError(
    ClearFriendsError event,
    Emitter<FriendsState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  void _onResetFriendsState(
    ResetFriendsState event,
    Emitter<FriendsState> emit,
  ) {
    emit(const FriendsState());
  }
}
