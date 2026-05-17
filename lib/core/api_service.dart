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

  String? _authToken;
  final Map<String, _PendingRequest> _pendingRequests = {};

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
      ),
    );
    retrofitClient = RetrofitClient(dio);
    _setupInterceptors();
  }

  void setAuthToken(String token) {
    _authToken = token;
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _authToken = null;
    dio.options.headers.remove('Authorization');
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = SupabaseConfig.client.auth.currentSession;
          final token = session?.accessToken ?? _authToken;

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  String _getRequestKey(String path, Map<String, dynamic>? queryParameters,
      {dynamic data}) {
    final queryStr = queryParameters?.toString() ?? '';
    final dataStr = data != null ? data.toString() : '';
    return '$path|$queryStr|$dataStr';
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

  // Deduplicated GET request
  Future<dynamic> getDebounced(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool forceRefresh = false,
  }) async {
    final key = _getRequestKey(path, queryParameters);

    if (!forceRefresh && _pendingRequests.containsKey(key)) {
      return _pendingRequests[key]!.future;
    }

    final completer = Completer<dynamic>();
    final pending = _PendingRequest(completer, DateTime.now());
    _pendingRequests[key] = pending;

    try {
      final response = await get(path, queryParameters: queryParameters);
      completer.complete(response.data);
      return response.data;
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

  // Deduplicated POST request
  Future<dynamic> postDebounced(
    String path, {
    dynamic data,
    bool forceRefresh = false,
  }) async {
    final key = _getRequestKey(path, null, data: data);

    if (!forceRefresh && _pendingRequests.containsKey(key)) {
      return _pendingRequests[key]!.future;
    }

    final completer = Completer<dynamic>();
    final pending = _PendingRequest(completer, DateTime.now());
    _pendingRequests[key] = pending;

    try {
      final response = await post(path, data: data);
      completer.complete(response.data);
      return response.data;
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

  void cancelAllPendingRequests() {
    for (final pending in _pendingRequests.values) {
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(CancelToken());
      }
    }
    _pendingRequests.clear();
  }
}

class _PendingRequest {
  final Completer<dynamic> completer;
  final DateTime timestamp;

  _PendingRequest(this.completer, this.timestamp);

  Future<dynamic> get future => completer.future;
}
