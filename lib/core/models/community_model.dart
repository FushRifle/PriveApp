class CommunityModel {
  final int id;
  final int ownerId;
  final String name;
  final String slug;
  final String description;
  final String category;
  final String imageUrl;
  final bool isPrivate;
  final int memberCount;
  final int groupCount;
  final bool isMember;
  final String role;
  final CommunityUser? owner;

  const CommunityModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.slug,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.isPrivate,
    required this.memberCount,
    required this.groupCount,
    required this.isMember,
    required this.role,
    this.owner,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: _readInt(json['id']),
      ownerId: _readInt(json['ownerId'] ?? json['owner_id']),
      name: _readString(json['name'], fallback: 'Community'),
      slug: _readString(json['slug']),
      description: _readString(json['description']),
      category: _readString(json['category']),
      imageUrl: _readString(json['imageUrl'] ?? json['image_url']),
      isPrivate: json['isPrivate'] == true || json['is_private'] == true,
      memberCount: _readInt(json['memberCount'] ?? json['member_count']),
      groupCount: _readInt(json['groupCount'] ?? json['group_count']),
      isMember: json['isMember'] == true || json['is_member'] == true,
      role: _readString(json['role']),
      owner: json['owner'] is Map
          ? CommunityUser.fromJson(Map<String, dynamic>.from(json['owner']))
          : null,
    );
  }

  CommunityModel copyWith({
    bool? isMember,
    int? memberCount,
    int? groupCount,
    String? role,
  }) {
    return CommunityModel(
      id: id,
      ownerId: ownerId,
      name: name,
      slug: slug,
      description: description,
      category: category,
      imageUrl: imageUrl,
      isPrivate: isPrivate,
      memberCount: memberCount ?? this.memberCount,
      groupCount: groupCount ?? this.groupCount,
      isMember: isMember ?? this.isMember,
      role: role ?? this.role,
      owner: owner,
    );
  }
}

class CommunityGroupModel {
  final int id;
  final int communityId;
  final int ownerId;
  final String name;
  final String description;
  final String imageUrl;
  final bool isPrivate;
  final int memberCount;
  final bool isMember;
  final String role;
  final CommunityUser? owner;

  const CommunityGroupModel({
    required this.id,
    required this.communityId,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isPrivate,
    required this.memberCount,
    required this.isMember,
    required this.role,
    this.owner,
  });

  factory CommunityGroupModel.fromJson(Map<String, dynamic> json) {
    return CommunityGroupModel(
      id: _readInt(json['id']),
      communityId: _readInt(json['communityId'] ?? json['community_id']),
      ownerId: _readInt(json['ownerId'] ?? json['owner_id']),
      name: _readString(json['name'], fallback: 'Group'),
      description: _readString(json['description']),
      imageUrl: _readString(json['imageUrl'] ?? json['image_url']),
      isPrivate: json['isPrivate'] == true || json['is_private'] == true,
      memberCount: _readInt(json['memberCount'] ?? json['member_count']),
      isMember: json['isMember'] == true || json['is_member'] == true,
      role: _readString(json['role']),
      owner: json['owner'] is Map
          ? CommunityUser.fromJson(Map<String, dynamic>.from(json['owner']))
          : null,
    );
  }
}

class DiscussionPostModel {
  final int id;
  final int communityId;
  final int groupId;
  final int userId;
  final String content;
  final List<String> attachments;
  final CommunityUser? author;
  final DateTime? createdAt;

  const DiscussionPostModel({
    required this.id,
    required this.communityId,
    required this.groupId,
    required this.userId,
    required this.content,
    required this.attachments,
    required this.author,
    required this.createdAt,
  });

  factory DiscussionPostModel.fromJson(Map<String, dynamic> json) {
    return DiscussionPostModel(
      id: _readInt(json['id']),
      communityId: _readInt(json['communityId'] ?? json['community_id']),
      groupId: _readInt(json['groupId'] ?? json['group_id']),
      userId: _readInt(json['userId'] ?? json['user_id']),
      content: _readString(json['content']),
      attachments: _readStringList(json['attachments']),
      author: json['author'] is Map
          ? CommunityUser.fromJson(Map<String, dynamic>.from(json['author']))
          : null,
      createdAt: DateTime.tryParse(_readString(json['createdAt'])),
    );
  }
}

class GroupInvitationModel {
  final int id;
  final int groupId;
  final String status;
  final String message;
  final CommunityUser? fromUser;

  const GroupInvitationModel({
    required this.id,
    required this.groupId,
    required this.status,
    required this.message,
    this.fromUser,
  });

  factory GroupInvitationModel.fromJson(Map<String, dynamic> json) {
    return GroupInvitationModel(
      id: _readInt(json['id']),
      groupId: _readInt(json['groupId'] ?? json['group_id']),
      status: _readString(json['status']),
      message: _readString(json['message']),
      fromUser: json['fromUser'] is Map
          ? CommunityUser.fromJson(Map<String, dynamic>.from(json['fromUser']))
          : null,
    );
  }
}

class CommunityMemberModel {
  final CommunityUser user;
  final String role;
  final DateTime? joinedAt;

  const CommunityMemberModel({
    required this.user,
    required this.role,
    this.joinedAt,
  });

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'])
        : Map<String, dynamic>.from(json);

    return CommunityMemberModel(
      user: CommunityUser.fromJson(userJson),
      role: _readString(json['role'], fallback: 'member'),
      joinedAt: DateTime.tryParse(_readString(json['joinedAt'])),
    );
  }
}

class CommunityUser {
  final int id;
  final String name;
  final String username;
  final String avatar;
  final bool verified;

  const CommunityUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
    required this.verified,
  });

  factory CommunityUser.fromJson(Map<String, dynamic> json) {
    return CommunityUser(
      id: _readInt(json['id']),
      name: _readString(json['name'], fallback: 'User'),
      username: _readString(json['username']),
      avatar: _readString(json['avatar']),
      verified: json['verified'] == true || json['isVerified'] == true,
    );
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}
