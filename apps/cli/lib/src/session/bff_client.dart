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
  Future<Result<T>> get<T>(
    String path, {
    T Function(Object? data)? decode,
  }) async {
    final firstAttempt = await _attemptGet<T>(path, decode: decode);
    return firstAttempt.flatMapWith(
      onSuccess: Success<T>.new,
      on401: () => _refreshAndRetryGet<T>(path, decode: decode),
      onOther: Failure<T>.new,
    );
  }

  Future<_Attempt<T>> _attemptGet<T>(
    String path, {
    T Function(Object? data)? decode,
  }) async {
    try {
      // `validateStatus: (_) => true` keeps Dio from throwing on non-2xx;
      // we want full control over 401 detection (so the refresh-retry
      // path stays inside `_attemptGet`, never inside Dio's exception
      // machinery). Errors from transport / parsing are still surfaced
      // as `DioException`.
      // Read as bytes so Dio's transformer never JSON-decodes before we
      // see the status (a non-JSON 4xx body would otherwise blow up
      // before reaching the catch). We decode JSON ourselves on the
      // success path.
      final response = await _dio.get<List<int>>(
        path,
        options: Options(
          validateStatus: (_) => true,
          responseType: ResponseType.bytes,
        ),
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
      final body = raw is List<int> && raw.isNotEmpty
          ? utf8.decode(raw, allowMalformed: true)
          : '';
      final data = body.isNotEmpty ? _safeJsonDecode(body) : null;
      if (decode != null) {
        return _Attempt<T>.success(decode(data));
      }
      return _Attempt<T>.success(data as T);
    } on DioException catch (e, stack) {
      return _Attempt<T>.failure(_translate(e), stack: stack);
    }
  }

  Future<Result<T>> _refreshAndRetryGet<T>(
    String path, {
    T Function(Object? data)? decode,
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
        final retry = await _attemptGet<T>(path, decode: decode);
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

/// Internal sum type representing a single GET attempt outcome:
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
