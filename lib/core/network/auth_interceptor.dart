import 'package:clique/core/managers/token_manager.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  
  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.path.contains('/auth/')) {
      return handler.next(options);
    }

    final token = await TokenManager.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't attempt refresh on auth endpoints
    if (err.requestOptions.path.contains('/auth/')) {
      return handler.reject(err);
    }

    try {
      // Use TokenManager's built-in refresh lock
      final newTokens = await TokenManager.refreshTokens(
        refreshApiCall: (refreshToken) async {
          // This calls your Retrofit API
          final response = await dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );
          
          return AuthTokens(
            accessToken: response.data['accessToken'],
            refreshToken: response.data['refreshToken'],
            expiresAt: DateTime.parse(response.data['expiresAt']),
          );
        },
      );

      // Retry the original request with new token
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer ${newTokens.accessToken}';
      
      final response = await dio.fetch(options);
      return handler.resolve(response);
      
    } catch (e) {
      // Refresh failed - force logout
      await TokenManager.clearTokens();
      return handler.reject(err);
    }
  }
}