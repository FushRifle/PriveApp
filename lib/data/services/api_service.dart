import 'package:dio/dio.dart';
import 'package:social_media_app/app/configs/api_config.dart';
import 'package:social_media_app/core/supabase_client.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },

        // Important:
        // Let Dio treat 401/403/500 as errors so onError runs.
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = SupabaseConfig.client.auth.currentSession;
          final token = session?.accessToken;

          print('[API] ${options.method} ${options.uri}');
          print('[API] Supabase session exists: ${session != null}');
          print('[API] Token exists: ${token != null}');
          print('[API] Token length: ${token?.length ?? 0}');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            print('[API] Authorization header added');
          } else {
            print('[API] No Authorization header added');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '[API] Response ${response.statusCode}: ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) async {
          print(
            '[API] Error ${error.response?.statusCode}: ${error.requestOptions.path}',
          );
          print('[API] Error data: ${error.response?.data}');

          if (error.response?.statusCode == 401) {
            print('[API] 401 from backend. Token may be missing or invalid.');
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> getToken() async {
    return SupabaseConfig.client.auth.currentSession?.accessToken;
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return dio.delete(path);
  }
}
