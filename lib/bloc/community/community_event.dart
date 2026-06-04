part of 'community_bloc.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

class LoadCommunities extends CommunityEvent {
  const LoadCommunities();
}

class SearchCommunities extends CommunityEvent {
  final String query;
  final String category;

  const SearchCommunities({
    required this.query,
    required this.category,
  });

  @override
  List<Object?> get props => [query, category];
}

class CreateCommunity extends CommunityEvent {
  final String name;
  final String description;
  final String category;
  final bool isPrivate;

  const CreateCommunity({
    required this.name,
    required this.description,
    required this.category,
    required this.isPrivate,
  });

  @override
  List<Object?> get props => [name, description, category, isPrivate];
}

class SelectCommunity extends CommunityEvent {
  final int communityId;

  const SelectCommunity(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class JoinCommunity extends CommunityEvent {
  final int communityId;

  const JoinCommunity(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class LeaveCommunity extends CommunityEvent {
  final int communityId;

  const LeaveCommunity(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class CreateCommunityDiscussion extends CommunityEvent {
  final int communityId;
  final String content;

  const CreateCommunityDiscussion({
    required this.communityId,
    required this.content,
  });

  @override
  List<Object?> get props => [communityId, content];
}

class CreateCommunityGroup extends CommunityEvent {
  final int communityId;
  final String name;
  final String description;
  final bool isPrivate;

  const CreateCommunityGroup({
    required this.communityId,
    required this.name,
    required this.description,
    required this.isPrivate,
  });

  @override
  List<Object?> get props => [communityId, name, description, isPrivate];
}

class JoinCommunityGroup extends CommunityEvent {
  final int groupId;

  const JoinCommunityGroup(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class LoadCommunityInvitations extends CommunityEvent {
  const LoadCommunityInvitations();
}

class ClearCommunityError extends CommunityEvent {
  const ClearCommunityError();
}
