import 'dart:isolate';

import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

/// Optional token-provider hook used when wiring a real `Dio` client in
/// production. Tests inject `Dio` directly via the remote constructors,
/// so the provider is irrelevant to the GREEN suite.
typedef TokenProvider = String? Function();

/// Shared base for the 7 sub-contract remotes (A16-v2).
///
/// Stateless helpers extracted from the legacy
/// `SocialCareBffRemote` (god-class deleted in A16-v2). Each concrete
/// remote `extends RemoteBase`, gets the `Dio` client, and uses the
/// helpers to:
///
///   * map non-2xx responses with a `{ "error": {...} }` body to
///     `Failure(BackendErrorResponse)` — falling back to a synthetic
///     `UNKNOWN`-coded error when the body is unstructured;
///   * wrap a parsed payload into `StandardResponse<T>` with a fresh
///     `ResponseMeta(timestamp: ...)`;
///   * extract a `StandardIdResponse` (`{"data": {"id": ...}, "meta": {...}}`).
///
/// `validateStatus: (_) => true` is reused everywhere — non-2xx are
/// surfaced as `Response` objects (not throws), so error mapping is
/// linear and tests don't need to fake `DioException`.
abstract class RemoteBase {
  RemoteBase({required this.dio});

  /// Production helper that wires a `Dio` client with `X-Actor-Id` and
  /// optional `Authorization` interceptor. Tests bypass this and pass
  /// their own `MockDio` directly to a remote constructor.
  static Dio buildDio({
    required String baseUrl,
    required String actorId,
    TokenProvider? tokenProvider,
    String? authToken,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: <String, String>{
          'X-Actor-Id': actorId,
          'Content-Type': 'application/json',
        },
      ),
    );
    final effectiveProvider = tokenProvider ?? () => authToken;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = effectiveProvider();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
    return dio;
  }

  /// The `Dio` client used by every concrete remote. Exposed so the
  /// remotes can call `dio.get/post/put/patch/delete` directly without
  /// going through delegation boilerplate.
  final Dio dio;

  /// Convenience `Options` that surface every status code as a
  /// `Response` (no throws). Reused across every endpoint so the
  /// error-mapping branch is always linear.
  static final Options passthroughStatus = Options(validateStatus: (_) => true);

  /// Maps a non-2xx [response] to a `Failure<T>(BackendErrorResponse)`.
  ///
  /// If the body has the `{"error": {...}}` shape we round-trip it
  /// through `BackendErrorResponse.fromJson`. Otherwise we synthesize a
  /// `BackendErrorResponse` with code `UNKNOWN`, preserving the HTTP
  /// status and falling back to [fallbackMessage] for the body's
  /// description.
  Failure<T> backendFailure<T>(
    Response<dynamic> response,
    String fallbackMessage,
  ) {
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      try {
        return Failure<T>(BackendErrorResponse.fromJson(data));
      } catch (_) {
        // Fall through to UNKNOWN synthesis below.
      }
    }
    final message = (data is Map<String, dynamic>)
        ? (data['message'] as String? ?? fallbackMessage)
        : fallbackMessage;
    return Failure<T>(
      BackendErrorResponse(
        error: BackendError(
          id: '',
          code: 'UNKNOWN',
          message: message,
          http: response.statusCode ?? 502,
        ),
      ),
    );
  }

  /// Wraps a parsed payload into `StandardResponse<T>` with a fresh
  /// `ResponseMeta(timestamp: <now>)`.
  StandardResponse<T> wrapResponse<T>(T data) => StandardResponse<T>(
    data: data,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  /// Synthesizes a `StandardResponse<void>` for 204 endpoints whose
  /// return type is `StandardResponse<void>` (lookup item / governance
  /// admin operations). The backend returns no body, so we mint a
  /// `meta` envelope client-side.
  StandardResponse<void> wrapVoid() => StandardResponse<void>(
    data: null,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  /// Extracts a `StandardIdResponse` from a `{"data": {"id": ...}, "meta": {...}}`
  /// body. The `meta.timestamp` is preserved when present; otherwise we
  /// synthesize one (consistent with the legacy behavior).
  StandardIdResponse extractIdResponse(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>;
    final meta = body['meta'] as Map<String, dynamic>?;
    return StandardResponse<IdData>(
      data: IdData(id: data['id'] as String),
      meta: ResponseMeta(
        timestamp:
            meta?['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Threshold above which list-mapping is delegated to a background
  /// isolate to keep the main isolate (UI / event loop) free.
  ///
  /// Per `handbook/architecture/CONCURRENCY_AND_PERFORMANCE_POLICY.md`
  /// §C1: Isolate spin-up costs ~0.5–2ms; below this threshold, inline
  /// mapping is faster overall. Above it, the main-thread freeze that
  /// inline mapping would cause exceeds the spawn cost — Isolate wins.
  static const int isolateMappingThreshold = 50;

  /// Maps a `List<dynamic>` of JSON-decoded maps into a typed
  /// `List<T>` via [fromJson]. When [rawList] has more than
  /// [isolateMappingThreshold] entries, delegates to [Isolate.run] so
  /// the per-item `fromJson` work runs off the main isolate.
  ///
  /// **Sendable contract:** [fromJson] MUST be a top-level function or
  /// static-method tear-off (e.g.
  /// `PatientSummaryResponse.fromJson`) — closures with captured state
  /// are NOT sendable across isolate boundaries.
  ///
  /// **Behavior contract:** the returned `List<T>` is observationally
  /// identical to `rawList.cast<Map<String, dynamic>>().map(fromJson).toList()`
  /// — same length, same order, same field values. Only the executing
  /// isolate differs (regression-tested at the call site).
  ///
  /// Introduced by T1.2 (2026-05-01) — see
  /// `handbook/audit/2026-05-01-bff-comprehensive/05-isolates-opportunities.md`.
  static Future<List<T>> mapListPossiblyInIsolate<T>(
    List<dynamic> rawList,
    T Function(Map<String, dynamic>) fromJson, {
    int threshold = isolateMappingThreshold,
  }) async {
    if (rawList.length <= threshold) {
      return rawList.cast<Map<String, dynamic>>().map(fromJson).toList();
    }
    return Isolate.run<List<T>>(
      () => rawList.cast<Map<String, dynamic>>().map(fromJson).toList(),
    );
  }
}
