import 'dart:convert';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:shared/shared.dart';

/// Implementation of [SocialCareContract] that communicates with the real Backend API.
class SocialCareBffRemote implements SocialCareContract {
  SocialCareBffRemote({
    required String baseUrl,
    required String authToken,
    required String actorId,
    Dio? dio,
  }) : _dio = dio ?? Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Bearer $authToken',
            'X-Actor-Id': actorId,
            'Content-Type': 'application/json',
          },
        ));

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
  Future<Result<PatientId>> registerPatient(Patient patient) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/patients',
        data: _mapPatientToApi(patient),
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
  Future<Result<Patient>> getPatient(PatientId id) async {
    try {
      final url = '/api/v1/patients/${id.value}';
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return Success(_mapApiToPatient(data));
      }
      return Failure(response.data ?? 'Patient not found');
    } catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<Patient>> getPatientByPersonId(PersonId personId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/patients/by-person/${personId.value}',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return Success(_mapApiToPatient(data));
      }
      return Failure(response.data ?? 'Patient not found');
    } catch (e) {
      return Failure(e);
    }
  }

  // --- Map Helpers (Injected logic based on API-REFERENCE.md) ---

  Map<String, dynamic> _mapPatientToApi(Patient p) {
    return {
      'personId': p.personId.value,
      'prRelationshipId': p.prRelationshipId.value,
      'personalData': {
        'firstName': p.personalData?.firstName,
        'lastName': p.personalData?.lastName,
        'motherName': p.personalData?.motherName,
        'nationality': p.personalData?.nationality,
        'sex': p.personalData?.sex.name,
        'socialName': p.personalData?.socialName,
        'birthDate': p.personalData?.birthDate.toIso8601(),
        'phone': p.personalData?.phone,
      },
      'civilDocuments': {
        'cpf': p.civilDocuments?.cpf?.value,
        'nis': p.civilDocuments?.nis?.value,
        'rgDocument': p.civilDocuments?.rgDocument == null ? null : {
          'number': p.civilDocuments!.rgDocument!.number,
          'issuingState': p.civilDocuments!.rgDocument!.issuingState,
          'issuingAgency': p.civilDocuments!.rgDocument!.issuingAgency,
          'issueDate': p.civilDocuments!.rgDocument!.issueDate.toIso8601(),
        },
      },
      'address': {
        'cep': p.address?.cep?.value,
        'isShelter': p.address?.isShelter,
        'residenceLocation': p.address?.residenceLocation == ResidenceLocation.urbano ? 'URBANO' : 'RURAL',
        'street': p.address?.street,
        'neighborhood': p.address?.neighborhood,
        'number': p.address?.number,
        'complement': p.address?.complement,
        'state': p.address?.state,
        'city': p.address?.city,
      },
      'initialDiagnoses': p.diagnoses.map((d) => {
        'icdCode': d.id.value,
        'date': d.date.toIso8601(),
        'description': d.description,
      }).toList(),
      'familyMembers': p.familyMembers.map((m) => {
        'personId': m.personId.value,
        'relationshipId': m.relationshipId.value,
        'isPrimaryCaregiver': m.isPrimaryCaregiver,
        'residesWithPatient': m.residesWithPatient,
        'hasDisability': m.hasDisability,
        'requiredDocuments': m.requiredDocuments.map((d) => d.value).toList(),
        'birthDate': m.birthDate.toIso8601(),
      }).toList(),
    };
  }

  Patient _mapApiToPatient(Map<String, dynamic> data) {
    final prRelId = data['prRelationshipId'] as String? ?? '00000000-0000-0000-0000-000000000000';
    
    // Map family members
    final List<dynamic> membersJson = data['familyMembers'] ?? [];
    final familyMembers = membersJson.map((m) {
      return FamilyMember.reconstitute(
        personId: PersonId.create(m['personId'] as String).valueOrNull!,
        relationshipId: LookupId.create(m['relationshipId'] as String).valueOrNull!,
        isPrimaryCaregiver: m['isPrimaryCaregiver'] as bool? ?? false,
        residesWithPatient: m['residesWithPatient'] as bool? ?? false,
        hasDisability: m['hasDisability'] as bool? ?? false,
        requiredDocuments: (m['requiredDocuments'] as List? ?? [])
            .map((d) => RequiredDocument.values.firstWhere((v) => v.value == d))
            .toList(),
        birthDate: TimeStamp.fromIso(m['birthDate'] as String).valueOrNull!,
      );
    }).toList();

    return Patient.reconstitute(
      id: PatientId.create(data['patientId'] as String).valueOrNull!,
      version: data['version'] as int? ?? 1,
      personId: PersonId.create(data['personId'] as String).valueOrNull!,
      prRelationshipId: LookupId.create(prRelId).valueOrNull!,
      familyMembers: familyMembers,
    );
  }

  // Implementation of other methods omitted for brevity in this stage
  @override
  Future<Result<void>> addFamilyMember(PatientId patientId, FamilyMember member, LookupId prRelationshipId) async {
    try {
      final payload = {
        'memberPersonId': member.personId.value,
        'relationship': member.relationshipId.value,
        'isResiding': member.residesWithPatient,
        'isCaregiver': member.isPrimaryCaregiver,
        'hasDisability': member.hasDisability,
        'requiredDocuments': member.requiredDocuments.map((d) => d.value).toList(),
        'birthDate': member.birthDate.toIso8601(),
        'prRelationshipId': prRelationshipId.value,
      };

      final response = await _dio.post(
        '/api/v1/patients/${patientId.value}/family-members',
        data: payload,
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 204 || response.statusCode == 201 || response.statusCode == 200) {
        return const Success(null);
      }
      return Failure(response.data ?? 'Failed to add family member');
    } catch (e) {
      return Failure(e);
    }
  }
  @override
  Future<Result<void>> removeFamilyMember(PatientId patientId, PersonId memberId) async {
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
  Future<Result<void>> assignPrimaryCaregiver(PatientId patientId, PersonId memberId) async {
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
  Future<Result<void>> updateSocialIdentity(PatientId patientId, SocialIdentity identity) async {
    try {
      final response = await _dio.put(
        '/api/v1/patients/${patientId.value}/social-identity',
        data: {
          'typeId': identity.typeId.value,
          if (identity.otherDescription != null) 'description': identity.otherDescription,
        },
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
  Future<Result<List>> getAuditTrail(PatientId patientId, {String? eventType}) async => const Success([]);
  @override
  Future<Result<void>> updateHousingCondition(PatientId patientId, HousingCondition condition) async => const Success(null);
  @override
  Future<Result<void>> updateSocioEconomicSituation(PatientId patientId, SocioEconomicSituation situation) async => const Success(null);
  @override
  Future<Result<void>> updateWorkAndIncome(PatientId patientId, WorkAndIncome data) async => const Success(null);
  @override
  Future<Result<void>> updateEducationalStatus(PatientId patientId, EducationalStatus status) async => const Success(null);
  @override
  Future<Result<void>> updateHealthStatus(PatientId patientId, HealthStatus status) async => const Success(null);
  @override
  Future<Result<void>> updateCommunitySupportNetwork(PatientId patientId, CommunitySupportNetwork network) async => const Success(null);
  @override
  Future<Result<void>> updateSocialHealthSummary(PatientId patientId, SocialHealthSummary summary) async => const Success(null);
  @override
  Future<Result<AppointmentId>> registerAppointment(PatientId patientId, SocialCareAppointment appointment) async => Success(appointment.id);
  @override
  Future<Result<void>> updateIntakeInfo(PatientId patientId, IngressInfo info) async => const Success(null);
  @override
  Future<Result<void>> updatePlacementHistory(PatientId patientId, PlacementHistory history) async => const Success(null);
  @override
  Future<Result<ViolationReportId>> reportViolation(PatientId patientId, RightsViolationReport report) async => Success(report.id);
  @override
  Future<Result<ReferralId>> createReferral(PatientId patientId, Referral referral) async => Success(referral.id);
  @override
  Future<Result<List<LookupItem>>> getLookupTable(String tableName) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/dominios/$tableName',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data!['data'];
        return Success(data.map((item) => LookupItem(
          id: item['id'] as String,
          codigo: item['codigo'] as String,
          descricao: item['descricao'] as String,
        )).toList());
      }
      return Failure('Lookup table $tableName not found');
    } catch (e) {
      return Failure(e);
    }
  }
}
