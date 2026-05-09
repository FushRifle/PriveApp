import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Prive/app/configs/api_config.dart';
import 'package:Prive/core/supabase_client.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  final Map<String, CacheEntry> _memoryCache = {};

  final Duration cacheDuration = const Duration(days: 7);

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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

          if (ApiConfig.isDebugMode) {
            print('[API] ${options.method} ${options.uri.path}');
          }

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (ApiConfig.isDebugMode && response.statusCode != 200) {
            print(
                '[API] Response ${response.statusCode}: ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (ApiConfig.isDebugMode) {
            print(
                '[API] Error ${error.response?.statusCode}: ${error.requestOptions.path}');
          }

          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final requestOptions = error.requestOptions;
              final newToken = await getToken();
              if (newToken != null) {
                requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final response = await dio.fetch(requestOptions);
                return handler.resolve(response);
              }
            }
          }

          return handler.next(error);
        },
      ),
    );

    if (ApiConfig.isDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
        ),
      );
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Accept-Encoding'] = 'gzip, deflate, br';
          return handler.next(options);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getToken() async {
    return SupabaseConfig.client.auth.currentSession?.accessToken;
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // GET with cache support
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(path, queryParameters);

    // Try to get from memory cache first
    if (!forceRefresh && _memoryCache.containsKey(cacheKey)) {
      final entry = _memoryCache[cacheKey]!;
      if (!entry.isExpired) {
        return Response(
          data: entry.data,
          statusCode: 200,
          requestOptions: RequestOptions(path: path),
        );
      }
    }

    // Try to get from disk cache
    if (!forceRefresh) {
      final cached = await _getFromDiskCache(cacheKey);
      if (cached != null) {
        _memoryCache[cacheKey] = CacheEntry(
          data: cached,
          timestamp: DateTime.now(),
        );
        return Response(
          data: cached,
          statusCode: 200,
          requestOptions: RequestOptions(path: path),
        );
      }
    }

    // Fetch from network
    final response = await dio.get(path, queryParameters: queryParameters);

    // Cache the response
    if (response.statusCode == 200) {
      await _saveToCache(cacheKey, response.data);
    }

    return response;
  }

  // POST (no cache by default)
  Future<Response> post(String path, {dynamic data}) {
    return dio.post(path, data: data);
  }

  // PUT (no cache by default)
  Future<Response> put(String path, {dynamic data}) {
    return dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return dio.delete(path);
  }

  // Clear all cache
  Future<void> clearCache() async {
    _memoryCache.clear();
    final cacheDir = await _getCacheDirectory();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }

  // Clear cache for specific endpoint
  Future<void> clearCacheForEndpoint(String path) async {
    final keysToRemove =
        _memoryCache.keys.where((key) => key.contains(path)).toList();
    for (var key in keysToRemove) {
      _memoryCache.remove(key);
    }

    final cacheDir = await _getCacheDirectory();
    final files = await cacheDir.list().toList();
    for (var file in files) {
      if (file.path.contains(path)) {
        await file.delete();
      }
    }
  }

  String _getCacheKey(String path, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return path;
    }
    final queryString = Uri(queryParameters: queryParameters).query;
    return '$path?$queryString';
  }

  Future<Directory> _getCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/api_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<void> _saveToCache(String key, dynamic data) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final file = File('${cacheDir.path}/${key.hashCode}.json');
      await file.writeAsString(data.toString());

      _memoryCache[key] = CacheEntry(
        data: data,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // Silent fail for cache
    }
  }

  Future<dynamic> _getFromDiskCache(String key) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final file = File('${cacheDir.path}/${key.hashCode}.json');

      if (!await file.exists()) return null;

      final stat = await file.stat();
      final age = DateTime.now().difference(stat.modified);

      if (age > cacheDuration) {
        await file.delete();
        return null;
      }

      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  CacheEntry({
    required this.data,
    required this.timestamp,
  });

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(days: 7);
}
