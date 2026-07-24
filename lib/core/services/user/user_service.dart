import 'package:dio/dio.dart';
import '../../clients/api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  void setAuthToken(String token) {
    _api.setAuthToken(token);
  }

  void clearAuthToken() {
    _api.clearAuthToken();
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _api.get('/api/users/me');
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get user');
    }
  }

  Future<Map<String, dynamic>> updateUser({
    String? name,
    String? username,
    String? phone,
    int? age,
    String? occupation,
    String? bio,
    String? location,
    String? work,
    String? education,
    List<String>? languages,
    String? avatar,
    String? coverImage,
  }) async {
    try {
      final data = <String, dynamic>{
        if (name != null) 'name': name,
        if (username != null) 'username': username,
        if (phone != null) 'phone': phone,
        if (age != null) 'age': age,
        if (occupation != null) 'occupation': occupation,
        if (bio != null) 'bio': bio,
        if (location != null) 'location': location,
        if (work != null) 'work': work,
        if (education != null) 'education': education,
        if (languages != null) 'languages': languages,
        if (avatar != null) 'avatar': avatar,
        if (coverImage != null) 'coverImage': coverImage,
      };

      final response = await _api.put('/api/users/me', data: data);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to update user');
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _api.delete('/api/users/me');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to delete account');
    }
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await _api.get('/api/users/$userId');
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get user');
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(
    String query, {
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        '/api/users/search',
        queryParameters: {
          'q': query,
          'limit': limit,
        },
      );
      final data = response.data is Map ? response.data['data'] : response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to search users');
    }
  }

  Future<List<Map<String, dynamic>>> getUserSuggestions({
    int limit = 10,
  }) async {
    final endpoints = <String>[
      '/api/users/suggestions',
      '/api/friends/suggestions',
      '/api/users/recommended',
    ];

    DioException? lastError;
    for (final endpoint in endpoints) {
      try {
        final response = await _api.get(
          endpoint,
          queryParameters: {'limit': limit},
        );
        final data =
            response.data is Map ? response.data['data'] : response.data;
        if (data is List) {
          return data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      } on DioException catch (e) {
        lastError = e;
        if (e.response?.statusCode == 404) continue;
      }
    }

    if (lastError != null && lastError.response?.statusCode != 404) {
      throw _handleError(lastError, 'Failed to load suggestions');
    }
    return const [];
  }

  Future<Map<String, dynamic>> getProfileSwitchState() async {
    try {
      final response = await _api.get('/api/users/profiles');
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load profile switch state');
    }
  }

  Future<Map<String, dynamic>> createProfile({
    required String name,
    required String username,
    required String profileType,
    String? bio,
    String? avatar,
    String? coverImage,
  }) async {
    try {
      final response = await _api.post(
        '/api/users/profiles',
        data: {
          'name': name,
          'username': username,
          'profileType': profileType,
          if (bio != null) 'bio': bio,
          if (avatar != null) 'avatar': avatar,
          if (coverImage != null) 'coverImage': coverImage,
        },
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to create profile');
    }
  }

  Future<Map<String, dynamic>> linkProfile(int profileUserId) async {
    try {
      final response = await _api.post(
        '/api/users/profiles/link',
        data: {
          'profileUserId': profileUserId,
        },
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to link profile');
    }
  }

  Future<Map<String, dynamic>> switchProfile(int profileUserId) async {
    try {
      final response = await _api.post(
        '/api/users/profiles/switch',
        data: {
          'profileUserId': profileUserId,
        },
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to switch profile');
    }
  }

  Future<Map<String, dynamic>> unlinkProfile(int profileUserId) async {
    try {
      final response = await _api.delete('/api/users/profiles/$profileUserId');
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to unlink profile');
    }
  }

  Future<Map<String, dynamic>> deleteProfile(int profileUserId) async {
    try {
      final response = await _api.delete(
        '/api/users/profiles/$profileUserId/delete',
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to delete profile');
    }
  }

// Update demographic info
  Future<void> updateDemographicInfo({
    required int age,
    required String gender,
    required String lookingFor,
    required String occupation,
    required String bio,
    required String location,
    required String work,
    required String education,
    required List<String> interests,
  }) async {
    try {
      await _api.put('/api/users/me/demographic', data: {
        'age': age,
        'gender': gender,
        'looking_for': lookingFor,
        'occupation': occupation,
        'bio': bio,
        'location': location,
        'work': work,
        'education': education,
        'languages': interests,
      });
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to update profile');
    }
  }

// Complete onboarding
  Future<void> completeOnboarding() async {
    try {
      await _api.put('/api/users/onboard');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to complete onboarding');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const FormatException('Invalid user response');
  }

  String _handleError(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return fallback;
  }
}
