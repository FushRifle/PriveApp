import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only retry on 429 or 5xx errors
    final shouldRetry = err.response?.statusCode == 429 ||
        (err.response?.statusCode ?? 500) >= 500;
    
    if (!shouldRetry || err.requestOptions.extra['retryCount'] == maxRetries) {
      return handler.next(err);
    }

    final retryCount = (err.requestOptions.extra['retryCount'] as int? ?? 0) + 1;
    final delay = baseDelay * (1 << (retryCount - 1)); // Exponential: 500ms, 1000ms, 2000ms

    await Future.delayed(delay);

    final options = err.requestOptions;
    options.extra['retryCount'] = retryCount;
    
    try {
      final response = await dio.fetch(options);
      return handler.resolve(response);
    } catch (e) {
      return handler.next(e as DioException);
    }
  }
}