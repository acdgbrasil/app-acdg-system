/// HTTP client wrapper for BFF calls — Result-returning, never throws.
///
/// C02 contract:
///   * Constructor wires baseUrl + [CredentialStore] + optional [Dio] +
///     optional [TokenClient] / [OidcDiscovery] for refresh-on-401.
///   * Bearer interceptor reads the store on every outbound request so a
///     fresh access token (after a refresh) is picked up automatically.
///   * `get<T>` returns `Result<T>` — adapter exceptions never escape.
///   * On 401, if a [TokenClient] is wired AND a session is present:
///     refresh once, persist the rotated session, retry the request once
///     with the new bearer. `RefreshTokenInvalidError` clears the local
///     store and surfaces [AuthRequiredError]. The retry path is invoked
///     AT MOST ONCE per outbound request — no infinite loops.
///
/// C03 extension:
///   * `post<T>` mirrors `get<T>` — JSON-serialized body, same Bearer
///     interceptor, same 401 → refresh → retry-once invariant. The retry
///     resends the original body verbatim.
///
/// C04 extension:
///   * `put<T>` mirrors `post<T>` — same body+401 contract, dispatches PUT
///     on the wire.
///   * `delete<T>` mirrors `get<T>` for the wire shape (no body on the
///     public API), but dispatches DELETE.
///   * Both reuse the existing `_attempt`/`_refreshAndRetry` helpers; the
///     only new dispatch knob is the `method` string.
///
/// C08 extension:
///   * `patch<T>` mirrors `put<T>` — same body+401 contract, dispatches
///     PATCH on the wire. Required for `acdg lookup toggle` (the first
///     PATCH endpoint surfaced by Contract A — see
///     `apps/social_care_bff/lib/src/intents/governance/toggle_lookup_item_intent.dart`).
library;

import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';

import '../errors/cli_error.dart';
import '../oidc/oidc_discovery.dart';
import '../oidc/token_client.dart';
import 'credential_store.dart';
import 'oidc_session.dart';

/// Thin Dio wrapper that:
///   * injects Bearer tokens from the [CredentialStore],
///   * normalises every failure into a [CliError]-shaped [Failure],
///   * refreshes the access token once on 401 when a [TokenClient] is wired.
final class BffClient {
  BffClient({
    required this.baseUrl,
    required CredentialStore credentialStore,
    TokenClient? tokenClient,
    OidcDiscovery? discovery,
    Dio? dio,
  }) : _credentialStore = credentialStore,
       _tokenClient = tokenClient,
       _discovery = discovery,
       _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = await _credentialStore.read();
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
          handler.next(options);
        },
      ),
    );
  }

  final String baseUrl;
  final CredentialStore _credentialStore;
  final TokenClient? _tokenClient;

  /// Reserved for end_session / revoke wiring in C03+. Kept on the field
  /// roster (not just the constructor signature) so existing tests can
  /// pass `discovery:` and so a future verb can read it without changing
  /// the public API again.
  // ignore: unused_field
  final OidcDiscovery? _discovery;
  final Dio _dio;

  /// Issues `GET [path]` and returns a [Result].
  ///
  /// * Adapter throws → [Failure] wrapping a translated [CliError].
  /// * 2xx with a [decode] callback → [Success] wrapping the decoded value.
  /// * 2xx without [decode] → [Success] wrapping the raw response data
  ///   coerced to `T`.
  /// * 401 with a wired [TokenClient] → refresh + retry once.
  ///
  /// [queryParameters] are forwarded to Dio so the captured
  /// `RequestOptions.path` stays clean (e.g. `/lookups`) and the query string
  /// is reachable via `lastOptions.uri.queryParameters` — pinned by the C08
  /// `lookup batch` contract.
  Future<Result<T>> get<T>(
    String path, {
    T Function(Object? data)? decode,
    Map<String, Object?>? queryParameters,
  }) async {
    final firstAttempt = await _attempt<T>(
      method: 'GET',
      path: path,
      body: null,
      decode: decode,
      queryParameters: queryParameters,
    );
    return firstAttempt.flatMapWith(
      onSuccess: Success<T>.new,
      on401: () => _refreshAndRetry<T>(
        method: 'GET',
        path: path,
        body: null,
        decode: decode,
        queryParameters: queryParameters,
      ),
      onOther: Failure<T>.new,
    );
  }

  /// Issues `POST [path]` with [body] serialized as JSON and returns a [Result].
  ///
  /// Mirrors [get] semantics:
  ///   * Adapter throws → [Failure] wrapping a translated [CliError].
  ///   * 2xx with a [decode] callback → [Success] wrapping the decoded value.
  ///   * 2xx without [decode] → [Success] wrapping the raw response data
  ///     coerced to `T` (may be `null` on 204).
  ///   * 401 with a wired [TokenClient] → refresh + retry once with the
  ///     original [body].
  Future<Result<T>> post<T>(
    String path, {
    Object? body,
    T Function(Object? data)? decode,
  }) async {
    final firstAttempt = await _attempt<T>(
      method: 'POST',
      path: path,
      body: body,
      decode: decode,
    );
    return firstAttempt.flatMapWith(
      onSuccess: Success<T>.new,
      on401: () => _refreshAndRetry<T>(
        method: 'POST',
        path: path,
        body: body,
        decode: decode,
      ),
      onOther: Failure<T>.new,
    );
  }

  /// Issues `PUT [path]` with [body] serialized as JSON and returns a [Result].
  ///
  /// Mirrors [post] semantics — only the wire method differs.
  Future<Result<T>> put<T>(
    String path, {
    Object? body,
    T Function(Object? data)? decode,
  }) async {
    final firstAttempt = await _attempt<T>(
      method: 'PUT',
      path: path,
      body: body,
      decode: decode,
    );
    return firstAttempt.flatMapWith(
      onSuccess: Success<T>.new,
      on401: () => _refreshAndRetry<T>(
        method: 'PUT',
        path: path,
        body: body,
        decode: decode,
      ),
      onOther: Failure<T>.new,
    );
  }

  /// Issues `PATCH [path]` with [body] serialized as JSON and returns a [Result].
  ///
  /// Mirrors [put] semantics — only the wire method differs. PATCH carries
  /// idempotent partial updates (e.g. `lookup toggle` flipping the `active`
  /// flag); the verb keeps [body] optional so future PATCH endpoints can
  /// dispatch without a payload if the BFF intent is path-only.
  Future<Result<T>> patch<T>(
    String path, {
    Object? body,
    T Function(Object? data)? decode,
  }) async {
    final firstAttempt = await _attempt<T>(
      method: 'PATCH',
      path: path,
      body: body,
      decode: decode,
    );
    return firstAttempt.flatMapWith(
      onSuccess: Success<T>.new,
      on401: () => _refreshAndRetry<T>(
        method: 'PATCH',
        path: path,
        body: body,
        decode: decode,
      ),
      onOther: Failure<T>.new,
    );
  }

  /// Issues `DELETE [path]` and returns a [Result].
  ///
  /// Mirrors [get] semantics — no body is sent on the wire (DELETE per HTTP
  /// convention). The 401 retry path resends the same path with no body.
  Future<Result<T>> delete<T>(
    String path, {
    T Function(Object? data)? decode,
  }) async {
    final firstAttempt = await _attempt<T>(
      method: 'DELETE',
      path: path,
      body: null,
      decode: decode,
    );
    return firstAttempt.flatMapWith(
      onSuccess: Success<T>.new,
      on401: () => _refreshAndRetry<T>(
        method: 'DELETE',
        path: path,
        body: null,
        decode: decode,
      ),
      onOther: Failure<T>.new,
    );
  }

  /// Single HTTP attempt — used by every verb (GET/POST/PUT/DELETE/PATCH).
  /// Returns an [_Attempt] envelope so the refresh-retry orchestration stays
  /// linear.
  Future<_Attempt<T>> _attempt<T>({
    required String method,
    required String path,
    required Object? body,
    T Function(Object? data)? decode,
    Map<String, Object?>? queryParameters,
  }) async {
    try {
      // `validateStatus: (_) => true` keeps Dio from throwing on non-2xx;
      // we want full control over 401 detection (so the refresh-retry
      // path stays inside `_attempt`, never inside Dio's exception
      // machinery).
      // Read as bytes so Dio's transformer never JSON-decodes before we
      // see the status (a non-JSON 4xx body would otherwise blow up
      // before reaching the catch). We decode JSON ourselves on the
      // success path.
      final options = Options(
        method: method,
        validateStatus: (_) => true,
        responseType: ResponseType.bytes,
        // For POST with a body, set the JSON content-type so the BFF
        // and Dio's request transformer agree on the serialization.
        contentType: body != null ? Headers.jsonContentType : null,
      );
      final response = await _dio.request<List<int>>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: options,
      );
      final status = response.statusCode;
      if (status == 401) {
        return _Attempt<T>.unauthorized();
      }
      if (status == null || status < 200 || status >= 300) {
        return _Attempt<T>.failure(
          ServerError(status ?? 0, 'HTTP ${status ?? '<unknown>'}'),
        );
      }
      final raw = response.data;
      final bodyStr = raw is List<int> && raw.isNotEmpty
          ? utf8.decode(raw, allowMalformed: true)
          : '';
      final data = bodyStr.isNotEmpty ? _safeJsonDecode(bodyStr) : null;
      if (decode != null) {
        return _Attempt<T>.success(decode(data));
      }
      return _Attempt<T>.success(data as T);
    } on DioException catch (e, stack) {
      return _Attempt<T>.failure(_translate(e), stack: stack);
    }
  }

  /// Refreshes the access token (once) and retries the original request
  /// (once). The retry path returns Failure on persistent 401 — no recursion.
  Future<Result<T>> _refreshAndRetry<T>({
    required String method,
    required String path,
    required Object? body,
    T Function(Object? data)? decode,
    Map<String, Object?>? queryParameters,
  }) async {
    final tokenClient = _tokenClient;
    final session = await _credentialStore.read();
    if (tokenClient == null || session == null) {
      return const Failure(AuthRequiredError());
    }

    final refresh = await tokenClient.refresh(
      refreshToken: session.refreshToken,
    );

    switch (refresh) {
      case Failure(:final error):
        if (error is RefreshTokenInvalidError) {
          await _credentialStore.clear();
        }
        return const Failure(AuthRequiredError());
      case Success(:final value):
        final rotated = _rotate(session, value);
        await _credentialStore.write(rotated);
        // Retry exactly once — any second 401 is propagated as Failure
        // without recursion.
        final retry = await _attempt<T>(
          method: method,
          path: path,
          body: body,
          decode: decode,
          queryParameters: queryParameters,
        );
        return retry.flatMapWith(
          onSuccess: Success<T>.new,
          on401: () async => const Failure(AuthRequiredError()),
          onOther: Failure<T>.new,
        );
    }
  }

  Object? _safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  OidcSession _rotate(OidcSession previous, TokenResponse tokens) {
    final newExpiry = DateTime.now().toUtc().add(tokens.expiresIn);
    return OidcSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      idToken: tokens.idToken,
      accessExpiresAt: newExpiry,
      sub: previous.sub,
      email: previous.email,
      roles: previous.roles,
    );
  }

  /// Maps a [DioException] into the matching [CliError] variant.
  CliError _translate(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkError(e.message ?? 'connection failed');
      case DioExceptionType.badCertificate:
        return NetworkError(e.message ?? 'TLS handshake failed');
      case DioExceptionType.cancel:
        return NetworkError(e.message ?? 'request cancelled');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final status = e.response?.statusCode;
        if (status == 401) return const AuthRequiredError();
        if (status != null) {
          return ServerError(status, e.message ?? 'server error');
        }
        return NetworkError(e.message ?? 'unknown transport failure');
    }
  }
}

/// Internal sum type representing a single HTTP attempt outcome:
/// success, unauthorized (401), or other failure.
sealed class _Attempt<T> {
  const _Attempt();
  factory _Attempt.success(T value) = _Success<T>;
  factory _Attempt.unauthorized() = _Unauthorized<T>;
  factory _Attempt.failure(CliError error, {StackTrace? stack}) =
      _OtherFailure<T>;

  Future<Result<T>> flatMapWith({
    required Success<T> Function(T value) onSuccess,
    required Future<Result<T>> Function() on401,
    required Failure<T> Function(CliError error, {StackTrace? stackTrace})
    onOther,
  }) {
    final self = this;
    switch (self) {
      case _Success<T>(:final value):
        return Future.value(onSuccess(value));
      case _Unauthorized<T>():
        return on401();
      case _OtherFailure<T>(:final error, :final stack):
        return Future.value(onOther(error, stackTrace: stack));
    }
  }
}

final class _Success<T> extends _Attempt<T> {
  const _Success(this.value);
  final T value;
}

final class _Unauthorized<T> extends _Attempt<T> {
  const _Unauthorized();
}

final class _OtherFailure<T> extends _Attempt<T> {
  const _OtherFailure(this.error, {this.stack});
  final CliError error;
  final StackTrace? stack;
}
