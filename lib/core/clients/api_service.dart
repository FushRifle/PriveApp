import 'package:dio/dio.dart';
import 'package:clique/app/configs/api_config.dart';
import 'package:clique/core/clients/supabase_client.dart';

import 'retrofit_client.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late final Dio dio;
  late final RetrofitClient retrofitClient;

  String? _authToken;

  final Map<String, CancelToken> _cancelTokens = {};

  final Map<String, Future<Response>> _pendingGetRequests = {};

  final Map<String, dynamic> _memoryCache = {};

  final Map<String, DateTime> _cacheTimestamps = {};

  final Map<String, DateTime> _cooldowns = {};

  int _requestId = 0;

  static const Duration _cacheDuration = Duration(seconds: 60);
  static const int _maxCacheEntries = 120;
  static const int _maxRetries = 3;
  static const Duration _defaultRateLimitCooldown = Duration(seconds: 30);

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
      _stableEncode(queryParameters),
      _stableEncode(data),
    ].join('_');
  }

  String _stableEncode(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return entries
          .map((entry) => '${entry.key}:${_stableEncode(entry.value)}')
          .join(',');
    }
    if (value is Iterable) {
      return value.map(_stableEncode).join(',');
    }
    return value.toString();
  }

  ({CancelToken token, String? trackingKey}) _trackCancelToken(
    String key,
    CancelToken? cancelToken,
  ) {
    if (cancelToken != null) {
      return (token: cancelToken, trackingKey: null);
    }

    final token = CancelToken();
    final trackingKey = '${key}_${_requestId++}';

    _cancelTokens[trackingKey] = token;

    return (token: token, trackingKey: trackingKey);
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];

    if (timestamp == null) {
      return false;
    }

    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  bool _isCoolingDown(String key) {
    final cooldownUntil = _cooldowns[key];
    if (cooldownUntil == null) {
      return false;
    }

    if (DateTime.now().isBefore(cooldownUntil)) {
      return true;
    }

    _cooldowns.remove(key);
    return false;
  }

  void _startCooldown(String key, DioException error) {
    final retryAfter = error.response?.headers.value('retry-after');
    final retryAfterSeconds = int.tryParse(retryAfter ?? '');
    final duration = retryAfterSeconds != null && retryAfterSeconds > 0
        ? Duration(seconds: retryAfterSeconds)
        : _defaultRateLimitCooldown;

    _cooldowns[key] = DateTime.now().add(duration);
  }

  DioException _cooldownException(String key, String path) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 429,
        data: {
          'message': 'Request is cooling down after a rate limit response',
          'key': key,
        },
      ),
      type: DioExceptionType.badResponse,
    );
  }

  Future<Response> _sendWithRetry(
    Future<Response> Function() request,
    String key,
    String method,
  ) async {
    final canRetry = method == 'GET';
    int retries = 0;

    while (true) {
      try {
        return await request();
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          rethrow;
        }

        final status = e.response?.statusCode ?? 0;

        if (status == 429) {
          _startCooldown(key, e);
          rethrow;
        }

        final shouldRetry = status >= 500 || status == 0;

        if (!canRetry || !shouldRetry || retries >= _maxRetries) {
          rethrow;
        }

        retries++;

        await Future.delayed(_retryDelay(e, retries));
      }
    }
  }

  Duration _retryDelay(DioException error, int retryCount) {
    final retryAfter = error.response?.headers.value('retry-after');
    final retryAfterSeconds = int.tryParse(retryAfter ?? '');

    if (retryAfterSeconds != null && retryAfterSeconds > 0) {
      return Duration(seconds: retryAfterSeconds);
    }

    return Duration(milliseconds: 600 * retryCount);
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

    if (_isCoolingDown(key)) {
      if (useCache && _memoryCache.containsKey(key)) {
        return Response(
          requestOptions: RequestOptions(path: path),
          data: _memoryCache[key],
        );
      }

      throw _cooldownException(key, path);
    }

    final shouldSharePending = !forceRefresh;

    if (shouldSharePending && _pendingGetRequests.containsKey(key)) {
      return await _pendingGetRequests[key]!;
    }

    final trackedToken = _trackCancelToken(key, cancelToken);

    final future = _sendWithRetry(
      () => dio.get(
        path,
        queryParameters: queryParameters,
        cancelToken: trackedToken.token,
      ),
      key,
      'GET',
    );

    if (shouldSharePending) {
      _pendingGetRequests[key] = future;
    }

    try {
      final response = await future;

      if (useCache) {
        _memoryCache[key] = response.data;

        _cacheTimestamps[key] = DateTime.now();

        _trimCache();
      }

      return response;
    } finally {
      if (_pendingGetRequests[key] == future) {
        _pendingGetRequests.remove(key);
      }
      final trackingKey = trackedToken.trackingKey;
      if (trackingKey != null) {
        _cancelTokens.remove(trackingKey);
      }
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

    final trackedToken = _trackCancelToken(key, cancelToken);

    return _sendWithRetry(
      () => dio.post(
        path,
        data: data,
        cancelToken: trackedToken.token,
      ),
      key,
      'POST',
    ).whenComplete(() {
      final trackingKey = trackedToken.trackingKey;
      if (trackingKey != null) {
        _cancelTokens.remove(trackingKey);
      }
    });
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

    final trackedToken = _trackCancelToken(key, cancelToken);

    return _sendWithRetry(
      () => dio.put(
        path,
        data: data,
        cancelToken: trackedToken.token,
      ),
      key,
      'PUT',
    ).whenComplete(() {
      final trackingKey = trackedToken.trackingKey;
      if (trackingKey != null) {
        _cancelTokens.remove(trackingKey);
      }
    });
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

    final trackedToken = _trackCancelToken(key, cancelToken);

    return _sendWithRetry(
      () => dio.patch(
        path,
        data: data,
        cancelToken: trackedToken.token,
      ),
      key,
      'PATCH',
    ).whenComplete(() {
      final trackingKey = trackedToken.trackingKey;
      if (trackingKey != null) {
        _cancelTokens.remove(trackingKey);
      }
    });
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<Response> delete(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    final key = _requestKey(
      'DELETE',
      path,
      data: data,
    );

    final trackedToken = _trackCancelToken(key, cancelToken);

    return _sendWithRetry(
      () => dio.delete(
        path,
        data: data,
        cancelToken: trackedToken.token,
      ),
      key,
      'DELETE',
    ).whenComplete(() {
      final trackingKey = trackedToken.trackingKey;
      if (trackingKey != null) {
        _cancelTokens.remove(trackingKey);
      }
    });
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

    _cooldowns.clear();
  }

  void _trimCache() {
    if (_memoryCache.length <= _maxCacheEntries) return;

    final keysByAge = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final removeCount = _memoryCache.length - _maxCacheEntries;

    for (final entry in keysByAge.take(removeCount)) {
      _memoryCache.remove(entry.key);
      _cacheTimestamps.remove(entry.key);
    }
  }

  // =========================================================
  // REQUEST CANCELLATION
  // =========================================================

  void cancelRequest(String key) {
    final matchingKeys = _cancelTokens.keys
        .where((tokenKey) => tokenKey == key || tokenKey.startsWith('${key}_'))
        .toList();

    for (final tokenKey in matchingKeys) {
      _cancelTokens[tokenKey]?.cancel();
      _cancelTokens.remove(tokenKey);
    }
  }

  void cancelAllRequests() {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }

    _cancelTokens.clear();

    _pendingGetRequests.clear();
  }

  // =========================================================
  // CLEANUP
  // =========================================================

  void dispose() {
    cancelAllRequests();

    clearCache();
  }
}
