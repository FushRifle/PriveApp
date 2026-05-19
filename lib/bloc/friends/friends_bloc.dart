import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cirqle/data/services/socials/friends_service.dart';

part 'friends_event.dart';
part 'friends_state.dart';

class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  final FriendsService _friendsService = FriendsService();
  static const int _pageSize = 20;

  FriendsBloc() : super(const FriendsState()) {
    on<FollowUser>(_onFollowUser);
    on<UnfollowUser>(_onUnfollowUser);
    on<LoadFollowers>(_onLoadFollowers);
    on<LoadMoreFollowers>(_onLoadMoreFollowers);
    on<RefreshFollowers>(_onRefreshFollowers);
    on<LoadFollowing>(_onLoadFollowing);
    on<LoadMoreFollowing>(_onLoadMoreFollowing);
    on<RefreshFollowing>(_onRefreshFollowing);
    on<LoadFriends>(_onLoadFriends);
    on<LoadMoreFriends>(_onLoadMoreFriends);
    on<RefreshFriends>(_onRefreshFriends);
    on<LoadFollowStats>(_onLoadFollowStats);
    on<CheckRelationship>(_onCheckRelationship);
    on<SendFriendRequest>(_onSendFriendRequest);
    on<LoadPendingRequests>(_onLoadPendingRequests);
    on<LoadMorePendingRequests>(_onLoadMorePendingRequests);
    on<RefreshPendingRequests>(_onRefreshPendingRequests);
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<RejectFriendRequest>(_onRejectFriendRequest);
    on<ClearFriendsError>(_onClearFriendsError);
    on<ResetFriendsState>(_onResetFriendsState);
  }

  Future<void> _onFollowUser(
    FollowUser event,
    Emitter<FriendsState> emit,
  ) async {
    if (state.pendingActions.contains(event.userId)) return;

    final updatedPending = Set<int>.from(state.pendingActions)
      ..add(event.userId);
    emit(state.copyWith(pendingActions: updatedPending));

    try {
      await _friendsService.followUser(event.userId);

      // Update relationship
      final relationship = Relationship(isFollowing: true);
      final updatedRelationships =
          Map<int, Relationship>.from(state.relationships)
            ..[event.userId] = relationship;

      emit(state.copyWith(
        relationships: updatedRelationships,
        pendingActions: state.pendingActions..remove(event.userId),
      ));

      // Refresh stats and following list
      add(LoadFollowStats());
      add(RefreshFollowing());
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        pendingActions: state.pendingActions..remove(event.userId),
      ));
    }
  }

  Future<void> _onUnfollowUser(
    UnfollowUser event,
    Emitter<FriendsState> emit,
  ) async {
    if (state.pendingActions.contains(event.userId)) return;

    final updatedPending = Set<int>.from(state.pendingActions)
      ..add(event.userId);
    emit(state.copyWith(pendingActions: updatedPending));

    try {
      await _friendsService.unfollowUser(event.userId);

      // Update relationship
      final relationship = Relationship(isFollowing: false);
      final updatedRelationships =
          Map<int, Relationship>.from(state.relationships)
            ..[event.userId] = relationship;

      emit(state.copyWith(
        relationships: updatedRelationships,
        pendingActions: state.pendingActions..remove(event.userId),
      ));

      // Refresh stats and following list
      add(LoadFollowStats());
      add(RefreshFollowing());
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        pendingActions: state.pendingActions..remove(event.userId),
      ));
    }
  }

  Future<void> _onLoadFollowers(
    LoadFollowers event,
    Emitter<FriendsState> emit,
  ) async {
    if (state.followers.isEmpty) {
      emit(state.copyWith(
        status: FriendsStatus.loading,
        isLoading: true,
      ));
    }

    try {
      final result = await _friendsService.getFollowers(
        page: event.page,
        pageSize: _pageSize,
      );

      final followers = (result['followers'] as List?)
              ?.map((f) => FriendUser.fromJson(f))
              .toList() ??
          [];

      emit(state.copyWith(
        followers: followers,
        hasMoreFollowers: followers.length >= _pageSize,
        followersPage: event.page,
        status: FriendsStatus.success,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FriendsStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreFollowers(
    LoadMoreFollowers event,
    Emitter<FriendsState> emit,
  ) async {
    if (!state.hasMoreFollowers || state.isLoadingMore) return;

    emit(state.copyWith(
      status: FriendsStatus.loadingMore,
      isLoadingMore: true,
    ));

    try {
      final nextPage = state.followersPage + 1;
      final result = await _friendsService.getFollowers(
        page: nextPage,
        pageSize: _pageSize,
      );

      final newFollowers = (result['followers'] as List?)
              ?.map((f) => FriendUser.fromJson(f))
              .toList() ??
          [];

      final updatedFollowers = [...state.followers, ...newFollowers];

      emit(state.copyWith(
        followers: updatedFollowers,
        hasMoreFollowers: newFollowers.length >= _pageSize,
        followersPage: nextPage,
        status: FriendsStatus.success,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FriendsStatus.error,
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshFollowers(
    RefreshFollowers event,
    Emitter<FriendsState> emit,
  ) async {
    emit(state.copyWith(
      status: FriendsStatus.refreshing,
      isRefreshing: true,
    ));

    try {
      final result =
          await _friendsService.getFollowers(page: 1, pageSize: _pageSize);

      final followers = (result['followers'] as List?)
              ?.map((f) => FriendUser.fromJson(f))
              .toList() ??
          [];

      emit(state.copyWith(
        followers: followers,
        hasMoreFollowers: followers.length >= _pageSize,
        followersPage: 1,
        status: FriendsStatus.success,
        isRefreshing: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FriendsStatus.error,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadFollowing(
    LoadFollowing event,
    Emitter<FriendsState> emit,
  ) async {
    if (state.following.isEmpty) {
      emit(state.copyWith(
        friendsStatus: FriendsStatus.loading,
        isLoading: true,
      ));
    }

    try {
      final result = await _friendsService.getFollowing(
        page: event.page,
        pageSize: _pageSize,
      );

      final following = (result['following'] as List?)
              ?.map((f) => FriendUser.fromJson(f))
              .toList() ??
          [];

      emit(state.copyWith(
        following: following,
        hasMoreFollowing: following.length >= _pageSize,
        followingPage: event.page,
        friendsStatus: FriendsStatus.success,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        friendsStatus: FriendsStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreFollowing(
    LoadMoreFollowing event,
    Emitter<FriendsState> emit,
  ) async {
    if (!state.hasMoreFollowing || state.isLoadingMore) return;

    emit(state.copyWith(
      friendsStatus: FriendsStatus.loadingMore,
      isLoadingMore: true,
    ));

    try {
      final nextPage = state.followingPage + 1;
      final result = await _friendsService.getFollowing(
        page: nextPage,
        pageSize: _pageSize,
      );

      final newFollowing = (result['following'] as List?)
              ?.map((f) => FriendUser.fromJson(f))
              .toList() ??
          [];

      final updatedFollowing = [...state.following, ...newFollowing];

      emit(state.copyWith(
        following: updatedFollowing,
        hasMoreFollowing: newFollowing.length >= _pageSize,
        followingPage: nextPage,
        friendsStatus: FriendsStatus.success,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        friendsStatus: FriendsStatus.error,
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshFollowing(
    RefreshFollowing event,
    Emitter<FriendsState> emit,
  ) async {
    emit(state.copyWith(
      friendsStatus: FriendsStatus.refreshing,
      isRefreshing: true,
    ));

    try {
      final result =
          await _friendsService.getFollowing(page: 1, pageSize: _pageSize);

      final following = (result['following'] as List?)
              ?.map((f) => FriendUser.fromJson(f))
              .toList() ??
          [];

      emit(state.copyWith(
        following: following,
        hasMoreFollowing: following.length >= _pageSize,
        followingPage: 1,
        friendsStatus: FriendsStatus.success,
        isRefreshing: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        friendsStatus: FriendsStatus.error,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadFriends(
    LoadFriends event,
    Emitter<FriendsState> emit,
  ) async {
    if (state.friends.isEmpty) {
      emit(state.copyWith(
        friendsStatus: FriendsStatus.loading,
        isLoading: true,
      ));
    }

    try {
      final result = await _friendsService.getFriends(
        page: event.page,
        pageSize: _pageSize,
      );

      final friends = (result['friends'] as List?)
              ?.map((f) => FriendUser.fromJson(f))
              .toList() ??
          [];

      emit(state.copyWith(
        friends: friends,
        hasMoreFriends: friends.length >= _pageSize,
        friendsPage: event.page,
        friendsStatus: FriendsStatus.success,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        friendsStatus: FriendsStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreFriends(
    LoadMoreFriends event,
    Emitter<FriendsState> emit,
  ) async {
    if (!state.hasMoreFriends || state.isLoadingMore) return;

    emit(state.copyWith(
      friendsStatus: FriendsStatus.loadingMore,
      isLoadingMore: true,
    ));

    try {
      final nextPage = state.friendsPage + 1;
      final result = await _friendsService.getFriends(
        page: nextPage,
        pageSize: _pageSize,
      );

      final newFriends = (result['friends'] as List?)
              ?.map((f) => FriendUser.fromJson(f))
              .toList() ??
          [];

      final updatedFriends = [...state.friends, ...newFriends];

      emit(state.copyWith(
        friends: updatedFriends,
        hasMoreFriends: newFriends.length >= _pageSize,
        friendsPage: nextPage,
        friendsStatus: FriendsStatus.success,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        friendsStatus: FriendsStatus.error,
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshFriends(
    RefreshFriends event,
    Emitter<FriendsState> emit,
  ) async {
    emit(state.copyWith(
      friendsStatus: FriendsStatus.refreshing,
      isRefreshing: true,
    ));

    try {
      final result =
          await _friendsService.getFriends(page: 1, pageSize: _pageSize);

      final friends = (result['friends'] as List?)
              ?.map((f) => FriendUser.fromJson(f))
              .toList() ??
          [];

      emit(state.copyWith(
        friends: friends,
        hasMoreFriends: friends.length >= _pageSize,
        friendsPage: 1,
        friendsStatus: FriendsStatus.success,
        isRefreshing: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        friendsStatus: FriendsStatus.error,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadFollowStats(
    LoadFollowStats event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      final statsData = await _friendsService.getFollowStats();
      final stats = FollowStats.fromJson(statsData);

      emit(state.copyWith(stats: stats));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onCheckRelationship(
    CheckRelationship event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      final relationshipData =
          await _friendsService.checkRelationship(event.userId);
      final relationship = Relationship.fromJson(relationshipData);

      final updatedRelationships =
          Map<int, Relationship>.from(state.relationships)
            ..[event.userId] = relationship;

      emit(state.copyWith(relationships: updatedRelationships));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSendFriendRequest(
    SendFriendRequest event,
    Emitter<FriendsState> emit,
  ) async {
    if (state.pendingActions.contains(event.userId)) return;

    final updatedPending = Set<int>.from(state.pendingActions)
      ..add(event.userId);
    emit(state.copyWith(pendingActions: updatedPending));

    try {
      await _friendsService.sendFriendRequest(event.userId,
          message: event.message);

      // Update relationship
      final relationship = Relationship(hasPendingRequest: true);
      final updatedRelationships =
          Map<int, Relationship>.from(state.relationships)
            ..[event.userId] = relationship;

      emit(state.copyWith(
        relationships: updatedRelationships,
        pendingActions: state.pendingActions..remove(event.userId),
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        pendingActions: state.pendingActions..remove(event.userId),
      ));
    }
  }

  Future<void> _onLoadPendingRequests(
    LoadPendingRequests event,
    Emitter<FriendsState> emit,
  ) async {
    if (state.pendingRequests.isEmpty) {
      emit(state.copyWith(
        requestsStatus: FriendsStatus.loading,
        isLoading: true,
      ));
    }

    try {
      final result = await _friendsService.getPendingRequests(
        page: event.page,
        pageSize: _pageSize,
      );

      final requests = (result['requests'] as List?)
              ?.map((r) => FriendRequest.fromJson(r))
              .toList() ??
          [];

      emit(state.copyWith(
        pendingRequests: requests,
        hasMorePendingRequests: requests.length >= _pageSize,
        pendingRequestsPage: event.page,
        requestsStatus: FriendsStatus.success,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        requestsStatus: FriendsStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMorePendingRequests(
    LoadMorePendingRequests event,
    Emitter<FriendsState> emit,
  ) async {
    if (!state.hasMorePendingRequests || state.isLoadingMore) return;

    emit(state.copyWith(
      requestsStatus: FriendsStatus.loadingMore,
      isLoadingMore: true,
    ));

    try {
      final nextPage = state.pendingRequestsPage + 1;
      final result = await _friendsService.getPendingRequests(
        page: nextPage,
        pageSize: _pageSize,
      );

      final newRequests = (result['requests'] as List?)
              ?.map((r) => FriendRequest.fromJson(r))
              .toList() ??
          [];

      final updatedRequests = [...state.pendingRequests, ...newRequests];

      emit(state.copyWith(
        pendingRequests: updatedRequests,
        hasMorePendingRequests: newRequests.length >= _pageSize,
        pendingRequestsPage: nextPage,
        requestsStatus: FriendsStatus.success,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        requestsStatus: FriendsStatus.error,
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshPendingRequests(
    RefreshPendingRequests event,
    Emitter<FriendsState> emit,
  ) async {
    emit(state.copyWith(
      requestsStatus: FriendsStatus.refreshing,
      isRefreshing: true,
    ));

    try {
      final result = await _friendsService.getPendingRequests(
          page: 1, pageSize: _pageSize);

      final requests = (result['requests'] as List?)
              ?.map((r) => FriendRequest.fromJson(r))
              .toList() ??
          [];

      emit(state.copyWith(
        pendingRequests: requests,
        hasMorePendingRequests: requests.length >= _pageSize,
        pendingRequestsPage: 1,
        requestsStatus: FriendsStatus.success,
        isRefreshing: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        requestsStatus: FriendsStatus.error,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequest event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      // Optimistic update - remove request
      final updatedRequests =
          state.pendingRequests.where((r) => r.id != event.requestId).toList();

      emit(state.copyWith(
        pendingRequests: updatedRequests,
      ));

      await _friendsService.respondToRequest(event.requestId, 'accept');

      // Refresh stats, friends, and relationships
      add(LoadFollowStats());
      add(RefreshFriends());
    } catch (e) {
      // Refresh to restore state
      add(RefreshPendingRequests());
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRejectFriendRequest(
    RejectFriendRequest event,
    Emitter<FriendsState> emit,
  ) async {
    try {
      // Optimistic update - remove request
      final updatedRequests =
          state.pendingRequests.where((r) => r.id != event.requestId).toList();

      emit(state.copyWith(
        pendingRequests: updatedRequests,
      ));

      await _friendsService.respondToRequest(event.requestId, 'reject');
    } catch (e) {
      // Refresh to restore state
      add(RefreshPendingRequests());
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
