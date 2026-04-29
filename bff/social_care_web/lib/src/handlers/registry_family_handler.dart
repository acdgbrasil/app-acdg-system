import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../intents/add_family_member_intent.dart';
import '../intents/assign_primary_caregiver_intent.dart';
import '../intents/get_audit_trail_intent.dart';
import '../intents/remove_family_member_intent.dart';
import '../intents/update_social_identity_intent.dart';
import '../observability/observability_context.dart';
import '../use_cases/add_family_member_use_case.dart';
import '../use_cases/assign_primary_caregiver_use_case.dart';
import '../use_cases/get_audit_trail_use_case.dart';
import '../use_cases/remove_family_member_use_case.dart';
import '../use_cases/update_social_identity_use_case.dart';

/// Thin Registry (Family + Social Identity + Audit) HTTP handler — A09
/// canonical pattern.
///
/// Responsibilities mirror [RegistryPatientHandler]:
/// - Parse request (body / route params / query) into the matching Intent
///   via P2 if-case.
/// - Dispatch to the corresponding UseCase (state matrix — P1 switch).
/// - Translate [Result] into sanitized shelf [Response]s.
///
/// Error handling:
/// - `BackendError.http` → the HTTP status code (upstream passthrough).
/// - Non-`BackendError` failures → 500 `INTERNAL` WITHOUT echoing the
///   inner Dart exception message or stack trace (pinned by Wave 0).
/// - Invalid JSON / missing required fields → 400 with a PII-safe message
///   from the Intent's parser.
final class RegistryFamilyHandler {
  const RegistryFamilyHandler({
    required AddFamilyMemberUseCase add,
    required RemoveFamilyMemberUseCase remove,
    required AssignPrimaryCaregiverUseCase assignCaregiver,
    required UpdateSocialIdentityUseCase updateIdentity,
    required GetAuditTrailUseCase getAudit,
  }) : _add = add,
       _remove = remove,
       _assignCaregiver = assignCaregiver,
       _updateIdentity = updateIdentity,
       _getAudit = getAudit;

  final AddFamilyMemberUseCase _add;
  final RemoveFamilyMemberUseCase _remove;
  final AssignPrimaryCaregiverUseCase _assignCaregiver;
  final UpdateSocialIdentityUseCase _updateIdentity;
  final GetAuditTrailUseCase _getAudit;

  Router get router {
    final r = Router();
    r.post('/patients/<id>/family-members', _handleAdd);
    r.delete('/patients/<id>/family-members/<memberId>', _handleRemove);
    r.put('/patients/<id>/primary-caregiver', _handleAssignCaregiver);
    r.put('/patients/<id>/social-identity', _handleUpdateSocialIdentity);
    r.get('/patients/<id>/audit-trail', _handleGetAuditTrail);
    return r;
  }

  // ── POST /patients/<id>/family-members ─────────────────────────────────

  Future<Response> _handleAdd(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = AddFamilyMemberIntent.parseFromBody(id, body);
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(await _add.execute(value, obs)),
      Failure(:final error) => _badRequest(
        code: 'INVALID_ADD_FAMILY_MEMBER_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── DELETE /patients/<id>/family-members/<memberId> ────────────────────

  Future<Response> _handleRemove(
    Request request,
    String id,
    String memberId,
  ) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final parsed = RemoveFamilyMemberIntent.parseFromParams(
      patientId: id,
      memberId: memberId,
    );
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _remove.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_REMOVE_FAMILY_MEMBER_PARAMS',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /patients/<id>/primary-caregiver ───────────────────────────────

  Future<Response> _handleAssignCaregiver(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = AssignPrimaryCaregiverIntent.parseFromBody(id, body);
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _assignCaregiver.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_PRIMARY_CAREGIVER_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /patients/<id>/social-identity ─────────────────────────────────

  Future<Response> _handleUpdateSocialIdentity(
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

    final parsed = UpdateSocialIdentityIntent.parseFromBody(id, body);
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _updateIdentity.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_SOCIAL_IDENTITY_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── GET /patients/<id>/audit-trail ─────────────────────────────────────

  Future<Response> _handleGetAuditTrail(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final intent = GetAuditTrailIntent.parseFromQuery(
      id,
      request.requestedUri.queryParameters,
    );

    final result = await _getAudit.execute(intent, obs);
    return switch (result) {
      Success(:final value) => Response.ok(
        jsonEncode({
          'data': value.data.map((e) => e.toJson()).toList(),
          'meta': value.meta.toJson(),
        }),
        headers: _jsonHeaders,
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  // ── Helpers ────────────────────────────────────────────────────────────

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
