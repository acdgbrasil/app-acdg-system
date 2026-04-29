import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../intents/approve_lookup_request_intent.dart';
import '../intents/create_lookup_item_intent.dart';
import '../intents/create_lookup_request_intent.dart';
import '../intents/get_lookup_requests_intent.dart';
import '../intents/get_lookup_table_intent.dart';
import '../intents/get_lookups_batch_intent.dart';
import '../intents/reject_lookup_request_intent.dart';
import '../intents/toggle_lookup_item_intent.dart';
import '../intents/update_lookup_item_intent.dart';
import '../observability/observability_context.dart';
import '../use_cases/approve_lookup_request_use_case.dart';
import '../use_cases/create_lookup_item_use_case.dart';
import '../use_cases/create_lookup_request_use_case.dart';
import '../use_cases/get_lookup_requests_use_case.dart';
import '../use_cases/get_lookup_table_use_case.dart';
import '../use_cases/get_lookups_batch_use_case.dart';
import '../use_cases/reject_lookup_request_use_case.dart';
import '../use_cases/toggle_lookup_item_use_case.dart';
import '../use_cases/update_lookup_item_use_case.dart';

/// Thin Lookup HTTP handler — A13/A14 canonical pattern.
///
/// This handler exercises the widest range of parse strategies in the
/// Onda 3 canon:
/// - **Path-only** (GET `/lookups/<tableName>`, PUT
///   `/lookup-requests/<id>/approve`, PUT `/lookup-requests/<id>/reject`)
///   — no `parseFromBody`; the intent is built straight from the route.
/// - **Query-only** (GET `/lookups?tables=a,b,c`) — A14 introduced this
///   variant. The intent is built by `parseFromQuery` from the URL's
///   query string; no body. Failure on missing/blank/oversized input
///   surfaces as 400 `INVALID_LOOKUPS_BATCH_QUERY`.
/// - **Empty intent** (GET `/lookup-requests`) — no body, no params.
/// - **P2 if-case** with 1 required (PATCH
///   `/lookups/<tableName>/<id>/toggle` — const parse error).
/// - **P2 if-case** with 2 required (POST `/lookups/<tableName>`) and
///   with 3 required (POST `/lookup-requests`) — dynamic parse error
///   enumerating missing fields.
/// - **P2-tolerant** (PUT `/lookups/<tableName>/<id>`) — first use of
///   this variant. `parseFromBody` is a total function; there is NO
///   `INVALID_UPDATE_LOOKUP_ITEM_BODY` code. Only JSON-level malformed
///   input surfaces as 400 `INVALID_JSON`.
///
/// Error code convention (BFF Web canon):
/// - **Local 400 codes** are `INVALID_*` — emitted when the request never
///   reaches the upstream backend (parse failures, JSON malformed,
///   query-string validation). These are namespaced separately from
///   backend codes by design; see `STATE.md` of phase-3-bff-contract-a.
/// - **Upstream codes** (e.g. `LKP-001`, `LKR-009`) are passed through
///   transparently from `BackendError` via [_extractError]. The two
///   namespaces never collide because parse failures short-circuit
///   before the contract is dispatched.
///
/// Responsibilities (identical to the rest of the canonical handlers):
/// - Parse request (JSON body + route params) into the matching Intent.
/// - Dispatch to the corresponding UseCase (state matrix — P1 switch on
///   result).
/// - Translate [Result] into sanitized shelf [Response]s.
///
/// Error handling:
/// - `BackendError.http` → the HTTP status code (upstream passthrough).
/// - Non-`BackendError` failures → 500 `INTERNAL` WITHOUT echoing the
///   inner Dart exception message or stack trace.
/// - Invalid JSON → 400 `INVALID_JSON` for every POST/PUT/PATCH route.
/// - Missing required fields → 400 with a PII-safe message from the
///   Intent's parser (one dedicated code per body-validating route).
final class LookupHandler {
  const LookupHandler({
    required GetLookupTableUseCase getLookupTable,
    required GetLookupsBatchUseCase getLookupsBatch,
    required CreateLookupItemUseCase createLookupItem,
    required UpdateLookupItemUseCase updateLookupItem,
    required ToggleLookupItemUseCase toggleLookupItem,
    required GetLookupRequestsUseCase getLookupRequests,
    required CreateLookupRequestUseCase createLookupRequest,
    required ApproveLookupRequestUseCase approveLookupRequest,
    required RejectLookupRequestUseCase rejectLookupRequest,
  }) : _getLookupTable = getLookupTable,
       _getLookupsBatch = getLookupsBatch,
       _createLookupItem = createLookupItem,
       _updateLookupItem = updateLookupItem,
       _toggleLookupItem = toggleLookupItem,
       _getLookupRequests = getLookupRequests,
       _createLookupRequest = createLookupRequest,
       _approveLookupRequest = approveLookupRequest,
       _rejectLookupRequest = rejectLookupRequest;

  final GetLookupTableUseCase _getLookupTable;
  final GetLookupsBatchUseCase _getLookupsBatch;
  final CreateLookupItemUseCase _createLookupItem;
  final UpdateLookupItemUseCase _updateLookupItem;
  final ToggleLookupItemUseCase _toggleLookupItem;
  final GetLookupRequestsUseCase _getLookupRequests;
  final CreateLookupRequestUseCase _createLookupRequest;
  final ApproveLookupRequestUseCase _approveLookupRequest;
  final RejectLookupRequestUseCase _rejectLookupRequest;

  Router get router {
    final r = Router();
    // Order matters: register the more specific batch route first so it
    // wins ambiguity in shelf_router.
    r.get('/lookups', _handleGetBatch);
    r.get('/lookups/<tableName>', _handleGetTable);
    r.post('/lookups/<tableName>', _handleCreateItem);
    r.put('/lookups/<tableName>/<id>', _handleUpdateItem);
    r.patch('/lookups/<tableName>/<id>/toggle', _handleToggleItem);
    r.get('/lookup-requests', _handleGetRequests);
    r.post('/lookup-requests', _handleCreateRequest);
    r.put('/lookup-requests/<id>/approve', _handleApproveRequest);
    r.put('/lookup-requests/<id>/reject', _handleRejectRequest);
    return r;
  }

  // ── GET /lookups?tables=a,b,c (batch) ─────────────────────────────────

  Future<Response> _handleGetBatch(Request request) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final parsed = GetLookupsBatchIntent.parseFromQuery(
      request.url.queryParameters,
    );
    return switch (parsed) {
      Success(:final value) => await _runBatch(value, obs),
      Failure(:final error) => _badRequest(
        code: 'INVALID_LOOKUPS_BATCH_QUERY',
        message: error.toString(),
      ),
    };
  }

  Future<Response> _runBatch(
    GetLookupsBatchIntent intent,
    ObservabilityContext obs,
  ) async {
    final result = await _getLookupsBatch.execute(intent, obs);
    return switch (result) {
      Success(:final value) => Response.ok(
        jsonEncode({'data': value.data.toJson(), 'meta': value.meta.toJson()}),
        headers: _jsonHeaders,
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  // ── GET /lookups/<tableName> ──────────────────────────────────────────

  Future<Response> _handleGetTable(Request request, String tableName) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    final result = await _getLookupTable.execute(
      GetLookupTableIntent(tableName: tableName),
      obs,
    );

    return switch (result) {
      Success(:final value) => Response.ok(
        jsonEncode({
          'data': value.data.map((i) => i.toJson()).toList(),
          'meta': value.meta.toJson(),
        }),
        headers: _jsonHeaders,
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  // ── POST /lookups/<tableName> ─────────────────────────────────────────

  Future<Response> _handleCreateItem(Request request, String tableName) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = CreateLookupItemIntent.parseFromBody(tableName, body);
    return switch (parsed) {
      Success(:final value) => _respondWithId(
        await _createLookupItem.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_CREATE_LOOKUP_ITEM_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /lookups/<tableName>/<id> ─────────────────────────────────────

  Future<Response> _handleUpdateItem(
    Request request,
    String tableName,
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

    // V2 (§P5): body parser is total once UUID gate passes; UUID failure
    // becomes the dedicated 400 INVALID_UPDATE_LOOKUP_ITEM_BODY response.
    final parsed = UpdateLookupItemIntent.parseFromBody(tableName, id, body);
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _updateLookupItem.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_UPDATE_LOOKUP_ITEM_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PATCH /lookups/<tableName>/<id>/toggle ────────────────────────────

  Future<Response> _handleToggleItem(
    Request request,
    String tableName,
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

    final parsed = ToggleLookupItemIntent.parseFromBody(tableName, id, body);
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _toggleLookupItem.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_TOGGLE_LOOKUP_ITEM_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── GET /lookup-requests ──────────────────────────────────────────────

  Future<Response> _handleGetRequests(Request request) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    final result = await _getLookupRequests.execute(
      const GetLookupRequestsIntent(),
      obs,
    );

    return switch (result) {
      Success(:final value) => Response.ok(
        jsonEncode({
          'data': value.data.map((r) => r.toJson()).toList(),
          'meta': value.meta.toJson(),
        }),
        headers: _jsonHeaders,
      ),
      Failure(:final error) => _errorResponse(error),
    };
  }

  // ── POST /lookup-requests ─────────────────────────────────────────────

  Future<Response> _handleCreateRequest(Request request) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = CreateLookupRequestIntent.parseFromBody(body);
    return switch (parsed) {
      Success(:final value) => _respondWithId(
        await _createLookupRequest.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_CREATE_LOOKUP_REQUEST_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /lookup-requests/<id>/approve ─────────────────────────────────

  Future<Response> _handleApproveRequest(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    final parsed = ApproveLookupRequestIntent.parseFromPath(id);
    return switch (parsed) {
      Success(:final value) =>
        _wrapVoidResult(await _approveLookupRequest.execute(value, obs)),
      Failure(:final error) => _badRequest(
        code: 'INVALID_APPROVE_LOOKUP_REQUEST_PARAMS',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /lookup-requests/<id>/reject ──────────────────────────────────

  Future<Response> _handleRejectRequest(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);
    final parsed = RejectLookupRequestIntent.parseFromPath(id);
    return switch (parsed) {
      Success(:final value) =>
        _wrapVoidResult(await _rejectLookupRequest.execute(value, obs)),
      Failure(:final error) => _badRequest(
        code: 'INVALID_REJECT_LOOKUP_REQUEST_PARAMS',
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
