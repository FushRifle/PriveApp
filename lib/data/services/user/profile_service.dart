import 'package:dio/dio.dart';
import '../api_service.dart';

class ProfileService {
  final ApiService _api = ApiService();

  // Get my dating profile
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final response = await _api.get('/profiles/me');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get profile';
    }
  }

  // Update my dating profile
  Future<Map<String, dynamic>> updateMyProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/profiles/me', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update profile';
    }
  }

  // Get profile by user ID
  Future<Map<String, dynamic>> getProfileByUserId(int userId) async {
    try {
      final response = await _api.get('/profiles/$userId');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get profile';
    }
  }
}
