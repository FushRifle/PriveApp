import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:clique/core/models/community_model.dart';
import 'package:clique/core/services/community/community_service.dart';

part 'community_event.dart';
part 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityService _service = CommunityService();

  int _listRequestId = 0;
  int _detailRequestId = 0;

  CommunityBloc() : super(const CommunityState()) {
    on<LoadCommunities>(_onLoadCommunities);
    on<SearchCommunities>(_onSearchCommunities);
    on<CreateCommunity>(_onCreateCommunity);
    on<SelectCommunity>(_onSelectCommunity);
    on<JoinCommunity>(_onJoinCommunity);
    on<LeaveCommunity>(_onLeaveCommunity);
    on<CreateCommunityDiscussion>(_onCreateDiscussion);
    on<CreateCommunityGroup>(_onCreateGroup);
    on<JoinCommunityGroup>(_onJoinGroup);
    on<LoadCommunityInvitations>(_onLoadInvitations);
    on<ClearCommunityError>(_onClearError);
  }

  void setAuthToken(String token) {
    _service.setAuthToken(token);
  }

  Future<void> _onLoadCommunities(
    LoadCommunities event,
    Emitter<CommunityState> emit,
  ) async {
    final requestId = ++_listRequestId;

    emit(state.copyWith(status: CommunityStatus.loading, clearError: true));
    try {
      final communities = await _service.getCommunities(
        query: state.query,
        category: state.category,
      );
      final invitations = await _service.getInvitations();

      if (requestId != _listRequestId) return;

      emit(state.copyWith(
        status: CommunityStatus.success,
        communities: communities,
        invitations: invitations,
        clearError: true,
      ));
    } catch (e) {
      if (requestId != _listRequestId) return;
      emit(state.copyWith(status: CommunityStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSearchCommunities(
    SearchCommunities event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(
      query: event.query,
      category: event.category,
      status: CommunityStatus.loading,
      clearError: true,
    ));
    add(const LoadCommunities());
  }

  Future<void> _onCreateCommunity(
    CreateCommunity event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(actionStatus: CommunityActionStatus.loading));
    try {
      final community = await _service.createCommunity(
        name: event.name,
        description: event.description,
        category: event.category,
        isPrivate: event.isPrivate,
      );
      emit(state.copyWith(
        actionStatus: CommunityActionStatus.success,
        communities: [community, ...state.communities],
        selectedCommunity: community,
        clearError: true,
      ));
      add(SelectCommunity(community.id));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: CommunityActionStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSelectCommunity(
    SelectCommunity event,
    Emitter<CommunityState> emit,
  ) async {
    final requestId = ++_detailRequestId;

    emit(state.copyWith(detailStatus: CommunityStatus.loading));
    try {
      final community = await _service.getCommunity(event.communityId);
      final members = community.isMember
          ? await _service.getCommunityMembers(event.communityId)
          : <CommunityMemberModel>[];
      final groups = community.isMember
          ? await _service.getGroups(event.communityId)
          : <CommunityGroupModel>[];
      final posts = community.isMember
          ? await _service.getCommunityPosts(event.communityId)
          : <DiscussionPostModel>[];

      if (requestId != _detailRequestId) return;

      emit(state.copyWith(
        detailStatus: CommunityStatus.success,
        selectedCommunity: community,
        members: members,
        groups: groups,
        posts: posts,
        clearError: true,
      ));
    } catch (e) {
      if (requestId != _detailRequestId) return;
      emit(state.copyWith(
        detailStatus: CommunityStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onJoinCommunity(
    JoinCommunity event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(actionStatus: CommunityActionStatus.loading));
    try {
      await _service.joinCommunity(event.communityId);
      emit(state.copyWith(
        actionStatus: CommunityActionStatus.success,
        communities: state.communities.map((community) {
          if (community.id != event.communityId) return community;
          return community.copyWith(
            isMember: true,
            role: 'member',
            memberCount: community.memberCount + 1,
          );
        }).toList(),
      ));
      add(SelectCommunity(event.communityId));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: CommunityActionStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLeaveCommunity(
    LeaveCommunity event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(actionStatus: CommunityActionStatus.loading));
    try {
      await _service.leaveCommunity(event.communityId);
      emit(state.copyWith(
        actionStatus: CommunityActionStatus.success,
        selectedCommunity: state.selectedCommunity?.copyWith(
          isMember: false,
          role: '',
          memberCount:
              (state.selectedCommunity!.memberCount - 1).clamp(0, 1 << 31),
        ),
        groups: const [],
        members: const [],
        posts: const [],
      ));
      add(const LoadCommunities());
    } catch (e) {
      emit(state.copyWith(
        actionStatus: CommunityActionStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCreateDiscussion(
    CreateCommunityDiscussion event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(actionStatus: CommunityActionStatus.loading));
    try {
      final post = await _service.createCommunityPost(
        communityId: event.communityId,
        content: event.content,
      );
      emit(state.copyWith(
        actionStatus: CommunityActionStatus.success,
        posts: [post, ...state.posts],
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: CommunityActionStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCreateGroup(
    CreateCommunityGroup event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(actionStatus: CommunityActionStatus.loading));
    try {
      final group = await _service.createGroup(
        communityId: event.communityId,
        name: event.name,
        description: event.description,
        isPrivate: event.isPrivate,
      );
      emit(state.copyWith(
        actionStatus: CommunityActionStatus.success,
        groups: [group, ...state.groups],
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: CommunityActionStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onJoinGroup(
    JoinCommunityGroup event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(actionStatus: CommunityActionStatus.loading));
    try {
      await _service.joinGroup(event.groupId);
      emit(state.copyWith(actionStatus: CommunityActionStatus.success));
      if (state.selectedCommunity != null) {
        add(SelectCommunity(state.selectedCommunity!.id));
      }
    } catch (e) {
      emit(state.copyWith(
        actionStatus: CommunityActionStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadInvitations(
    LoadCommunityInvitations event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      final invitations = await _service.getInvitations();
      emit(state.copyWith(invitations: invitations, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onClearError(
    ClearCommunityError event,
    Emitter<CommunityState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }
}
