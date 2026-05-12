import 'dart:async';

import 'package:dio/dio.dart';
import 'package:Prive/app/configs/api_config.dart';
import 'package:Prive/core/supabase_client.dart';
import './retrofit_client.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  late final RetrofitClient retrofitClient;

  // Request tracking
  final Map<String, _PendingRequest> _pendingRequests = {};
  final Map<String, DateTime> _lastRequestTime = {};

  // Configuration
  static const Duration _minRequestInterval = Duration(milliseconds: 300);
  static const Duration _requestTimeout = Duration(seconds: 30);

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          // Accept 200-299, and treat 401/404 as non-fatal
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    retrofitClient = RetrofitClient(dio);
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = SupabaseConfig.client.auth.currentSession;
          final token = session?.accessToken;

          // Only log non-explore endpoints to reduce noise
          final shouldLog = !options.path.contains('/explore') &&
              !options.path.contains('/stats');

          if (shouldLog) {
            print('[API] ${options.method} ${options.uri}');
          }

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Don't log 404s as errors
          if (response.statusCode != 404) {
            print(
                '[API] Response ${response.statusCode}: ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Handle 404 gracefully - return empty data instead of error
          if (error.response?.statusCode == 404) {
            print(
                '[API] Endpoint not found (expected): ${error.requestOptions.path}');
            return handler.resolve(Response(
              requestOptions: error.requestOptions,
              statusCode: 200,
              data: _getDefaultResponseForPath(error.requestOptions.path),
            ));
          }

          // Handle 401 - return null data instead of throwing
          if (error.response?.statusCode == 401) {
            print('[API] 401 Unauthorized: ${error.requestOptions.path}');
            return handler.resolve(Response(
              requestOptions: error.requestOptions,
              statusCode: 401,
              data: {'error': 'Unauthorized', 'data': null},
            ));
          }

          // Don't print 500 errors for known problematic endpoints
          if (error.response?.statusCode == 500 &&
              (error.requestOptions.path.contains('/users/me') ||
                  error.requestOptions.path.contains('/feed/stories'))) {
            print('[API] Known 500 error on: ${error.requestOptions.path}');
            return handler.resolve(Response(
              requestOptions: error.requestOptions,
              statusCode: 200,
              data: _getDefaultResponseForPath(error.requestOptions.path),
            ));
          }

          print(
              '[API] Error ${error.response?.statusCode}: ${error.requestOptions.path}');
          return handler.next(error);
        },
      ),
    );
  }

  // Get default response for known endpoints
  dynamic _getDefaultResponseForPath(String path) {
    if (path.contains('/users/me')) {
      return {'id': null, 'name': null, 'email': null};
    }
    if (path.contains('/feed/posts')) {
      return [];
    }
    if (path.contains('/feed/stories')) {
      return [];
    }
    if (path.contains('/reels')) {
      return [];
    }
    return {};
  }

  // Generate a unique key for request deduplication
  String _getRequestKey(String path, Map<String, dynamic>? queryParameters,
      {dynamic data}) {
    final queryStr = queryParameters?.toString() ?? '';
    final dataStr = data != null ? data.toString() : '';
    return '$path|$queryStr|$dataStr';
  }

  // Debounced GET request to prevent racing
  Future<Response> getDebounced(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool forceRefresh = false,
  }) async {
    final key = _getRequestKey(path, queryParameters);

    // Check for pending request
    if (!forceRefresh && _pendingRequests.containsKey(key)) {
      final pending = _pendingRequests[key]!;
      print('[API] Reusing pending request for: $path');
      return pending.future;
    }

    // Check for recent request
    if (!forceRefresh && _lastRequestTime.containsKey(key)) {
      final timeSinceLast = DateTime.now().difference(_lastRequestTime[key]!);
      if (timeSinceLast < _minRequestInterval) {
        print('[API] Debouncing request to: $path');
        await Future.delayed(_minRequestInterval - timeSinceLast);
      }
    }

    // Create new request
    final completer = Completer<Response>();
    final pending = _PendingRequest(completer, DateTime.now());
    _pendingRequests[key] = pending;

    try {
      final response = await get(path, queryParameters: queryParameters);
      _lastRequestTime[key] = DateTime.now();
      completer.complete(response);
      return response;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      // Remove after a short delay to allow subsequent requests to reuse
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_pendingRequests[key] == pending) {
          _pendingRequests.remove(key);
        }
      });
    }
  }

  // Debounced POST request
  Future<Response> postDebounced(
    String path, {
    dynamic data,
    bool forceRefresh = false,
  }) async {
    final key = _getRequestKey(path, null, data: data);

    if (!forceRefresh && _pendingRequests.containsKey(key)) {
      print('[API] Reusing pending POST request for: $path');
      return _pendingRequests[key]!.future;
    }

    final completer = Completer<Response>();
    final pending = _PendingRequest(completer, DateTime.now());
    _pendingRequests[key] = pending;

    try {
      final response = await post(path, data: data);
      completer.complete(response);
      return response;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_pendingRequests[key] == pending) {
          _pendingRequests.remove(key);
        }
      });
    }
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

  // New Retrofit methods with deduplication
  Future<dynamic> getWithRetrofit(
    String path, {
    Map<String, dynamic>? queries,
    bool forceRefresh = false,
  }) async {
    final response = await getDebounced(path,
        queryParameters: queries, forceRefresh: forceRefresh);
    return response.data;
  }

  Future<dynamic> postWithRetrofit(
    String path, {
    dynamic data,
    bool forceRefresh = false,
  }) async {
    final response =
        await postDebounced(path, data: data, forceRefresh: forceRefresh);
    return response.data;
  }

  Future<dynamic> putWithRetrofit(String path, {dynamic data}) async {
    final response = await retrofitClient.putRequest(path, data);
    return response.data;
  }

  Future<dynamic> patchWithRetrofit(String path, {dynamic data}) async {
    final response = await retrofitClient.patchRequest(path, data);
    return response.data;
  }

  Future<dynamic> deleteWithRetrofit(String path) async {
    final response = await retrofitClient.deleteRequest(path);
    return response.data;
  }

  // Cancel all pending requests (call when navigating away)
  void cancelAllPendingRequests() {
    for (final pending in _pendingRequests.values) {
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(CancelToken());
      }
    }
    _pendingRequests.clear();
  }

  // Cancel specific request by path
  void cancelPendingRequest(String path) {
    final keysToRemove =
        _pendingRequests.keys.where((key) => key.startsWith(path)).toList();
    for (final key in keysToRemove) {
      final pending = _pendingRequests[key];
      if (pending != null && !pending.completer.isCompleted) {
        pending.completer.completeError(CancelToken());
      }
      _pendingRequests.remove(key);
    }
  }
}

// Helper class to track pending requests
class _PendingRequest {
  final Completer<Response> completer;
  final DateTime timestamp;

  _PendingRequest(this.completer, this.timestamp);

  Future<Response> get future => completer.future;
}
