import 'dart:convert';

import 'package:shared/shared.dart' show BackendError, BackendErrorResponse;
import 'package:shelf/shelf.dart';

import '../auth/session_store.dart';
import '../middleware/session_middleware.dart';

/// Factory that creates a sub-contract instance for a given [Session].
///
/// Returns the concrete sub-contract type expected by each handler
/// (`AuthContract`, `RegistryContract`, `AssessmentContract`, etc.).
/// Typed as `dynamic` so the same factory shape can be reused across
/// all handlers regardless of the specific contract they consume.
typedef ContractFactory = dynamic Function(Session session);

/// Extracts the [Session] from the request context.
/// Auth guard middleware ensures this is never null for protected routes.
Session getSession(Request request) =>
    request.context[sessionContextKey] as Session;

/// Parses the JSON body from a request.
Future<Map<String, dynamic>> readJsonBody(Request request) async {
  final body = await request.readAsString();
  return jsonDecode(body) as Map<String, dynamic>;
}

/// Creates a JSON success response with status 200.
Response jsonOk(Object? data) => Response.ok(
  jsonEncode(data),
  headers: {'Content-Type': 'application/json'},
);

/// Creates a JSON response with status 204 No Content.
Response jsonNoContent() => Response(204);

/// Creates a JSON error response.
Response jsonError(int status, String message) => Response(
  status,
  body: jsonEncode({'error': message}),
  headers: {'Content-Type': 'application/json'},
);

/// Creates an error [Response] from a [Failure]'s error object.
///
/// If the error is a [BackendErrorResponse], forwards the full structured error
/// with the original HTTP status code and all fields preserved.
/// If the error is a [BackendError], extracts HTTP status and message.
/// Otherwise falls back to 502 Bad Gateway.
Response backendError(Object error) {
  if (error is BackendErrorResponse) {
    return Response(
      error.error.http ?? 502,
      body: jsonEncode(error.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }
  if (error is BackendError) {
    return Response(
      error.http ?? 502,
      body: jsonEncode({
        'error': {'code': error.code, 'message': error.message},
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
  return jsonError(502, error.toString());
}
