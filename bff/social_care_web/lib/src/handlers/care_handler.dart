import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../intents/register_appointment_intent.dart';
import '../intents/update_intake_info_intent.dart';
import '../observability/observability_context.dart';
import '../use_cases/register_appointment_use_case.dart';
import '../use_cases/update_intake_info_use_case.dart';

/// Thin Care HTTP handler — A11 canonical pattern.
///
/// Responsibilities mirror [RegistryPatientHandler] / [AssessmentHandler]:
/// - Parse request (JSON body + route params) into the matching Intent via
///   P2 if-case (see ADR-019 + `PATTERN_MATCHING_POLICY.md §P2`).
/// - Dispatch to the corresponding UseCase (state matrix — P1 switch on
///   result).
/// - Translate [Result] into sanitized shelf [Response]s.
///
/// Every handler pulls the per-request [ObservabilityContext] via
/// [ObservabilityContext.fromRequestOrNoop] — the production pipeline
/// always installs the middleware; the Noop fallback keeps unit tests
/// that call `router.call(request)` directly thin.
///
/// Error handling:
/// - `BackendError.http` → the HTTP status code (upstream passthrough).
/// - Non-`BackendError` failures → 500 `INTERNAL` WITHOUT echoing the
///   inner Dart exception message or stack trace.
/// - Invalid JSON / missing required fields → 400 with a PII-safe message
///   from the Intent's parser (one dedicated code per route).
final class CareHandler {
  const CareHandler({
    required RegisterAppointmentUseCase registerAppointment,
    required UpdateIntakeInfoUseCase updateIntakeInfo,
  }) : _registerAppointment = registerAppointment,
       _updateIntakeInfo = updateIntakeInfo;

  final RegisterAppointmentUseCase _registerAppointment;
  final UpdateIntakeInfoUseCase _updateIntakeInfo;

  Router get router {
    final r = Router();
    r.post('/patients/<id>/appointments', _handleRegisterAppointment);
    r.put('/patients/<id>/intake', _handleUpdateIntakeInfo);
    return r;
  }

  // ── POST /patients/<id>/appointments ──────────────────────────────────

  Future<Response> _handleRegisterAppointment(
    Request request,
    String id,
  ) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = RegisterAppointmentIntent.parseFromBody(id, body);
    return switch (parsed) {
      Success(:final value) => _respondWithId(
        await _registerAppointment.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_APPOINTMENT_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /patients/<id>/intake ─────────────────────────────────────────

  Future<Response> _handleUpdateIntakeInfo(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = UpdateIntakeInfoIntent.parseFromBody(id, body);
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _updateIntakeInfo.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_INTAKE_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  static const Map<String, String> _jsonHeaders = {
    'content-type': 'application/json',
  };

  /// Reads the request body as JSON, returning `null` if the body is not
  /// valid JSON. We deliberately DO NOT rethrow so the handler can map the
  /// failure to a clean 400 without a Dart stack trace leaking.
  Future<Map<String, dynamic>?> _readJsonBody(Request request) async {
    try {
      final raw = await request.readAsString();
      if (raw.isEmpty) return const <String, dynamic>{};
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } on FormatException {
      return null;
    }
  }

  Response _respondWithId(Result<StandardIdResponse> result) {
    return switch (result) {
      Success(:final value) => Response.ok(
        jsonEncode({
          'data': {'id': value.data.id},
          'meta': value.meta.toJson(),
        }),
        headers: _jsonHeaders,
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  Response _wrapVoidResult(Result<StandardResponse<void>> result) {
    return switch (result) {
      Success(:final value) => Response.ok(
        jsonEncode({'data': null, 'meta': value.meta.toJson()}),
        headers: _jsonHeaders,
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  Response _errorResponse(Object error) {
    final (status, code, message) = _extractError(error);
    return Response(
      status,
      body: jsonEncode({
        'error': {'code': code, 'message': message},
      }),
      headers: _jsonHeaders,
    );
  }

  (int, String, String) _extractError(Object error) {
    if (error is BackendError) {
      return (error.http ?? 500, error.code, error.message);
    }
    // Non-BackendError failures: never echo the raw message, which might
    // carry stack trace text or inner exception prose from the adapter.
    return (500, 'INTERNAL', 'Internal server error');
  }

  Response _badRequest({required String code, required String message}) {
    return Response(
      400,
      body: jsonEncode({
        'error': {'code': code, 'message': message},
      }),
      headers: _jsonHeaders,
    );
  }
}
