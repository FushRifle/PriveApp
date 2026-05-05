import 'package:dio/dio.dart';
import '../api_service.dart';

class UserService {
  final ApiService _api = ApiService();

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

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw 'Invalid user response';
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
