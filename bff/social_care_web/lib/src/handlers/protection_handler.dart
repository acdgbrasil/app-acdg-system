import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../intents/create_referral_intent.dart';
import '../intents/report_rights_violation_intent.dart';
import '../intents/update_placement_history_intent.dart';
import '../observability/observability_context.dart';
import '../use_cases/create_referral_use_case.dart';
import '../use_cases/report_rights_violation_use_case.dart';
import '../use_cases/update_placement_history_use_case.dart';

/// Thin Protection HTTP handler — A12 canonical pattern.
///
/// Unique trait: this handler mixes two parse strategies behind a single
/// uniform shape:
/// - Referral + Violation use **P2 if-case** (3 required top-level strings,
///   PII confined to dynamic-message field-name enumeration — mirror of
///   A11 Intake).
/// - PlacementHistory uses **P2b try/catch** (0 top-level required, nested
///   sub-DTOs with their own required tuples, PII-dense free-narrative —
///   mirror of A10 Housing). `parseFromBody` receives the per-request
///   `obs:` so parse failures route through `logError` without crossing
///   layer boundaries.
///
/// Responsibilities (identical to [RegistryPatientHandler] /
/// [AssessmentHandler] / [CareHandler]):
/// - Parse request (JSON body + route params) into the matching Intent.
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
final class ProtectionHandler {
  const ProtectionHandler({
    required CreateReferralUseCase createReferral,
    required ReportRightsViolationUseCase reportViolation,
    required UpdatePlacementHistoryUseCase updatePlacementHistory,
  }) : _createReferral = createReferral,
       _reportViolation = reportViolation,
       _updatePlacementHistory = updatePlacementHistory;

  final CreateReferralUseCase _createReferral;
  final ReportRightsViolationUseCase _reportViolation;
  final UpdatePlacementHistoryUseCase _updatePlacementHistory;

  Router get router {
    final r = Router();
    r.post('/patients/<id>/referrals', _handleCreateReferral);
    r.post('/patients/<id>/violations', _handleReportViolation);
    r.put('/patients/<id>/placement-history', _handleUpdatePlacementHistory);
    return r;
  }

  // ── POST /patients/<id>/referrals ─────────────────────────────────────

  Future<Response> _handleCreateReferral(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = CreateReferralIntent.parseFromBody(id, body);
    return switch (parsed) {
      Success(:final value) => _respondWithId(
        await _createReferral.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_REFERRAL_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── POST /patients/<id>/violations ────────────────────────────────────

  Future<Response> _handleReportViolation(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = ReportRightsViolationIntent.parseFromBody(id, body);
    return switch (parsed) {
      Success(:final value) => _respondWithId(
        await _reportViolation.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_VIOLATION_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /patients/<id>/placement-history ──────────────────────────────

  Future<Response> _handleUpdatePlacementHistory(
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

    // P2b canon — pass obs so the catch branch can logError without
    // crossing the layer boundary.
    final parsed = UpdatePlacementHistoryIntent.parseFromBody(
      id,
      body,
      obs: obs,
    );
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _updatePlacementHistory.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_PLACEMENT_HISTORY_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── Helpers (verbatim copy of RegistryPatientHandler / CareHandler) ──

  static const Map<String, String> _jsonHeaders = {
    'content-type': 'application/json',
  };

  /// Reads the request body as JSON. Returns `null` on malformed input so
  /// the caller can emit a clean 400 without a Dart stack trace leaking.
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
