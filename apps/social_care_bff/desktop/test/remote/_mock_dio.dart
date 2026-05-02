/// MockDio — a minimal `Dio` test double.
///
/// Lifted from the legacy `test/social_care_bff_remote_test.dart` (lines
/// 6-122), extended with:
///   * `lastMethod` — verb captured by the last call (`GET`/`POST`/...)
///   * `lastQueryParameters` — query map (used by paginated/audit endpoints)
///   * `lastOptions` — to introspect Dio `Options` (e.g. `validateStatus`)
///   * `nextStatusCode` — programmable HTTP status for the next call
///   * `nextResponseData` — programmable body returned by the next call
///   * `nextThrow` — programmable `Object` thrown by the next call (covers
///     the network-failure branch where `Dio` throws and the remote must
///     map it to `Failure(e)`)
///
/// Uses `noSuchMethod` to dodge mocktail boilerplate. Each method override
/// resets only the *captured* fields it can populate — programmable fields
/// stay until the test reassigns them. This keeps per-test setup minimal
/// while still allowing chained calls.
library;

import 'package:dio/dio.dart';

class MockDio implements Dio {
  // ── Captured state from the last call ────────────────────────────────
  String? lastMethod;
  String? lastPath;
  Object? lastBody;
  Map<String, dynamic>? lastQueryParameters;
  Options? lastOptions;

  // ── Programmable response for the NEXT call ──────────────────────────
  int nextStatusCode = 200;
  Object? nextResponseData;
  Object? nextThrow;

  @override
  BaseOptions options = BaseOptions();

  @override
  Interceptors get interceptors => Interceptors();

  void _capture({
    required String method,
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    lastMethod = method;
    lastPath = path;
    lastBody = data;
    lastQueryParameters = queryParameters;
    lastOptions = options;
  }

  Response<T> _buildResponse<T>(String path) => Response<T>(
    requestOptions: RequestOptions(path: path),
    statusCode: nextStatusCode,
    data: nextResponseData as T?,
  );

  void _maybeThrow() {
    if (nextThrow != null) {
      final e = nextThrow!;
      // Reset so a single test can't accidentally throw twice in a row
      // unless it explicitly resets the field.
      nextThrow = null;
      throw e;
    }
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    _capture(
      method: 'GET',
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    _maybeThrow();
    return _buildResponse<T>(path);
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    _capture(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    _maybeThrow();
    return _buildResponse<T>(path);
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    _capture(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    _maybeThrow();
    return _buildResponse<T>(path);
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    _capture(
      method: 'PATCH',
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    _maybeThrow();
    return _buildResponse<T>(path);
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    _capture(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    _maybeThrow();
    return _buildResponse<T>(path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Canonical fixtures used across remote tests ──────────────────────

/// A representative `BackendErrorResponse` JSON body that the remote
/// must round-trip into `Failure(BackendErrorResponse)` when status is
/// non-2xx and the body has the `error` key.
Map<String, dynamic> kBackendErrorBody({
  String code = 'PAT-001',
  String message = 'Patient not found',
  int http = 404,
}) => <String, dynamic>{
  'error': <String, dynamic>{
    'id': 'err-${code.toLowerCase()}',
    'code': code,
    'message': message,
    'http': http,
  },
};

/// A backend body with no `error` key but with a `message`. Used to
/// verify the fallback path (`UNKNOWN` code, message preserved).
Map<String, dynamic> kFallbackErrorBody({String message = 'Boom'}) =>
    <String, dynamic>{'message': message};

/// A canonical `StandardIdResponse` payload for create endpoints.
Map<String, dynamic> kIdResponseBody(String id) => <String, dynamic>{
  'data': <String, dynamic>{'id': id},
  'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
};
