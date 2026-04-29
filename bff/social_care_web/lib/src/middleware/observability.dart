import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shelf/shelf.dart';

import '../observability/observability_context.dart';

/// Sensitive query parameter names that MUST be stripped from breadcrumbs.
///
/// Aligned with Wave 0 REPORT — PII masking is enforced by tests.
const Set<String> _sensitiveQueryParams = {
  'code',
  'access_token',
  'refresh_token',
  'id_token',
  'token',
};

/// Creates the root observability middleware for the BFF Web shelf pipeline.
///
/// Responsibilities:
/// - Generate a fresh `requestId` (UUID v4) for each request.
/// - Inject the [ObservabilityContext] into [Request.context].
/// - Emit `request.received` and `request.completed` breadcrumbs.
/// - Catch unhandled exceptions, log them at severe level with stack trace,
///   and respond with a sanitized 500 (never leaking the exception message).
/// - Scrub sensitive data (OIDC code, tokens, session cookies) from logs.
Middleware observabilityMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final requestId = UuidUtil.generateV4();
      final obs = ObservabilityContext.forMiddleware(requestId: requestId);

      final forwarded = request.change(
        context: {requestIdContextKey: requestId, observabilityContextKey: obs},
      );

      final safePath = _scrubPath(request.requestedUri);
      obs.breadcrumb(
        'request.received',
        data: {'method': request.method, 'path': safePath},
      );

      final stopwatch = Stopwatch()..start();
      try {
        final response = await inner(forwarded);
        stopwatch.stop();
        obs.breadcrumb(
          'request.completed',
          data: {
            'status': response.statusCode,
            'ms': stopwatch.elapsedMilliseconds,
          },
        );
        return response;
      } on Object catch (error, stack) {
        stopwatch.stop();
        obs.logError(
          'unhandled exception in pipeline',
          cause: error,
          stack: stack,
        );
        obs.breadcrumb(
          'request.completed',
          data: {'status': 500, 'ms': stopwatch.elapsedMilliseconds},
        );
        return Response.internalServerError(
          body: jsonEncode({
            'error': {
              'code': 'INTERNAL',
              'message': 'Internal server error',
              'requestId': requestId,
            },
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}

/// Rebuilds a loggable path by stripping sensitive query parameters.
///
/// OIDC authorization codes and tokens arrive in the query string on
/// `/auth/callback` and similar endpoints. They must never end up in
/// breadcrumbs or log lines.
String _scrubPath(Uri uri) {
  if (uri.queryParameters.isEmpty) {
    return uri.path;
  }
  final safe = <String, String>{};
  for (final entry in uri.queryParameters.entries) {
    if (_sensitiveQueryParams.contains(entry.key.toLowerCase())) {
      safe[entry.key] = '***';
    } else {
      safe[entry.key] = entry.value;
    }
  }
  final buf = StringBuffer(uri.path);
  if (safe.isNotEmpty) {
    buf.write('?');
    buf.write(
      safe.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&'),
    );
  }
  return buf.toString();
}
