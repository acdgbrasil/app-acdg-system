import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

import '../../domain/errors/social_care_errors.dart';

/// HTTP client implementation of [SocialCareContract] that communicates with
/// the BFF Web server's REST endpoints.
///
/// Used on the web platform where the Flutter app calls the same-origin BFF
/// server. Authentication is handled via HttpOnly cookies that are sent
/// automatically on same-origin requests -- no Authorization header needed.
///
/// Unlike the Desktop [SocialCareBffRemote], this client:
/// - Does NOT send an `Authorization` header (cookies go automatically).
/// - Does NOT send an `X-Actor-Id` header (the BFF extracts it from the session).
/// - Uses BFF Web routes (e.g. `/patients`, `/lookups`) instead of backend API routes.
class HttpSocialCareClient implements SocialCareContract {
  HttpSocialCareClient({String? baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? '/api',
              contentType: 'application/json',
              extra: {'withCredentials': true},
            ),
          );

  final Dio _dio;

  // ===========================================================================
  // Health
  // ===========================================================================

  @override
  Future<Result<void>> checkHealth() async {
    try {
      await _dio.get<dynamic>('/health/live');
      return const Success(null);
    } catch (e) {
      return _failureFromException(e);
    }
  }

  @override
  Future<Result<void>> checkReady() async {
    try {
      await _dio.get<dynamic>('/health/ready');
      return const Success(null);
    } catch (e) {
      return _failureFromException(e);
    }
  }

  // ===========================================================================
  // Registry
  // ===========================================================================

  @override
  Future<Result<List<PatientOverview>>> fetchPatients() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/patients',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data!;
        final patients = data
            .cast<Map<String, dynamic>>()
            .map(PatientOverview.fromJson)
            .toList();
        return Success(patients);
      }
      return _failureFromResponse(response, 'Failed to fetch patients');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  @override
  Future<Result<PatientId>> registerPatient(Patient patient) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/patients',
        data: PatientTranslator.toJson(patient),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final id = response.data!['id'] as String;
        return PatientId.create(id);
      }
      return _failureFromResponse(response, 'Failed to register patient');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  @override
  Future<Result<PatientRemote>> fetchPatient(PatientId id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/patients/${id.value}',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        return Success(PatientRemote.fromJson(response.data!));
      }
      return _failureFromResponse(response, 'Patient not found');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  @override
  Future<Result<PatientRemote>> fetchPatientByPersonId(
    PersonId personId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/patients/by-person/${personId.value}',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        return Success(PatientRemote.fromJson(response.data!));
      }
      return _failureFromResponse(response, 'Patient not found');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  @override
  Future<Result<void>> addFamilyMember(
    PatientId patientId,
    FamilyMember member,
    LookupId prRelationshipId,
  ) async {
    try {
      final payload = {
        ...PatientTranslator.familyMemberToJson(member),
        'prRelationshipId': prRelationshipId.value,
      };

      final response = await _dio.post<dynamic>(
        '/patients/${patientId.value}/family-members',
        data: payload,
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return _failureFromResponse(response, 'Failed to add family member');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  @override
  Future<Result<void>> removeFamilyMember(
    PatientId patientId,
    PersonId memberId,
  ) async {
    try {
      final response = await _dio.delete<dynamic>(
        '/patients/${patientId.value}/family-members/${memberId.value}',
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return _failureFromResponse(response, 'Failed to remove family member');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    PatientId patientId,
    PersonId memberId,
  ) async {
    try {
      final response = await _dio.put<dynamic>(
        '/patients/${patientId.value}/primary-caregiver',
        data: {'memberPersonId': memberId.value},
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return _failureFromResponse(
        response,
        'Failed to assign primary caregiver',
      );
    } catch (e) {
      return _failureFromException(e);
    }
  }

  @override
  Future<Result<void>> updateSocialIdentity(
    PatientId patientId,
    SocialIdentity identity,
  ) async {
    try {
      final response = await _dio.put<dynamic>(
        '/patients/${patientId.value}/social-identity',
        data: PatientTranslator.socialIdentityToJson(identity),
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return _failureFromResponse(response, 'Failed to update social identity');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(
    PatientId patientId, {
    String? eventType,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/patients/${patientId.value}/audit-trail',
        queryParameters: eventType != null ? {'eventType': eventType} : null,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data!;
        return Success(
          data.cast<Map<String, dynamic>>().map(_mapAuditEvent).toList(),
        );
      }
      return _failureFromResponse(response, 'Failed to fetch audit trail');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  // ===========================================================================
  // Assessment
  // ===========================================================================

  @override
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  ) async {
    return _putVoid(
      '/patients/${patientId.value}/assessment/housing',
      PatientTranslator.housingConditionToJson(condition),
    );
  }

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    PatientId patientId,
    SocioEconomicSituation situation,
  ) async {
    return _putVoid(
      '/patients/${patientId.value}/assessment/socioeconomic',
      PatientTranslator.socioEconomicToJson(situation),
    );
  }

  @override
  Future<Result<void>> updateWorkAndIncome(
    PatientId patientId,
    WorkAndIncome data,
  ) async {
    return _putVoid(
      '/patients/${patientId.value}/assessment/work-income',
      PatientTranslator.workAndIncomeToJson(data),
    );
  }

  @override
  Future<Result<void>> updateEducationalStatus(
    PatientId patientId,
    EducationalStatus status,
  ) async {
    return _putVoid(
      '/patients/${patientId.value}/assessment/education',
      PatientTranslator.educationalStatusToJson(status),
    );
  }

  @override
  Future<Result<void>> updateHealthStatus(
    PatientId patientId,
    HealthStatus status,
  ) async {
    return _putVoid(
      '/patients/${patientId.value}/assessment/health',
      PatientTranslator.healthStatusToJson(status),
    );
  }

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    PatientId patientId,
    CommunitySupportNetwork network,
  ) async {
    return _putVoid(
      '/patients/${patientId.value}/assessment/community-support',
      PatientTranslator.communitySupportToJson(network),
    );
  }

  @override
  Future<Result<void>> updateSocialHealthSummary(
    PatientId patientId,
    SocialHealthSummary summary,
  ) async {
    return _putVoid(
      '/patients/${patientId.value}/assessment/social-health-summary',
      PatientTranslator.socialHealthSummaryToJson(summary),
    );
  }

  // ===========================================================================
  // Care
  // ===========================================================================

  @override
  Future<Result<AppointmentId>> registerAppointment(
    PatientId patientId,
    SocialCareAppointment appointment,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/patients/${patientId.value}/appointments',
        data: PatientTranslator.appointmentToJson(appointment),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final id = response.data!['id'] as String;
        return AppointmentId.create(id);
      }
      return _failureFromResponse(response, 'Failed to register appointment');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  @override
  Future<Result<void>> updateIntakeInfo(
    PatientId patientId,
    IngressInfo info,
  ) async {
    return _putVoid(
      '/patients/${patientId.value}/intake',
      PatientTranslator.intakeInfoToJson(info),
    );
  }

  // ===========================================================================
  // Protection
  // ===========================================================================

  @override
  Future<Result<void>> updatePlacementHistory(
    PatientId patientId,
    PlacementHistory history,
  ) async {
    return _putVoid(
      '/patients/${patientId.value}/placement-history',
      PatientTranslator.placementHistoryToJson(history),
    );
  }

  @override
  Future<Result<ViolationReportId>> reportViolation(
    PatientId patientId,
    RightsViolationReport report,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/patients/${patientId.value}/violations',
        data: PatientTranslator.violationReportToJson(report),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final id = response.data!['id'] as String;
        return ViolationReportId.create(id);
      }
      return _failureFromResponse(response, 'Failed to report violation');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  @override
  Future<Result<ReferralId>> createReferral(
    PatientId patientId,
    Referral referral,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/patients/${patientId.value}/referrals',
        data: PatientTranslator.referralToJson(referral),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final id = response.data!['id'] as String;
        return ReferralId.create(id);
      }
      return _failureFromResponse(response, 'Failed to create referral');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  // ===========================================================================
  // Lookup
  // ===========================================================================

  @override
  Future<Result<List<LookupItem>>> getLookupTable(String tableName) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/lookups/$tableName',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data!;
        return Success(
          data
              .cast<Map<String, dynamic>>()
              .map(
                (item) => LookupItem(
                  id: item['id'] as String,
                  codigo: item['codigo'] as String,
                  descricao: item['descricao'] as String,
                ),
              )
              .toList(),
        );
      }
      return _failureFromResponse(
        response,
        'Lookup table $tableName not found',
      );
    } catch (e) {
      return _failureFromException(e);
    }
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  /// Executes a PUT request expecting a void response (200 or 204).
  Future<Result<void>> _putVoid(String path, Object? data) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        options: Options(validateStatus: (status) => true),
      );

      if (_isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return _failureFromResponse(response, 'Request failed');
    } catch (e) {
      return _failureFromException(e);
    }
  }

  /// Checks if a status code represents a successful response.
  bool _isSuccessStatus(int? statusCode) =>
      statusCode == 200 || statusCode == 201 || statusCode == 204;

  /// Parses a BFF error response into a typed [SocialCareError] [Failure].
  ///
  /// The BFF forwards backend errors as `{"error": "CODE: message"}`.
  /// This parser extracts the backend code and user-facing message,
  /// then maps to domain errors when the code is known, or wraps in
  /// [ServerError] otherwise.
  Failure<T> _failureFromResponse<T>(
    Response<dynamic> response,
    String fallback,
  ) {
    final statusCode = response.statusCode ?? 500;
    final data = response.data;
    String message = fallback;
    String code = 'SRV-$statusCode';

    if (data is Map<String, dynamic>) {
      final errorStr = data['error'] as String?;
      final messageStr = data['message'] as String?;

      // Parse backend code from "CODE: message" pattern
      if (errorStr != null) {
        final match = RegExp(r'^([A-Z]+-\d+):\s*(.*)$').firstMatch(errorStr);
        if (match != null) {
          code = match.group(1)!;
          final parsedMessage = match.group(2);
          message = (parsedMessage != null && parsedMessage.trim().isNotEmpty)
              ? parsedMessage
              : (messageStr ?? fallback);
        } else {
          message = messageStr ?? errorStr;
        }
      } else if (messageStr != null) {
        message = messageStr;
      }
    }

    return Failure(_mapToSocialCareError(code, message, statusCode));
  }

  /// Maps a backend error code to the corresponding [SocialCareError].
  ///
  /// Known codes are mapped to specific domain errors. Unknown codes
  /// are wrapped in [ServerError] which carries the backend message
  /// for the UI to display directly.
  SocialCareError _mapToSocialCareError(
    String code,
    String message,
    int httpStatus,
  ) {
    return switch (code) {
      // Registry — duplicate (backend code or HTTP status fallback)
      'REGP-001' || 'PAT-409' || 'SRV-409' => const DuplicatePatientError(),
      // Registry — validation
      'VAL-001' || 'PAT-003' => InvalidDataError(message),
      // Family — PR constraints
      'PAT-008' => const PrMemberRequiredError(),
      'PAT-009' => const MultiplePrimaryReferencesError(),
      // Everything else — pass the backend message through
      _ => ServerError(
        httpStatus: httpStatus,
        backendCode: code,
        backendMessage: message,
      ),
    };
  }

  /// Wraps a caught exception into a [SocialCareError] [Failure].
  ///
  /// [DioException] with connection/timeout types become [NetworkError].
  /// Everything else becomes [UnexpectedSocialCareError].
  Failure<T> _failureFromException<T>(Object e) {
    if (e is DioException) {
      final isNetwork = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => true,
        _ => false,
      };
      if (isNetwork) {
        return Failure(NetworkError(e.message ?? e.type.name));
      }
    }
    return Failure(UnexpectedSocialCareError(e));
  }

  /// Maps a raw JSON map to an [AuditEvent].
  AuditEvent _mapAuditEvent(Map<String, dynamic> data) {
    final occurredAtResult = TimeStamp.fromIso(data['occurredAt'] as String);
    final recordedAtResult = TimeStamp.fromIso(data['recordedAt'] as String);

    final occurredAt = switch (occurredAtResult) {
      Success(:final value) => value,
      Failure(:final error) => throw Exception('Invalid occurredAt: $error'),
    };

    final recordedAt = switch (recordedAtResult) {
      Success(:final value) => value,
      Failure(:final error) => throw Exception('Invalid recordedAt: $error'),
    };

    return AuditEvent.reconstitute(
      id: data['id'] as String,
      aggregateId: data['aggregateId'] as String,
      eventType: data['eventType'] as String,
      actorId: data['actorId'] as String?,
      payload: data['payload'] as Map<String, dynamic>,
      occurredAt: occurredAt,
      recordedAt: recordedAt,
    );
  }
}
