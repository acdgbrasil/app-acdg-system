import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../intents/admit_patient_intent.dart';
import '../intents/discharge_patient_intent.dart';
import '../intents/get_patient_intent.dart';
import '../intents/list_patients_intent.dart';
import '../intents/readmit_patient_intent.dart';
import '../intents/register_patient_intent.dart';
import '../intents/withdraw_patient_intent.dart';
import '../observability/observability_context.dart';
import '../use_cases/admit_patient_use_case.dart';
import '../use_cases/discharge_patient_use_case.dart';
import '../use_cases/get_patient_use_case.dart';
import '../use_cases/list_patients_use_case.dart';
import '../use_cases/readmit_patient_use_case.dart';
import '../use_cases/register_patient_use_case.dart';
import '../use_cases/withdraw_patient_use_case.dart';

/// Thin Registry (Patient) HTTP handler — A08 canonical pattern.
///
/// Responsibilities:
/// - Parse request (body + route params + query) into the matching Intent
///   via P2 if-case.
/// - Dispatch to the corresponding UseCase (state matrix — P1 switch on
///   result).
/// - Translate [Result] into sanitized shelf [Response]s.
///
/// Every handler pulls the per-request [ObservabilityContext] from
/// [Request.context] (with [ObservabilityContext.fromRequestOrNoop] as a
/// unit-test convenience — the production pipeline always installs the
/// middleware). UseCases emit the canonical breadcrumbs; the handler does
/// NOT duplicate them.
///
/// Error handling:
/// - `BackendError.http` maps to the HTTP status code.
/// - Registry-level "patient not found" [Failure] with a plain `String`
///   error (see `FakeRegistryBff.fetchPatient`) is translated to 404 here —
///   the upstream contract doesn't wrap that case in a `BackendError`.
/// - Invalid JSON / missing required fields → 400 with a PII-safe message
///   from the Intent's parser.
final class RegistryPatientHandler {
  const RegistryPatientHandler({
    required RegisterPatientUseCase register,
    required ListPatientsUseCase list,
    required GetPatientUseCase get,
    required AdmitPatientUseCase admit,
    required DischargePatientUseCase discharge,
    required ReadmitPatientUseCase readmit,
    required WithdrawPatientUseCase withdraw,
  }) : _register = register,
       _list = list,
       _get = get,
       _admit = admit,
       _discharge = discharge,
       _readmit = readmit,
       _withdraw = withdraw;

  final RegisterPatientUseCase _register;
  final ListPatientsUseCase _list;
  final GetPatientUseCase _get;
  final AdmitPatientUseCase _admit;
  final DischargePatientUseCase _discharge;
  final ReadmitPatientUseCase _readmit;
  final WithdrawPatientUseCase _withdraw;

  Router get router {
    final r = Router();
    r.post('/patients', _handleRegister);
    r.get('/patients', _handleList);
    r.get('/patients/<id>', _handleGet);
    r.post('/patients/<id>/admit', _handleAdmit);
    r.post('/patients/<id>/discharge', _handleDischarge);
    r.post('/patients/<id>/readmit', _handleReadmit);
    r.post('/patients/<id>/withdraw', _handleWithdraw);
    return r;
  }

  // ── POST /patients ─────────────────────────────────────────────────────

  Future<Response> _handleRegister(Request request) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = RegisterPatientIntent.parseFromBody(body);
    return switch (parsed) {
      Success(:final value) => _respondRegister(value, obs),
      Failure(:final error) => _badRequest(
        code: 'INVALID_REGISTER_BODY',
        message: error.toString(),
      ),
    };
  }

  Future<Response> _respondRegister(
    RegisterPatientIntent intent,
    ObservabilityContext obs,
  ) async {
    final result = await _register.execute(intent, obs);

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

  // ── GET /patients ──────────────────────────────────────────────────────

  Future<Response> _handleList(Request request) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    final intent = ListPatientsIntent.parseFromQuery(
      request.requestedUri.queryParameters,
    );

    final result = await _list.execute(intent, obs);
    return switch (result) {
      Success(:final value) => Response.ok(
        jsonEncode({
          'data': value.data.map((s) => s.toJson()).toList(),
          'meta': value.meta.toJson(),
        }),
        headers: _jsonHeaders,
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  // ── GET /patients/<id> ────────────────────────────────────────────────

  Future<Response> _handleGet(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    final parsed = GetPatientIntent.parseFromPath(id);
    return switch (parsed) {
      Failure(:final error) => _badRequest(
        code: 'INVALID_GET_PATIENT_PARAMS',
        message: error.toString(),
      ),
      Success(:final value) => await _runGet(value, obs),
    };
  }

  Future<Response> _runGet(
    GetPatientIntent intent,
    ObservabilityContext obs,
  ) async {
    final result = await _get.execute(intent, obs);
    return switch (result) {
      Success(:final value) => Response.ok(
        jsonEncode({'data': value.data.toJson(), 'meta': value.meta.toJson()}),
        headers: _jsonHeaders,
      ),
      Failure(:final error) => _patientNotFoundOrError(error),
    };
  }

  /// Maps a `GET /patients/{id}` failure to either 404 (when the upstream
  /// signals absence with a plain `String` error) or the full [_errorResponse]
  /// path for a structured [BackendError].
  Response _patientNotFoundOrError(Object error) {
    if (error is BackendError) return _errorResponse(error);
    // `FakeRegistryBff.fetchPatient` returns `Failure('Patient not found: ...')`
    // for missing IDs. Translate that to 404 without echoing the inner string
    // (which would include the raw patientId — UUIDs are non-PII, but the
    // message still feels too chatty for a public response).
    return Response(
      404,
      body: jsonEncode({
        'error': {'code': 'PATIENT_NOT_FOUND', 'message': 'Patient not found'},
      }),
      headers: _jsonHeaders,
    );
  }

  // ── POST /patients/<id>/admit ─────────────────────────────────────────

  Future<Response> _handleAdmit(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = AdmitPatientIntent.parseFromBody(id, body);
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _admit.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_ADMIT_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── POST /patients/<id>/discharge ─────────────────────────────────────

  Future<Response> _handleDischarge(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = DischargePatientIntent.parseFromBody(id, body);
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _discharge.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_DISCHARGE_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── POST /patients/<id>/readmit ───────────────────────────────────────

  Future<Response> _handleReadmit(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request) ?? const <String, dynamic>{};

    final parsed = ReadmitPatientIntent.parseFromBody(id, body);
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _readmit.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_READMIT_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── POST /patients/<id>/withdraw ──────────────────────────────────────

  Future<Response> _handleWithdraw(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = WithdrawPatientIntent.parseFromBody(id, body);
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _withdraw.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_WITHDRAW_BODY',
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
