import 'package:dio/dio.dart';
import 'package:social_media_app/app/configs/api_config.dart';
import 'package:social_media_app/data/services/api_service.dart';

class ConnectivityService {
  final ApiService _api = ApiService();

  // Test connection to your backend
  Future<Map<String, dynamic>> checkBackendConnection() async {
    try {
      final response = await _api.get('/ping', queryParameters: null);
      return {
        'connected': true,
        'statusCode': response.statusCode,
        'baseUrl': ApiConfig.baseUrl,
      };
    } on DioException catch (e) {
      return {
        'connected': false,
        'error': e.type.name,
        'message': e.message,
        'baseUrl': ApiConfig.baseUrl,
        'statusCode': e.response?.statusCode,
      };
    }
  }

  // Test connection to Clerk
  Future<Map<String, dynamic>> checkClerkConnection() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://api.clerk.com/v1',
        headers: {
          'Authorization': 'Bearer ${ApiConfig.clerkSecretKey}',
        },
      ));
      final response = await dio.get('/client');
      return {
        'connected': true,
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      return {
        'connected': false,
        'error': e.type.name,
        'message': e.message,
      };
    }
  }

  // Test connection to Cloudinary
  Future<Map<String, dynamic>> checkCloudinaryConnection() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.cloudinary.com/v1_1/${ApiConfig.cloudinaryCloudName}/ping',
      );
      return {
        'connected': true,
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      return {
        'connected': false,
        'error': e.type.name,
        'message': e.message,
      };
    }
  }

  // Run all checks
  Future<Map<String, dynamic>> runAllChecks() async {
    final results = await Future.wait([
      checkBackendConnection(),
      checkClerkConnection(),
      checkCloudinaryConnection(),
    ]);

    return {
      'backend': results[0],
      'clerk': results[1],
      'cloudinary': results[2],
    };
  }

  // Get human-readable error message
  String getFriendlyErrorMessage(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. The server is taking too long to respond.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Check your internet speed.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. The server is not responding.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Check your internet connection.';
      case DioExceptionType.badResponse:
        return 'Server error. Please try again later.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Please check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
