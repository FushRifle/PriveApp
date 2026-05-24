import 'dart:async';

import 'package:dio/dio.dart';
import 'package:clique/app/configs/api_config.dart';
import 'package:clique/core/supabase_client.dart';

import './retrofit_client.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late final Dio dio;
  late final RetrofitClient retrofitClient;

  String? _authToken;

  final Map<String, CancelToken> _cancelTokens = {};

  final Map<String, Future<Response>> _pendingRequests = {};

  final Map<String, dynamic> _memoryCache = {};

  final Map<String, DateTime> _cacheTimestamps = {};

  static const Duration _cacheDuration = Duration(seconds: 60);

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    retrofitClient = RetrofitClient(dio);

    _setupInterceptors();
  }

  // =========================================================
  // AUTH
  // =========================================================

  void setAuthToken(String token) {
    _authToken = token;

    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _authToken = null;

    dio.options.headers.remove('Authorization');

    clearCache();

    cancelAllRequests();
  }

  // =========================================================
  // INTERCEPTORS
  // =========================================================

  void _setupInterceptors() {
    dio.interceptors.clear();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = SupabaseConfig.client.auth.currentSession;

          final token = session?.accessToken ?? _authToken;

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String _requestKey(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
  }) {
    return [
      method,
      path,
      queryParameters.toString(),
      data.toString(),
    ].join('_');
  }

  CancelToken _createCancelToken(String key) {
    if (_cancelTokens.containsKey(key)) {
      _cancelTokens[key]?.cancel();
    }

    final token = CancelToken();

    _cancelTokens[key] = token;

    return token;
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];

    if (timestamp == null) {
      return false;
    }

    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  Future<Response> _withRetry(
    Future<Response> Function() request,
  ) async {
    int retries = 0;

    while (retries < 3) {
      try {
        return await request();
      } on DioException catch (e) {
        retries++;

        if (CancelToken.isCancel(e)) {
          rethrow;
        }

        final status = e.response?.statusCode ?? 0;

        if (status >= 400 && status < 500 && status != 401) {
          rethrow;
        }

        if (retries >= 3) {
          rethrow;
        }

        await Future.delayed(
          Duration(milliseconds: 400 * retries),
        );
      }
    }

    throw Exception('Request failed');
  }

  // =========================================================
  // GET
  // =========================================================

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool forceRefresh = false,
    bool useCache = true,
    CancelToken? cancelToken,
  }) async {
    final key = _requestKey(
      'GET',
      path,
      queryParameters: queryParameters,
    );

    if (!forceRefresh &&
        useCache &&
        _memoryCache.containsKey(key) &&
        _isCacheValid(key)) {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: _memoryCache[key],
      );
    }

    if (_pendingRequests.containsKey(key)) {
      return await _pendingRequests[key]!;
    }

    final future = _withRetry(
      () => dio.get(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken ?? _createCancelToken(key),
      ),
    );

    _pendingRequests[key] = future;

    try {
      final response = await future;

      if (useCache) {
        _memoryCache[key] = response.data;

        _cacheTimestamps[key] = DateTime.now();
      }

      return response;
    } finally {
      _pendingRequests.remove(key);
    }
  }

  // =========================================================
  // POST
  // =========================================================

  Future<Response> post(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    final key = _requestKey(
      'POST',
      path,
      data: data,
    );

    return _withRetry(
      () => dio.post(
        path,
        data: data,
        cancelToken: cancelToken ?? _createCancelToken(key),
      ),
    );
  }

  // =========================================================
  // PUT
  // =========================================================

  Future<Response> put(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    final key = _requestKey(
      'PUT',
      path,
      data: data,
    );

    return _withRetry(
      () => dio.put(
        path,
        data: data,
        cancelToken: cancelToken ?? _createCancelToken(key),
      ),
    );
  }

  // =========================================================
  // PATCH
  // =========================================================

  Future<Response> patch(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    final key = _requestKey(
      'PATCH',
      path,
      data: data,
    );

    return _withRetry(
      () => dio.patch(
        path,
        data: data,
        cancelToken: cancelToken ?? _createCancelToken(key),
      ),
    );
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<Response> delete(
    String path, {
    CancelToken? cancelToken,
  }) async {
    final key = _requestKey(
      'DELETE',
      path,
    );

    return _withRetry(
      () => dio.delete(
        path,
        cancelToken: cancelToken ?? _createCancelToken(key),
      ),
    );
  }

  // =========================================================
  // CACHE
  // =========================================================

  void removeCacheByPath(String path) {
    final keys = _memoryCache.keys.where((e) => e.contains(path)).toList();

    for (final key in keys) {
      _memoryCache.remove(key);

      _cacheTimestamps.remove(key);
    }
  }

  void clearCache() {
    _memoryCache.clear();

    _cacheTimestamps.clear();
  }

  // =========================================================
  // REQUEST CANCELLATION
  // =========================================================

  void cancelRequest(String key) {
    if (_cancelTokens.containsKey(key)) {
      _cancelTokens[key]?.cancel();

      _cancelTokens.remove(key);
    }
  }

  void cancelAllRequests() {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }

    _cancelTokens.clear();

    _pendingRequests.clear();
  }

  // =========================================================
  // CLEANUP
  // =========================================================

  void dispose() {
    cancelAllRequests();

    clearCache();
  }
}
