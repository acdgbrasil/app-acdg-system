import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../intents/update_community_support_network_intent.dart';
import '../intents/update_educational_status_intent.dart';
import '../intents/update_health_status_intent.dart';
import '../intents/update_housing_condition_intent.dart';
import '../intents/update_social_health_summary_intent.dart';
import '../intents/update_socio_economic_situation_intent.dart';
import '../intents/update_work_and_income_intent.dart';
import '../observability/observability_context.dart';
import '../use_cases/update_community_support_network_use_case.dart';
import '../use_cases/update_educational_status_use_case.dart';
import '../use_cases/update_health_status_use_case.dart';
import '../use_cases/update_housing_condition_use_case.dart';
import '../use_cases/update_social_health_summary_use_case.dart';
import '../use_cases/update_socio_economic_situation_use_case.dart';
import '../use_cases/update_work_and_income_use_case.dart';

/// Thin Assessment HTTP handler — A10 canonical pattern.
///
/// Responsibilities mirror [RegistryPatientHandler] / [RegistryFamilyHandler]:
/// - Parse request (JSON body + route params) into the matching Intent via
///   try/catch over `fromJson` (A10 refinement — see Wave 0 REPORT).
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
///   from the Intent's parser (one dedicated code per ficha).
final class AssessmentHandler {
  const AssessmentHandler({
    required UpdateHousingConditionUseCase housing,
    required UpdateSocioEconomicSituationUseCase socioEconomic,
    required UpdateWorkAndIncomeUseCase workAndIncome,
    required UpdateEducationalStatusUseCase educationalStatus,
    required UpdateHealthStatusUseCase healthStatus,
    required UpdateCommunitySupportNetworkUseCase communitySupport,
    required UpdateSocialHealthSummaryUseCase socialHealthSummary,
  }) : _housing = housing,
       _socioEconomic = socioEconomic,
       _workAndIncome = workAndIncome,
       _educationalStatus = educationalStatus,
       _healthStatus = healthStatus,
       _communitySupport = communitySupport,
       _socialHealthSummary = socialHealthSummary;

  final UpdateHousingConditionUseCase _housing;
  final UpdateSocioEconomicSituationUseCase _socioEconomic;
  final UpdateWorkAndIncomeUseCase _workAndIncome;
  final UpdateEducationalStatusUseCase _educationalStatus;
  final UpdateHealthStatusUseCase _healthStatus;
  final UpdateCommunitySupportNetworkUseCase _communitySupport;
  final UpdateSocialHealthSummaryUseCase _socialHealthSummary;

  Router get router {
    final r = Router();
    r.put('/patients/<id>/assessment/housing', _handleHousing);
    r.put('/patients/<id>/assessment/socioeconomic', _handleSocioEconomic);
    r.put('/patients/<id>/assessment/work-income', _handleWorkAndIncome);
    r.put('/patients/<id>/assessment/education', _handleEducational);
    r.put('/patients/<id>/assessment/health', _handleHealth);
    r.put(
      '/patients/<id>/assessment/community-support',
      _handleCommunitySupport,
    );
    r.put(
      '/patients/<id>/assessment/social-health-summary',
      _handleSocialHealthSummary,
    );
    return r;
  }

  // ── PUT /patients/<id>/assessment/housing ─────────────────────────────

  Future<Response> _handleHousing(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = UpdateHousingConditionIntent.parseFromBody(
      id,
      body,
      obs: obs,
    );
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _housing.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_HOUSING_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /patients/<id>/assessment/socioeconomic ───────────────────────

  Future<Response> _handleSocioEconomic(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = UpdateSocioEconomicSituationIntent.parseFromBody(
      id,
      body,
      obs: obs,
    );
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _socioEconomic.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_SOCIO_ECONOMIC_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /patients/<id>/assessment/work-income ─────────────────────────

  Future<Response> _handleWorkAndIncome(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = UpdateWorkAndIncomeIntent.parseFromBody(id, body, obs: obs);
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _workAndIncome.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_WORK_AND_INCOME_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /patients/<id>/assessment/education ───────────────────────────

  Future<Response> _handleEducational(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = UpdateEducationalStatusIntent.parseFromBody(
      id,
      body,
      obs: obs,
    );
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _educationalStatus.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_EDUCATIONAL_STATUS_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /patients/<id>/assessment/health ──────────────────────────────

  Future<Response> _handleHealth(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = UpdateHealthStatusIntent.parseFromBody(id, body, obs: obs);
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _healthStatus.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_HEALTH_STATUS_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /patients/<id>/assessment/community-support ───────────────────

  Future<Response> _handleCommunitySupport(Request request, String id) async {
    final obs = ObservabilityContext.fromRequestOrNoop(request);

    final body = await _readJsonBody(request);
    if (body == null) {
      return _badRequest(
        code: 'INVALID_JSON',
        message: 'Request body is not valid JSON',
      );
    }

    final parsed = UpdateCommunitySupportNetworkIntent.parseFromBody(
      id,
      body,
      obs: obs,
    );
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _communitySupport.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_COMMUNITY_SUPPORT_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── PUT /patients/<id>/assessment/social-health-summary ───────────────

  Future<Response> _handleSocialHealthSummary(
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

    final parsed = UpdateSocialHealthSummaryIntent.parseFromBody(
      id,
      body,
      obs: obs,
    );
    return switch (parsed) {
      Success(:final value) => _wrapVoidResult(
        await _socialHealthSummary.execute(value, obs),
      ),
      Failure(:final error) => _badRequest(
        code: 'INVALID_SOCIAL_HEALTH_SUMMARY_BODY',
        message: error.toString(),
      ),
    };
  }

  // ── Helpers (verbatim copy of RegistryPatientHandler canon) ───────────

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
