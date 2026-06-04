part of 'community_bloc.dart';

enum CommunityStatus {
  initial,
  loading,
  success,
  error,
}

enum CommunityActionStatus {
  initial,
  loading,
  success,
  error,
}

class CommunityState extends Equatable {
  final CommunityStatus status;
  final CommunityStatus detailStatus;
  final CommunityActionStatus actionStatus;
  final List<CommunityModel> communities;
  final List<CommunityGroupModel> groups;
  final List<DiscussionPostModel> posts;
  final List<GroupInvitationModel> invitations;
  final CommunityModel? selectedCommunity;
  final String query;
  final String category;
  final String? error;

  const CommunityState({
    this.status = CommunityStatus.initial,
    this.detailStatus = CommunityStatus.initial,
    this.actionStatus = CommunityActionStatus.initial,
    this.communities = const [],
    this.groups = const [],
    this.posts = const [],
    this.invitations = const [],
    this.selectedCommunity,
    this.query = '',
    this.category = '',
    this.error,
  });

  CommunityState copyWith({
    CommunityStatus? status,
    CommunityStatus? detailStatus,
    CommunityActionStatus? actionStatus,
    List<CommunityModel>? communities,
    List<CommunityGroupModel>? groups,
    List<DiscussionPostModel>? posts,
    List<GroupInvitationModel>? invitations,
    CommunityModel? selectedCommunity,
    String? query,
    String? category,
    String? error,
    bool clearError = false,
  }) {
    return CommunityState(
      status: status ?? this.status,
      detailStatus: detailStatus ?? this.detailStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      communities: communities ?? this.communities,
      groups: groups ?? this.groups,
      posts: posts ?? this.posts,
      invitations: invitations ?? this.invitations,
      selectedCommunity: selectedCommunity ?? this.selectedCommunity,
      query: query ?? this.query,
      category: category ?? this.category,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        detailStatus,
        actionStatus,
        communities,
        groups,
        posts,
        invitations,
        selectedCommunity,
        query,
        category,
        error,
      ];
}
