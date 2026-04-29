import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../intents/assign_role_intent.dart';
import '../intents/deactivate_role_intent.dart';
import '../intents/deactivate_worker_intent.dart';
import '../intents/get_team_member_intent.dart';
import '../intents/list_team_intent.dart';
import '../intents/reactivate_role_intent.dart';
import '../intents/reactivate_worker_intent.dart';
import '../intents/register_worker_intent.dart';
import '../intents/reset_password_intent.dart';
import '../observability/observability_context.dart';
import '../use_cases/assign_role_use_case.dart';
import '../use_cases/deactivate_role_use_case.dart';
import '../use_cases/deactivate_worker_use_case.dart';
import '../use_cases/get_team_member_use_case.dart';
import '../use_cases/list_team_use_case.dart';
import '../use_cases/reactivate_role_use_case.dart';
import '../use_cases/reactivate_worker_use_case.dart';
import '../use_cases/register_worker_use_case.dart';
import '../use_cases/reset_password_use_case.dart';

/// Thin Team HTTP handler — A15 canonical pattern (Onda 3 closer).
///
/// Topology hidden by design: this handler exposes ONLY `/team/*` routes.
/// The legacy `/team/people/*` and `/people/by-cpf/*` surfaces have been
/// removed — orchestration with PeopleContext is fully encapsulated
/// behind [TeamContract.registerWorker], so the APP no longer leaks
/// awareness that "team members" are stored in two places.
///
/// Parse strategies exercised:
/// - **Path-only** (GET `/team/<id>`, PUT `/team/<id>/{de,re}activate`,
///   POST `/team/<id>/reset-password`, PUT `/team/<id>/roles/<rid>/...`)
///   — no `parseFromBody`; the intent is built straight from the route.
/// - **Query-tolerant** (GET `/team`) — A15 introduced this variant.
///   All filters are optional. Failure surfaces only when a present
///   filter is malformed (e.g. `active=abc`) or oversized; absent
///   filters are valid input.
/// - **P2 if-case** with 3 required (POST `/team` — register worker)
///   and with 2 required (POST `/team/<id>/roles` — assign role) —
///   dynamic parse error enumerating the missing field names.
///
/// Error code convention (BFF Web canon — see `LookupHandler` dartdoc):
/// - **Local 400 codes** are `INVALID_*` — emitted when the request
///   never reaches the upstream contract (parse failures, JSON malformed,
///   query-string validation).
/// - **Upstream codes** (e.g. `EMAIL_TAKEN`, `ROLE_CONFLICT`) are passed
///   through transparently from `BackendError` via [_extractError].
final class TeamHandler {
  const TeamHandler({
    required ListTeamUseCase listTeam,
    required RegisterWorkerUseCase registerWorker,
    required GetTeamMemberUseCase getTeamMember,
    required DeactivateWorkerUseCase deactivateWorker,
    required ReactivateWorkerUseCase reactivateWorker,
    required ResetPasswordUseCase resetPassword,
    required AssignRoleUseCase assignRole,
    required DeactivateRoleUseCase deactivateRole,
    required ReactivateRoleUseCase reactivateRole,
  }) : _listTeam = listTeam,
       _registerWorker = registerWorker,
       _getTeamMember = getTeamMember,
       _deactivateWorker = deactivateWorker,
       _reactivateWorker = reactivateWorker,
       _resetPassword = resetPassword,
       _assignRole = assignRole,
       _deactivateRole = deactivateRole,
       _reactivateRole = reactivateRole;

  final ListTeamUseCase _listTeam;
  final RegisterWorkerUseCase _registerWorker;
  final GetTeamMemberUseCase _getTeamMember;
  final DeactivateWorkerUseCase _deactivateWorker;
  final ReactivateWorkerUseCase _reactivateWorker;
  final ResetPasswordUseCase _resetPassword;
  final AssignRoleUseCase _assignRole;
  final DeactivateRoleUseCase _deactivateRole;
  final ReactivateRoleUseCase _reactivateRole;

  Router get router {
    final r = Router();
    r.get('/team', _handleListTeam);
    r.post('/team', _handleRegisterWorker);
    r.get('/team/<id>', _handleGetMember);
    r.put('/team/<id>/deactivate', _handleDeactivateWorker);
    r.put('/team/<id>/reactivate', _handleReactivateWorker);
    r.post('/team/<id>/reset-password', _handleResetPassword);
    r.post('/team/<id>/roles', _handleAssignRole);
    r.put('/team/<id>/roles/<roleId>/deactivate', _handleDeactivateRole);
    r.put('/team/<id>/roles/<roleId>/reactivate', _handleReactivateRole);
    return r;
  }

  // ── GET /team (query-tolerant) ────────────────────────────────────────

  Future<Response> _handleListTeam(Request request) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final parsed = ListTeamIntent.parseFromQuery(request.url.queryParameters);
    return switch (parsed) {
      Success(:final value) => await _runListTeam(value, obs),
      Failure(:final error) => _badRequest(
        code: 'INVALID_LIST_TEAM_QUERY',
        message: error.toString(),
      ),
    };
  }

  Future<Response> _runListTeam(
    ListTeamIntent intent,
    ObservabilityContext obs,
  ) async {
    final result = await _listTeam.execute(intent, obs);
    return switch (result) {
      Success(:final value) => Response.ok(
        jsonEncode({
          'data': value.data.map((m) => m.toJson()).toList(),
          'meta': value.meta.toJson(),
        }),
        headers: _jsonHeaders,
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  // ── POST /team ────────────────────────────────────────────────────────

  Future<Response> _handleRegisterWorker(Request request) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = RegisterWorkerIntent.parseFromBody(body);
    return switch (parsed) {
      Success(:final value) => _respondWithId(
        await _registerWorker.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_REGISTER_WORKER_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── GET /team/<id> ────────────────────────────────────────────────────

  Future<Response> _handleGetMember(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    final result = await _getTeamMember.execute(
      GetTeamMemberIntent(memberId: id),
      obs,
    );

    return switch (result) {
      Success(:final value) => Response.ok(
        jsonEncode({'data': value.data.toJson(), 'meta': value.meta.toJson()}),
        headers: _jsonHeaders,
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  // ── PUT /team/<id>/deactivate ─────────────────────────────────────────

  Future<Response> _handleDeactivateWorker(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    return _wrapVoidResult(
      await _deactivateWorker.execute(
        DeactivateWorkerIntent(memberId: id),
        obs,
      ),
    );
  }

  // ── PUT /team/<id>/reactivate ─────────────────────────────────────────

  Future<Response> _handleReactivateWorker(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    return _wrapVoidResult(
      await _reactivateWorker.execute(
        ReactivateWorkerIntent(memberId: id),
        obs,
      ),
    );
  }

  // ── POST /team/<id>/reset-password ────────────────────────────────────

  Future<Response> _handleResetPassword(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    return _wrapVoidResult(
      await _resetPassword.execute(ResetPasswordIntent(memberId: id), obs),
    );
  }

  // ── POST /team/<id>/roles ─────────────────────────────────────────────

  Future<Response> _handleAssignRole(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = AssignRoleIntent.parseFromBody(id, body);
    return switch (parsed) {
      Success(:final value) => _respondWithId(
        await _assignRole.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_ASSIGN_ROLE_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /team/<id>/roles/<roleId>/deactivate ──────────────────────────

  Future<Response> _handleDeactivateRole(
    Request request,
    String id,
    String roleId,
  ) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    return _wrapVoidResult(
      await _deactivateRole.execute(
        DeactivateRoleIntent(memberId: id, roleId: roleId),
        obs,
      ),
    );
  }

  // ── PUT /team/<id>/roles/<roleId>/reactivate ──────────────────────────

  Future<Response> _handleReactivateRole(
    Request request,
    String id,
    String roleId,
  ) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    return _wrapVoidResult(
      await _reactivateRole.execute(
        ReactivateRoleIntent(memberId: id, roleId: roleId),
        obs,
      ),
    );
  }

  // ── Helpers (verbatim copy of LookupHandler / RegistryPatientHandler) ──

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
