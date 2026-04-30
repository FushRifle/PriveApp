import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:social_media_app/app/configs/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.supabaseRestUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'apikey': ApiConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${ApiConfig.supabaseAnonKey}',
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'clerk_token');
        if (token != null) {
          // Use Clerk token for authenticated requests
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await clearToken();
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'clerk_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'clerk_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'clerk_token');
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'clerk_token');
    return token != null;
  }

  // HTTP methods
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await dio.delete(path);
  }
}
