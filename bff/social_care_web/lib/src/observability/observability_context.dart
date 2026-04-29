import 'package:core_contracts/core_contracts.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

/// Key under which the [ObservabilityContext] is stored in [Request.context].
const String observabilityContextKey = 'observability';

/// Key under which the correlation `requestId` is stored in [Request.context].
const String requestIdContextKey = 'requestId';

/// A single breadcrumb captured while handling a request.
///
/// Breadcrumbs are structured, forward-compatible events that describe what
/// happened at each point of a request/UseCase chain. They are the backbone
/// of the BFF observability canon and MUST be PII-free (see Wave 0 REPORT).
final class BreadcrumbRecord with Equatable {
  BreadcrumbRecord({
    required this.event,
    required this.timestamp,
    Map<String, Object?> data = const {},
  }) : data = Map.unmodifiable(data);

  /// Canonical event name (e.g. `auth.login.received`, `request.completed`).
  final String event;

  /// When the breadcrumb was captured (UTC).
  final DateTime timestamp;

  /// Structured payload accompanying the event. MUST NOT contain raw PII
  /// (OIDC code, access/refresh tokens, session IDs, emails).
  final Map<String, Object?> data;

  @override
  List<Object?> get props => [event, timestamp, data];
}

/// Per-request observability scope.
///
/// Created by [observabilityMiddleware] and attached to every [Request] via
/// [Request.context]. Handlers/UseCases retrieve it with
/// [ObservabilityContext.of] and emit breadcrumbs through
/// [ObservabilityContext.breadcrumb].
///
/// In tests, [ObservabilityContext.noop] captures breadcrumbs in memory for
/// inspection without requiring AcdgLogger/Sentry wiring.
///
/// The `of` factory MUST be called within a request that has passed through
/// the middleware — otherwise it calls [unreachable] (P4) to fail fast.
final class ObservabilityContext {
  ObservabilityContext._({required this.requestId})
    : _breadcrumbs = <BreadcrumbRecord>[];

  /// Retrieves the [ObservabilityContext] attached to [request].
  ///
  /// Calling without having passed through [observabilityMiddleware] first
  /// is a programming error and surfaces via [unreachable] (P4).
  factory ObservabilityContext.of(Request request) {
    final ctx = request.context[observabilityContextKey];
    if (ctx is ObservabilityContext) {
      return ctx;
    }
    unreachable(
      'ObservabilityContext missing from request.context — was '
      'observabilityMiddleware() added to the pipeline?',
      module: 'bff-web/observability',
    );
  }

  /// Creates an in-memory context for tests (no real logger wiring).
  ///
  /// Breadcrumbs recorded via [breadcrumb] are captured in [breadcrumbs]
  /// for later assertion. [logError] is a no-op under noop.
  factory ObservabilityContext.noop({String requestId = 'test-request'}) {
    return ObservabilityContext._(requestId: requestId);
  }

  /// Same as [ObservabilityContext.of] but silently falls back to
  /// [ObservabilityContext.noop] when the middleware was not installed.
  ///
  /// Intended for handlers that are exercised both by the real shelf
  /// pipeline (middleware present) and by unit tests calling
  /// `router.call(request)` directly (no middleware). The real pipeline is
  /// still the authoritative wiring; this factory only tolerates the unit
  /// test surface so the handler stays thin.
  factory ObservabilityContext.fromRequestOrNoop(Request request) {
    final ctx = request.context[observabilityContextKey];
    if (ctx is ObservabilityContext) return ctx;
    return ObservabilityContext.noop();
  }

  /// Internal factory used by [observabilityMiddleware]. Not exposed as a
  /// public API — access to a freshly-minted context always flows through
  /// [Request.context].
  static ObservabilityContext forMiddleware({required String requestId}) {
    return ObservabilityContext._(requestId: requestId);
  }

  /// Correlation id propagated across middleware, handlers and UseCases.
  final String requestId;

  final List<BreadcrumbRecord> _breadcrumbs;

  /// Unmodifiable view of all breadcrumbs recorded so far.
  List<BreadcrumbRecord> get breadcrumbs =>
      List<BreadcrumbRecord>.unmodifiable(_breadcrumbs);

  /// Records a breadcrumb with the given [event] name and optional [data].
  ///
  /// Also forwards to [Logger.root] at info level so that AcdgLogger +
  /// Sentry can pick it up when running in production. Handlers/UseCases
  /// are responsible for passing PII-safe [data].
  void breadcrumb(String event, {Map<String, Object?> data = const {}}) {
    final record = BreadcrumbRecord(
      event: event,
      timestamp: DateTime.now().toUtc(),
      data: data,
    );
    _breadcrumbs.add(record);
    Logger.root.info('bc: $event requestId=$requestId data=$data');
  }

  /// Logs an unhandled error with [cause] and [stack] at severe level.
  ///
  /// This is the canonical way to surface unexpected failures from the BFF
  /// pipeline. The middleware uses this to record exceptions before
  /// converting them into sanitized 500 responses.
  void logError(String message, {Object? cause, StackTrace? stack}) {
    Logger.root.severe('$message requestId=$requestId', cause, stack);
  }
}
