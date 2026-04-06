import 'dart:developer' as developer;

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

/// Implementation of [SocialCareContract] that communicates with the real
/// backend API (Swift/Vapor) via HTTP.
///
/// This is the pure-Dart equivalent of `SocialCareBffRemote` from the desktop
/// BFF, without Flutter dependencies. It is used by the Web BFF server to
/// proxy authenticated requests to the backend.
class SocialCareApiClient implements SocialCareContract {
  SocialCareApiClient({
    required String baseUrl,
    required String actorId,
    required String accessToken,
    Dio? dio,
  }) : _dio =
           dio ??
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

  @override
  Future<Result<List<PatientOverview>>> fetchPatients() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/patients',
        queryParameters: {'limit': 100},
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data!['data'] as List<dynamic>;
        final summaries = data
            .cast<Map<String, dynamic>>()
            .map(PatientOverview.fromJson)
            .toList();
        return Success(summaries);
      }
      return Failure(response.data ?? 'Failed to list patients');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<PatientId>> registerPatient(Patient patient) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/patients',
        data: PatientTranslator.toJson(patient),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return PatientId.create(data['id'] as String);
      }
      return Failure(response.data ?? 'Unknown backend error');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<PatientRemote>> fetchPatient(PatientId id) async {
    try {
      final url = '/api/v1/patients/${id.value}';
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return Success(PatientRemote.fromJson(data));
      }
      return Failure(response.data ?? 'Patient not found');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<PatientRemote>> fetchPatientByPersonId(
    PersonId personId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/patients/by-person/${personId.value}',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return Success(PatientRemote.fromJson(data));
      }
      return Failure(response.data ?? 'Patient not found');
    } catch (e) {
      return Failure(e);
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

      developer.log(
        'addFamilyMember POST: /api/v1/patients/${patientId.value}/family-members',
        name: 'SocialCareApiClient',
      );

      final response = await _dio.post(
        '/api/v1/patients/${patientId.value}/family-members',
        data: payload,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 ||
          response.statusCode == 201 ||
          response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(response.data ?? 'Failed to add family member');
    } catch (e) {
      developer.log(
        'CRITICAL ERROR: $e',
        name: 'SocialCareApiClient',
        level: 1000,
      );
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> removeFamilyMember(
    PatientId patientId,
    PersonId memberId,
  ) async {
    try {
      final response = await _dio.delete(
        '/api/v1/patients/${patientId.value}/family-members/${memberId.value}',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(response.data ?? 'Failed to remove family member');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    PatientId patientId,
    PersonId memberId,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/${patientId.value}/primary-caregiver',
        data: {'memberPersonId': memberId.value},
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(response.data ?? 'Failed to assign primary caregiver');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateSocialIdentity(
    PatientId patientId,
    SocialIdentity identity,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/${patientId.value}/social-identity',
        data: PatientTranslator.socialIdentityToJson(identity),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(response.data ?? 'Failed to update social identity');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(
    PatientId patientId, {
    String? eventType,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/patients/${patientId.value}/audit-trail',
        queryParameters: eventType != null ? {'eventType': eventType} : null,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data!['data'];
        return Success(data.map((item) => _mapApiToAuditEvent(item)).toList());
      }
      return Failure(response.data ?? 'Failed to fetch audit trail');
    } catch (e) {
      return Failure(e);
    }
  }

  AuditEvent _mapApiToAuditEvent(Map<String, dynamic> data) {
    return AuditEvent.reconstitute(
      id: data['id'] as String,
      aggregateId: data['aggregateId'] as String,
      eventType: data['eventType'] as String,
      actorId: data['actorId'] as String?,
      payload: data['payload'] as Map<String, dynamic>,
      occurredAt: TimeStamp.fromIso(data['occurredAt'] as String).valueOrNull!,
      recordedAt: TimeStamp.fromIso(data['recordedAt'] as String).valueOrNull!,
    );
  }

  @override
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/${patientId.value}/housing-condition',
        data: PatientTranslator.housingConditionToJson(condition),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(response.data ?? 'Failed to update housing condition');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    PatientId patientId,
    SocioEconomicSituation situation,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/${patientId.value}/socioeconomic-situation',
        data: PatientTranslator.socioEconomicToJson(situation),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(
        response.data ?? 'Failed to update socio-economic situation',
      );
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateWorkAndIncome(
    PatientId patientId,
    WorkAndIncome data,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/${patientId.value}/work-and-income',
        data: PatientTranslator.workAndIncomeToJson(data),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(response.data ?? 'Failed to update work and income');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateEducationalStatus(
    PatientId patientId,
    EducationalStatus status,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/${patientId.value}/educational-status',
        data: PatientTranslator.educationalStatusToJson(status),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(response.data ?? 'Failed to update educational status');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateHealthStatus(
    PatientId patientId,
    HealthStatus status,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/${patientId.value}/health-status',
        data: PatientTranslator.healthStatusToJson(status),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(response.data ?? 'Failed to update health status');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    PatientId patientId,
    CommunitySupportNetwork network,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/${patientId.value}/community-support-network',
        data: PatientTranslator.communitySupportToJson(network),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(
        response.data ?? 'Failed to update community support network',
      );
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateSocialHealthSummary(
    PatientId patientId,
    SocialHealthSummary summary,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/${patientId.value}/social-health-summary',
        data: PatientTranslator.socialHealthSummaryToJson(summary),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(response.data ?? 'Failed to update social health summary');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<AppointmentId>> registerAppointment(
    PatientId patientId,
    SocialCareAppointment appointment,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/patients/${patientId.value}/appointments',
        data: PatientTranslator.appointmentToJson(appointment),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return AppointmentId.create(data['id'] as String);
      }
      return Failure(response.data ?? 'Failed to register appointment');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updateIntakeInfo(
    PatientId patientId,
    IngressInfo info,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/${patientId.value}/intake-info',
        data: PatientTranslator.intakeInfoToJson(info),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(response.data ?? 'Failed to update intake info');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> updatePlacementHistory(
    PatientId patientId,
    PlacementHistory history,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/${patientId.value}/placement-history',
        data: PatientTranslator.placementHistoryToJson(history),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(response.data ?? 'Failed to update placement history');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<ViolationReportId>> reportViolation(
    PatientId patientId,
    RightsViolationReport report,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/patients/${patientId.value}/violation-reports',
        data: PatientTranslator.violationReportToJson(report),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return ViolationReportId.create(data['id'] as String);
      }
      return Failure(response.data ?? 'Failed to report violation');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<ReferralId>> createReferral(
    PatientId patientId,
    Referral referral,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/patients/${patientId.value}/referrals',
        data: PatientTranslator.referralToJson(referral),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return ReferralId.create(data['id'] as String);
      }
      return Failure(response.data ?? 'Failed to create referral');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<List<LookupItem>>> getLookupTable(String tableName) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/dominios/$tableName',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data!['data'];
        return Success(
          data
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
      return Failure('Lookup table $tableName not found');
    } catch (e) {
      return Failure(e);
    }
  }
}
