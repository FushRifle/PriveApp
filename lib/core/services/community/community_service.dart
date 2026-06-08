import 'package:dio/dio.dart';

import 'package:clique/core/clients/api_service.dart';
import 'package:clique/core/models/community_model.dart';

class CommunityService {
  final ApiService _api = ApiService();

  void setAuthToken(String token) {
    _api.setAuthToken(token);
  }

  Future<List<CommunityModel>> getCommunities({
    int page = 1,
    int pageSize = 20,
    String query = '',
    String category = '',
  }) async {
    try {
      final response = await _api.get(
        '/api/communities/',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (query.isNotEmpty) 'q': query,
          if (category.isNotEmpty) 'category': category,
        },
        forceRefresh: true,
      );
      return _readList(response.data)
          .map((item) => CommunityModel.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load communities');
    }
  }

  Future<CommunityModel> getCommunity(int id) async {
    try {
      final response = await _api.get(
        '/api/communities/$id',
        forceRefresh: true,
      );
      return CommunityModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load community');
    }
  }

  Future<CommunityModel> createCommunity({
    required String name,
    required String description,
    required String category,
    String imageUrl = '',
    bool isPrivate = false,
  }) async {
    try {
      final response = await _api.post('/api/communities/', data: {
        'name': name,
        'description': description,
        'category': category,
        'imageUrl': imageUrl,
        'isPrivate': isPrivate,
      });
      _clearCommunityCaches();
      return CommunityModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to create community');
    }
  }

  Future<void> joinCommunity(int id) async {
    try {
      await _api.post('/api/communities/$id/join');
      _clearCommunityCaches();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to join community');
    }
  }

  Future<void> leaveCommunity(int id) async {
    try {
      await _api.delete('/api/communities/$id/join');
      _clearCommunityCaches();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to leave community');
    }
  }

  Future<List<CommunityMemberModel>> getCommunityMembers(
      int communityId) async {
    try {
      final response = await _api.get(
        '/api/communities/$communityId/members',
        forceRefresh: true,
      );
      return _readList(response.data)
          .map((item) => CommunityMemberModel.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load members');
    }
  }

  Future<List<CommunityGroupModel>> getGroups(int communityId) async {
    try {
      final response = await _api.get(
        '/api/communities/$communityId/groups',
        forceRefresh: true,
      );
      return _readList(response.data)
          .map((item) => CommunityGroupModel.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load groups');
    }
  }

  Future<CommunityGroupModel> createGroup({
    required int communityId,
    required String name,
    required String description,
    String imageUrl = '',
    bool isPrivate = false,
  }) async {
    try {
      final response =
          await _api.post('/api/communities/$communityId/groups', data: {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'isPrivate': isPrivate,
      });
      _clearCommunityCaches();
      return CommunityGroupModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to create group');
    }
  }

  Future<void> joinGroup(int groupId) async {
    try {
      await _api.post('/api/groups/$groupId/join');
      _clearCommunityCaches();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to join group');
    }
  }

  Future<List<DiscussionPostModel>> getCommunityPosts(int communityId) async {
    try {
      final response = await _api.get(
        '/api/communities/$communityId/posts',
        forceRefresh: true,
      );
      return _readList(response.data)
          .map((item) => DiscussionPostModel.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load discussions');
    }
  }

  Future<DiscussionPostModel> createCommunityPost({
    required int communityId,
    required String content,
    int? groupId,
  }) async {
    try {
      final path = groupId != null && groupId > 0
          ? '/api/groups/$groupId/posts'
          : '/api/communities/$communityId/posts';
      final response = await _api.post(
        path,
        data: {
          'content': content,
          'attachments': <String>[],
          if (_extractMentions(content).isNotEmpty)
            'mentions': _extractMentions(content),
        },
      );
      _clearCommunityCaches();
      return DiscussionPostModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to post discussion');
    }
  }

  Future<List<DiscussionPostModel>> getGroupPosts(int groupId) async {
    try {
      final response = await _api.get(
        '/api/groups/$groupId/posts',
        forceRefresh: true,
      );
      return _readList(response.data)
          .map((item) => DiscussionPostModel.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load group chat');
    }
  }

  Future<List<GroupInvitationModel>> getInvitations() async {
    try {
      final response = await _api.get(
        '/api/communities/invitations',
        forceRefresh: true,
      );
      return _readList(response.data)
          .map((item) => GroupInvitationModel.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load invitations');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  List<Map<String, dynamic>> _readList(dynamic data) {
    final raw = data is Map ? data['data'] : data;
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  void _clearCommunityCaches() {
    _api.removeCacheByPath('/api/communities');
    _api.removeCacheByPath('/api/groups');
    _api.removeCacheByPath('/api/notifications');
  }

  String _handleError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return fallback;
  }

  List<String> _extractMentions(String text) {
    final seen = <String>{};
    return RegExp(r'(?<![A-Za-z0-9_])@([A-Za-z0-9_]+)')
        .allMatches(text)
        .map((match) => match.group(1)!.toLowerCase())
        .where(seen.add)
        .toList();
  }
}
