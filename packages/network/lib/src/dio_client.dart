import 'package:dio/dio.dart';

/// Configured HTTP client for API communication.
///
/// Provides interceptors for:
/// - Auth token injection
/// - Request/response logging
/// - Retry on transient failures
class DioClient {
  DioClient({
    required String baseUrl,
    String? authToken,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: connectTimeout,
           receiveTimeout: receiveTimeout,
           headers: {
             'Content-Type': 'application/json',
             'Accept': 'application/json',
           },
         ),
       ) {
    if (authToken != null) {
      setAuthToken(authToken);
    }
    _dio.interceptors.add(_LoggingInterceptor());
    _dio.interceptors.add(_RetryInterceptor(dio: _dio));
  }

  final Dio _dio;

  /// Access the underlying Dio instance for advanced configuration.
  Dio get dio => _dio;

  /// Updates the Bearer token used for authenticated requests.
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Removes the auth token (e.g., on logout).
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      _dio.delete<T>(path, data: data);
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[DIO] ${options.method} ${options.uri}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[DIO] ERROR ${err.response?.statusCode} ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  static const int maxRetries = 2;

  _RetryInterceptor({required this.dio});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final shouldRetry = _isRetryable(err);
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    if (shouldRetry && retryCount < maxRetries) {
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      final delay = Duration(milliseconds: 500 * (retryCount + 1));
      await Future<void>.delayed(delay);

      try {
        final response = await dio.fetch<dynamic>(err.requestOptions);
        handler.resolve(response);
        return;
      } on DioException catch (e) {
        handler.next(e);
        return;
      }
    }

    handler.next(err);
  }

  bool _isRetryable(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}
