import 'package:dio/dio.dart';
import 'package:social_media_app/app/configs/api_config.dart';
import 'api_service.dart';

class ClerkAuthService {
  final ApiService _api = ApiService();
  final Dio _clerkDio = Dio(BaseOptions(
    baseUrl: 'https://api.clerk.com/v1',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${ApiConfig.clerkPublishableKey}',
    },
  ));

  // Sign in
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // First, create a sign-in
      final signInResponse = await _clerkDio.post('/client/sign_ins', data: {
        'identifier': email,
        'password': password,
      });

      final signInId = signInResponse.data['id'];

      // Then, attempt to complete it
      final attemptResponse = await _clerkDio.post(
        '/client/sign_ins/$signInId/attempt_first_factor',
        data: {
          'strategy': 'password',
          'password': password,
        },
      );

      // Get session token
      final sessionId = attemptResponse.data['created_session_id'];
      if (sessionId != null) {
        // Get session token
        final tokenResponse = await _clerkDio.get(
          '/client/sessions/$sessionId/token',
        );
        final token = tokenResponse.data['jwt'];
        await _api.setToken(token);
      }

      return {
        'success': true,
        'data': attemptResponse.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['errors']?[0]?['message'] ?? 'Sign in failed',
      };
    }
  }

  // Sign up
  Future<Map<String, dynamic>> signUp({
    required String emailAddress,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _clerkDio.post('/client/sign_ups', data: {
        'email_address': emailAddress,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['errors']?[0]?['message'] ?? 'Sign up failed',
      };
    }
  }

  // Verify email
  Future<Map<String, dynamic>> verifyEmail({
    required String signUpId,
    required String code,
  }) async {
    try {
      final response = await _clerkDio.post(
        '/client/sign_ups/$signUpId/attempt_verification',
        data: {
          'strategy': 'email_code',
          'code': code,
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data['errors']?[0]?['message'] ?? 'Verification failed',
      };
    }
  }

  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await _api.getToken();
      if (token == null) return null;

      final response = await _clerkDio.get(
        '/client',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data;
    } catch (e) {
      return null;
    }
  }

  // Check if authenticated
  Future<bool> isAuthenticated() async {
    return await _api.hasToken();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final token = await _api.getToken();
      if (token != null) {
        await _clerkDio.post(
          '/client/sign_outs',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      }
    } catch (e) {
      // Still clear token
    } finally {
      await _api.clearToken();
    }
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      // Create sign-in with reset strategy
      final response = await _clerkDio.post('/client/sign_ins', data: {
        'identifier': email,
        'strategy': 'reset_password_email_code',
      });

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['errors']?[0]?['message'] ?? 'Failed',
      };
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String signInId,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _clerkDio.post(
        '/client/sign_ins/$signInId/attempt_first_factor',
        data: {
          'strategy': 'reset_password_email_code',
          'code': code,
          'password': newPassword,
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['errors']?[0]?['message'] ?? 'Failed',
      };
    }
  }
}
