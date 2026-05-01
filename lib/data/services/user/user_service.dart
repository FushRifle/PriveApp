import 'package:dio/dio.dart';
import '../api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  // Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _api.get('/api/users/me');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get user';
    }
  }

  // Update current user
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
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (username != null) data['username'] = username;
      if (phone != null) data['phone'] = phone;
      if (age != null) data['age'] = age;
      if (occupation != null) data['occupation'] = occupation;
      if (bio != null) data['bio'] = bio;
      if (location != null) data['location'] = location;
      if (work != null) data['work'] = work;
      if (education != null) data['education'] = education;
      if (languages != null) data['languages'] = languages;
      if (avatar != null) data['avatar'] = avatar;
      if (coverImage != null) data['coverImage'] = coverImage;

      final response = await _api.put('/api/users/me', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update user';
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await _api.delete('/api/users/me');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete account';
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await _api.get('/api/users/$userId');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get user';
    }
  }
}
