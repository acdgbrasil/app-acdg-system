import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

import '_http_shared.dart';

/// Split from HttpSocialCareClient — Registry endpoints (Patient + Family + Audit).
///
/// Organizational split: no logic changes.
class RegistryHttpClient {
  RegistryHttpClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

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
      return failureFromResponse(response, 'Failed to fetch patients');
    } catch (e) {
      return failureFromException(e);
    }
  }

  Future<Result<PatientId>> registerPatient(Patient patient) async {
    try {
      final payload = PatientTranslator.toJson(patient);
      final members = payload['familyMembers'] as List?;
      print('📤 POST /patients — familyMembers count: ${members?.length ?? 0}');
      for (final m in members ?? []) {
        print('📤   member: personId=${m['personId']}, rel=${m['relationship']}, name=${m['fullName']}');
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/patients',
        data: payload,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final id = response.data!['id'] as String;
        return PatientId.create(id);
      }
      return failureFromResponse(response, 'Failed to register patient');
    } catch (e) {
      return failureFromException(e);
    }
  }

  Future<Result<PatientRemote>> fetchPatient(PatientId id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/patients/${id.value}',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        return Success(PatientRemote.fromJson(response.data!));
      }
      return failureFromResponse(response, 'Patient not found');
    } catch (e) {
      return failureFromException(e);
    }
  }

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
      return failureFromResponse(response, 'Patient not found');
    } catch (e) {
      return failureFromException(e);
    }
  }

  Future<Result<void>> addFamilyMember(
    PatientId patientId,
    FamilyMember member,
    LookupId prRelationshipId, {
    String? cpf,
  }) async {
    try {
      final payload = {
        ...PatientTranslator.familyMemberToJson(member),
        'prRelationshipId': prRelationshipId.value,
        'cpf': cpf,
      };

      final response = await _dio.post<dynamic>(
        '/patients/${patientId.value}/family-members',
        data: payload,
        options: Options(validateStatus: (status) => true),
      );

      if (isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return failureFromResponse(response, 'Failed to add family member');
    } catch (e) {
      return failureFromException(e);
    }
  }

  Future<Result<void>> removeFamilyMember(
    PatientId patientId,
    PersonId memberId,
  ) async {
    try {
      final response = await _dio.delete<dynamic>(
        '/patients/${patientId.value}/family-members/${memberId.value}',
        options: Options(validateStatus: (status) => true),
      );

      if (isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return failureFromResponse(response, 'Failed to remove family member');
    } catch (e) {
      return failureFromException(e);
    }
  }

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

      if (isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return failureFromResponse(
        response,
        'Failed to assign primary caregiver',
      );
    } catch (e) {
      return failureFromException(e);
    }
  }

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

      if (isSuccessStatus(response.statusCode)) {
        return const Success(null);
      }
      return failureFromResponse(response, 'Failed to update social identity');
    } catch (e) {
      return failureFromException(e);
    }
  }

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
          data.cast<Map<String, dynamic>>().map(mapAuditEvent).toList(),
        );
      }
      return failureFromResponse(response, 'Failed to fetch audit trail');
    } catch (e) {
      return failureFromException(e);
    }
  }
}
