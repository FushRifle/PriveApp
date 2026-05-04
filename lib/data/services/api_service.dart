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
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status! < 600,
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('[API] Request: ${options.method} ${options.path}');
        
        final token = await _storage.read(key: 'auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('[API] Token added to request (length: ${token.length})');
        } else {
          print('[API] No token found for request');
        }
        
        print('[API] Request headers: ${options.headers}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('[API] Response: ${response.statusCode} ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        print('[API] Error: ${error.response?.statusCode} ${error.requestOptions.path}');
        print('[API] Error message: ${error.message}');
        if (error.response?.data != null) {
          print('[API] Error data: ${error.response?.data}');
        }
        
        if (error.response?.statusCode == 401) {
          print('[API] Unauthorized - clearing token');
          await clearToken();
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> setToken(String token) async {
    print('[API] Setting token (length: ${token.length})');
    await _storage.write(key: 'auth_token', value: token);
    print('[API] Token saved successfully');
  }

  Future<void> clearToken() async {
    print('[API] Clearing token');
    await _storage.delete(key: 'auth_token');
    print('[API] Token cleared');
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: 'auth_token');
    print('[API] Getting token - exists: ${token != null}');
    if (token != null) {
      print('[API] Token length: ${token.length}');
    }
    return token;
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'auth_token');
    final hasToken = token != null && token.isNotEmpty;
    print('[API] Has token: $hasToken');
    return hasToken;
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    print('[API] GET $path');
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    print('[API] POST $path');
    return await dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    print('[API] PUT $path');
    return await dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    print('[API] PATCH $path');
    return await dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    print('[API] DELETE $path');
    return await dio.delete(path);
  }
}