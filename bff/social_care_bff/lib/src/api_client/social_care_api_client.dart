import 'package:dio/dio.dart';

import '../models/audit_event.dart';
import '../models/lookup_item.dart';
import '../models/patient.dart';
import 'api_models/common_mappers.dart';
import 'api_models/patient_mapper.dart';

/// Low-level HTTP client for the social-care API.
///
/// Translates Dio HTTP calls into domain models using the mappers
/// in `api_models/`. The rest of the BFF works with pure models.
class SocialCareApiClient {
  SocialCareApiClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ──────────────────────────── Registry ────────────────────────────

  Future<String> registerPatient({
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post<dynamic>(
      '/patients',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
    return _extractId(response.data);
  }

  Future<Patient> getPatientById(String patientId) async {
    final response = await _dio.get<dynamic>('/patients/$patientId');
    return PatientMapper.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<Patient> getPatientByPersonId(String personId) async {
    final response = await _dio.get<dynamic>('/patients/by-person/$personId');
    return PatientMapper.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> addFamilyMember({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.post<dynamic>(
      '/patients/$patientId/family-members',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  Future<void> removeFamilyMember({
    required String patientId,
    required String memberId,
    required String actorId,
  }) async {
    await _dio.delete<dynamic>(
      '/patients/$patientId/family-members/$memberId',
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  Future<void> assignPrimaryCaregiver({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put<dynamic>(
      '/patients/$patientId/primary-caregiver',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  Future<void> updateSocialIdentity({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put<dynamic>(
      '/patients/$patientId/social-identity',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  // ──────────────────────────── Audit ────────────────────────────

  Future<List<AuditEvent>> getAuditTrail(
    String patientId, {
    String? eventType,
  }) async {
    final response = await _dio.get<dynamic>(
      '/patients/$patientId/audit-trail',
      queryParameters: {
        if (eventType != null) 'eventType': eventType,
      },
    );
    final items = response.data['data'] as List<dynamic>;
    return items
        .cast<Map<String, dynamic>>()
        .map(CommonMappers.auditEventFromJson)
        .toList();
  }

  // ──────────────────────────── Assessment ────────────────────────────

  Future<void> updateHousingCondition({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put<dynamic>(
      '/patients/$patientId/housing-condition',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  Future<void> updateSocioEconomicSituation({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put<dynamic>(
      '/patients/$patientId/socioeconomic-situation',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  Future<void> updateWorkAndIncome({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put<dynamic>(
      '/patients/$patientId/work-and-income',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  Future<void> updateEducationalStatus({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put<dynamic>(
      '/patients/$patientId/educational-status',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  Future<void> updateHealthStatus({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put<dynamic>(
      '/patients/$patientId/health-status',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  Future<void> updateCommunitySupportNetwork({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put<dynamic>(
      '/patients/$patientId/community-support-network',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  Future<void> updateSocialHealthSummary({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put<dynamic>(
      '/patients/$patientId/social-health-summary',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  // ──────────────────────────── Care ────────────────────────────

  Future<String> registerAppointment({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post<dynamic>(
      '/patients/$patientId/appointments',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
    return _extractId(response.data);
  }

  Future<void> registerIntakeInfo({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put<dynamic>(
      '/patients/$patientId/intake-info',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  // ──────────────────────────── Protection ────────────────────────────

  Future<void> updatePlacementHistory({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put<dynamic>(
      '/patients/$patientId/placement-history',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
  }

  Future<String> reportRightsViolation({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post<dynamic>(
      '/patients/$patientId/violation-reports',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
    return _extractId(response.data);
  }

  Future<String> createReferral({
    required String patientId,
    required String actorId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post<dynamic>(
      '/patients/$patientId/referrals',
      data: body,
      options: Options(headers: {'X-Actor-Id': actorId}),
    );
    return _extractId(response.data);
  }

  // ──────────────────────────── Lookup ────────────────────────────

  Future<List<LookupItem>> listLookupItems(String tableName) async {
    final response = await _dio.get<dynamic>('/dominios/$tableName');
    final items = response.data['data'] as List<dynamic>;
    return items
        .cast<Map<String, dynamic>>()
        .map(CommonMappers.lookupItemFromJson)
        .toList();
  }

  // ──────────────────────────── Helpers ────────────────────────────

  String _extractId(dynamic data) {
    final map = data as Map<String, dynamic>;
    final inner = map['data'] as Map<String, dynamic>;
    return inner['id'] as String;
  }
}
