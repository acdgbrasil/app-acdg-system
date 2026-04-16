import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

/// Implementation of [SocialCareContract] that communicates with the real
/// backend API (Swift/Vapor) via HTTP.
///
/// This is the pure-Dart BFF API client for the Web BFF server.
/// It proxies authenticated requests to the backend, preserving
/// structured error responses.
///
/// People and Analytics methods are NOT implemented here — they
/// require separate service clients (PeopleContextClient, AnalyticsBiClient).
class SocialCareApiClient implements SocialCareContract {
  SocialCareApiClient({
    required String baseUrl,
    required String actorId,
    required String accessToken,
    Dio? dio,
  }) : _dio = dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               headers: {
                 'X-Actor-Id': actorId,
                 'Content-Type': 'application/json',
                 'Authorization': 'Bearer $accessToken',
               },
             ),
           );

  final Dio _dio;

  // ── Error Handling ──────────────────────────────────────────────────

  /// Extracts a structured [BackendErrorResponse] from a non-success response.
  ///
  /// Preserves the full error structure (id, code, message, bc, module,
  /// severity, etc.) without concatenating fields.
  Failure<T> _backendFailure<T>(Response<dynamic> response, String fallbackMessage) {
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      try {
        final errorResponse = BackendErrorResponse.fromJson(data);
        return Failure(errorResponse);
      } catch (_) {
        // Fallback if error structure does not match expected schema
      }
    }
    final message = (data is Map<String, dynamic>)
        ? (data['message'] as String? ?? fallbackMessage)
        : fallbackMessage;
    return Failure(
      BackendErrorResponse(
        error: BackendError(
          id: '',
          code: 'UNKNOWN',
          message: message,
          http: response.statusCode ?? 502,
        ),
      ),
    );
  }

  // ── Response Helpers ────────────────────────────────────────────────

  StandardResponse<T> _wrapResponse<T>(T data) => StandardResponse(
    data: data,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  StandardIdResponse _extractIdResponse(Map<String, dynamic> responseData) {
    final data = responseData['data'] as Map<String, dynamic>;
    return StandardResponse(
      data: IdData(id: data['id'] as String),
      meta: ResponseMeta(
        timestamp:
            (responseData['meta'] as Map<String, dynamic>?)?['timestamp']
                    as String? ??
                DateTime.now().toIso8601String(),
      ),
    );
  }

  // ── Health ──────────────────────────────────────────────────────────

  @override
  Future<Result<void>> checkHealth() async {
    try {
      await _dio.get('/health');
      return const Success(null);
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> checkReady() async {
    try {
      await _dio.get('/ready');
      return const Success(null);
    } catch (e) {
      return Failure(e);
    }
  }

  // ── Registry — Patients ─────────────────────────────────────────────

  @override
  Future<Result<PaginatedList<PatientSummaryResponse>>> fetchPatients({
    String? search,
    String? status,
    String? cursor,
    int? limit,
  }) async {
    try {
      final params = <String, dynamic>{
        if (search != null) 'search': search,
        if (status != null) 'status': status,
        if (cursor != null) 'cursor': cursor,
        'limit': limit ?? 20,
      };
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/patients',
        queryParameters: params,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data!['data'] as List<dynamic>;
        final meta = response.data!['meta'] as Map<String, dynamic>;
        return Success(
          PaginatedList(
            data: data
                .cast<Map<String, dynamic>>()
                .map(PatientSummaryResponse.fromJson)
                .toList(),
            meta: PaginationMeta.fromJson(meta),
          ),
        );
      }
      return _backendFailure(response, 'Failed to list patients');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<StandardIdResponse>> registerPatient(
    RegisterPatientRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/patients',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(_extractIdResponse(response.data!));
      }
      return _backendFailure(response, 'Failed to register patient');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatient(
    String patientId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/patients/$patientId',
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 200) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return Success(_wrapResponse(PatientResponse.fromJson(data)));
      }
      return _backendFailure(response, 'Patient not found');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatientByPersonId(
    String personId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/patients/by-person/$personId',
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 200) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return Success(_wrapResponse(PatientResponse.fromJson(data)));
      }
      return _backendFailure(response, 'Patient not found');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatientEnriched(
    String patientId,
  ) async {
    return fetchPatient(patientId);
  }

  // ── Registry — Family Members ───────────────────────────────────────

  @override
  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest request, {
    String? cpf,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/patients/$patientId/family-members',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 ||
          response.statusCode == 201 ||
          response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to add family member');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> removeFamilyMember(
    String patientId,
    String memberId,
  ) async {
    try {
      final response = await _dio.delete(
        '/api/v1/patients/$patientId/family-members/$memberId',
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to remove family member');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    String patientId,
    AssignPrimaryCaregiverRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/$patientId/primary-caregiver',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to assign primary caregiver');
    } catch (e) {
      return Failure(e);
    }
  }

  // ── Registry — Social Identity ──────────────────────────────────────

  @override
  Future<Result<void>> updateSocialIdentity(
    String patientId,
    UpdateSocialIdentityRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/$patientId/social-identity',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to update social identity');
    } catch (e) {
      return Failure(e);
    }
  }

  // ── Registry — Lifecycle ────────────────────────────────────────────

  @override
  Future<Result<void>> dischargePatient(
    String patientId,
    DischargePatientRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/patients/$patientId/discharge',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to discharge patient');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> readmitPatient(
    String patientId,
    ReadmitPatientRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/patients/$patientId/readmit',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to readmit patient');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> admitPatient(String patientId) async {
    try {
      final response = await _dio.post(
        '/api/v1/patients/$patientId/admit',
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to admit patient');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> withdrawPatient(
    String patientId,
    WithdrawPatientRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/patients/$patientId/withdraw',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to withdraw patient');
    } catch (e) {
      return Failure(e);
    }
  }

  // ── Assessment ──────────────────────────────────────────────────────

  @override
  Future<Result<void>> updateHousingCondition(
    String patientId,
    UpdateHousingConditionRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/$patientId/housing-condition',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to update housing condition');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    String patientId,
    UpdateSocioEconomicSituationRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/$patientId/socioeconomic-situation',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(
        response,
        'Failed to update socio-economic situation',
      );
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateWorkAndIncome(
    String patientId,
    UpdateWorkAndIncomeRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/$patientId/work-and-income',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to update work and income');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateEducationalStatus(
    String patientId,
    UpdateEducationalStatusRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/$patientId/educational-status',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to update educational status');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateHealthStatus(
    String patientId,
    UpdateHealthStatusRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/$patientId/health-status',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to update health status');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    String patientId,
    UpdateCommunitySupportNetworkRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/$patientId/community-support-network',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(
        response,
        'Failed to update community support network',
      );
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateSocialHealthSummary(
    String patientId,
    UpdateSocialHealthSummaryRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/$patientId/social-health-summary',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(
        response,
        'Failed to update social health summary',
      );
    } catch (e) {
      return Failure(e);
    }
  }

  // ── Care ────────────────────────────────────────────────────────────

  @override
  Future<Result<StandardIdResponse>> registerAppointment(
    String patientId,
    RegisterAppointmentRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/patients/$patientId/appointments',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(_extractIdResponse(response.data!));
      }
      return _backendFailure(response, 'Failed to register appointment');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateIntakeInfo(
    String patientId,
    RegisterIntakeInfoRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/$patientId/intake-info',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to update intake info');
    } catch (e) {
      return Failure(e);
    }
  }

  // ── Protection ──────────────────────────────────────────────────────

  @override
  Future<Result<void>> updatePlacementHistory(
    String patientId,
    UpdatePlacementHistoryRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/$patientId/placement-history',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return _backendFailure(response, 'Failed to update placement history');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<StandardIdResponse>> reportViolation(
    String patientId,
    ReportRightsViolationRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/patients/$patientId/violation-reports',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(_extractIdResponse(response.data!));
      }
      return _backendFailure(response, 'Failed to report violation');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<StandardIdResponse>> createReferral(
    String patientId,
    CreateReferralRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/patients/$patientId/referrals',
        data: request.toJson(),
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(_extractIdResponse(response.data!));
      }
      return _backendFailure(response, 'Failed to create referral');
    } catch (e) {
      return Failure(e);
    }
  }

  // ── Audit ───────────────────────────────────────────────────────────

  @override
  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> getAuditTrail(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) async {
    try {
      final params = <String, dynamic>{
        if (eventType != null) 'eventType': eventType,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/patients/$patientId/audit-trail',
        queryParameters: params.isEmpty ? null : params,
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 200) {
        final data = response.data!['data'] as List<dynamic>;
        return Success(
          _wrapResponse(
            data
                .cast<Map<String, dynamic>>()
                .map(AuditTrailEntryResponse.fromJson)
                .toList(),
          ),
        );
      }
      return _backendFailure(response, 'Failed to fetch audit trail');
    } catch (e) {
      return Failure(e);
    }
  }

  // ── Lookup ──────────────────────────────────────────────────────────

  @override
  Future<Result<StandardResponse<List<Map<String, dynamic>>>>> getLookupTable(
    String tableName,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/dominios/$tableName',
        options: Options(validateStatus: (status) => true),
      );
      if (response.statusCode == 200) {
        final data = response.data!['data'] as List<dynamic>;
        return Success(_wrapResponse(data.cast<Map<String, dynamic>>()));
      }
      return _backendFailure(response, 'Lookup table $tableName not found');
    } catch (e) {
      return Failure(e);
    }
  }

  // ── People (delegated to PeopleContextClient) ──────────────────────

  @override
  Future<Result<StandardIdResponse>> registerPerson(
    RegisterPersonRequest request,
  ) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  @override
  Future<Result<StandardIdResponse>> registerPersonWithLogin(
    RegisterPersonWithLoginRequest request,
  ) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  @override
  Future<Result<PersonResponse>> getPerson(String personId) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  @override
  Future<Result<PersonResponse>> findPersonByCpf(String cpf) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  @override
  Future<Result<StandardResponse<List<PersonResponse>>>> fetchPeople({
    int? limit,
    String? name,
    String? cpf,
    String? cursor,
  }) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  @override
  Future<Result<void>> deactivatePerson(String personId) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  @override
  Future<Result<void>> reactivatePerson(String personId) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  @override
  Future<Result<void>> requestPasswordReset(String personId) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  @override
  Future<Result<void>> assignRole(
    String personId,
    AssignRoleRequest request,
  ) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  @override
  Future<Result<List<PersonRoleResponse>>> listPersonRoles(
    String personId, {
    bool? active,
  }) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  @override
  Future<Result<List<PersonRoleResponse>>> queryRoles({
    required String system,
    String? role,
    bool active = true,
  }) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  @override
  Future<Result<void>> deactivateRole({
    required String personId,
    required String roleId,
  }) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  @override
  Future<Result<void>> reactivateRole({
    required String personId,
    required String roleId,
  }) =>
      throw UnimplementedError('Use PeopleContextClient directly');

  // ── Analytics (delegated to AnalyticsBiClient) ─────────────────────

  @override
  Future<Result<StandardResponse<IndicatorResponse>>> getIndicators(
    String axis, {
    String? period,
  }) =>
      throw UnimplementedError('Use AnalyticsBiClient directly');

  @override
  Future<Result<StandardResponse<List<AxisMetadataResponse>>>>
      getAxesMetadata() =>
          throw UnimplementedError('Use AnalyticsBiClient directly');
}
