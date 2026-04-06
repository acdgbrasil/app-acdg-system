import 'package:core_contracts/core_contracts.dart';
import '../contract/social_care_contract.dart';
import '../infrastructure/dtos/patient_remote.dart';
import '../infrastructure/dtos/patient_overview.dart';
import '../infrastructure/patient_translator.dart';
import '../domain/assessment/assessment_vos.dart';
import '../domain/assessment/community_support.dart';
import '../domain/assessment/educational_status.dart';
import '../domain/assessment/health_status.dart';
import '../domain/assessment/social_health_summary.dart';
import '../domain/assessment/work_and_income.dart';
import '../domain/care/care_vos.dart';
import '../domain/kernel/ids.dart';
import '../domain/models/lookup.dart';
import '../domain/audit/audit_event.dart';
import '../domain/registry/family_member.dart';
import '../domain/registry/patient.dart';
import '../domain/registry/registry_vos.dart';
import '../domain/protection/protection_vos.dart';

/// Implementation of [SocialCareContract] for testing and local simulation.
class FakeSocialCareBff implements SocialCareContract {
  FakeSocialCareBff({this.delay = const Duration(milliseconds: 200)});

  final Duration delay;
  final Map<String, Patient> _patients = {};

  @override
  Future<Result<void>> checkHealth() async => const Success(null);

  @override
  Future<Result<void>> checkReady() async => const Success(null);

  @override
  Future<Result<List<PatientOverview>>> fetchPatients() async {
    await Future.delayed(delay);
    return Success(_patients.values.map((p) => PatientOverview(
      patientId: p.id.value,
      personId: p.personId.value,
      firstName: p.personalData?.firstName,
      lastName: p.personalData?.lastName,
      fullName: '${p.personalData?.firstName ?? ''} ${p.personalData?.lastName ?? ''}'.trim(),
      primaryDiagnosis: p.diagnoses.isNotEmpty ? p.diagnoses.first.description : null,
      memberCount: p.familyMembers.length,
    )).toList());
  }

  @override
  Future<Result<PatientId>> registerPatient(Patient patient) async {
    await Future.delayed(delay);
    _patients[patient.id.value] = patient;
    return Success(patient.id);
  }

  @override
  Future<Result<PatientRemote>> fetchPatient(PatientId id) async {
    await Future.delayed(delay);
    final p = _patients[id.value];
    if (p == null) return Failure('Patient not found: ${id.value}');
    return Success(PatientRemote.fromJson(PatientTranslator.toJson(p)));
  }

  @override
  Future<Result<PatientRemote>> fetchPatientByPersonId(PersonId personId) async {
    await Future.delayed(delay);
    try {
      final p = _patients.values.firstWhere((p) => p.personId == personId);
      return Success(PatientRemote.fromJson(PatientTranslator.toJson(p)));
    } catch (_) {
      return Failure('Patient not found for person: ${personId.value}');
    }
  }

  @override
  Future<Result<void>> addFamilyMember(
    PatientId patientId,
    FamilyMember member,
    LookupId prRelationshipId,
  ) async => const Success(null);

  @override
  Future<Result<void>> removeFamilyMember(
    PatientId patientId,
    PersonId memberId,
  ) async => const Success(null);

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    PatientId patientId,
    PersonId memberId,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateSocialIdentity(
    PatientId patientId,
    SocialIdentity identity,
  ) async => const Success(null);

  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(
    PatientId patientId, {
    String? eventType,
  }) async => const Success([]);

  @override
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    PatientId patientId,
    SocioEconomicSituation situation,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateWorkAndIncome(
    PatientId patientId,
    WorkAndIncome data,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateEducationalStatus(
    PatientId patientId,
    EducationalStatus status,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateHealthStatus(
    PatientId patientId,
    HealthStatus status,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    PatientId patientId,
    CommunitySupportNetwork network,
  ) async => const Success(null);

  @override
  Future<Result<void>> updateSocialHealthSummary(
    PatientId patientId,
    SocialHealthSummary summary,
  ) async => const Success(null);

  @override
  Future<Result<AppointmentId>> registerAppointment(
    PatientId patientId,
    SocialCareAppointment appointment,
  ) async => Success(appointment.id);

  @override
  Future<Result<void>> updateIntakeInfo(
    PatientId patientId,
    IngressInfo info,
  ) async => const Success(null);

  @override
  Future<Result<void>> updatePlacementHistory(
    PatientId patientId,
    PlacementHistory history,
  ) async => const Success(null);

  @override
  Future<Result<ViolationReportId>> reportViolation(
    PatientId patientId,
    RightsViolationReport report,
  ) async => Success(report.id);

  @override
  Future<Result<ReferralId>> createReferral(
    PatientId patientId,
    Referral referral,
  ) async => Success(referral.id);

  @override
  Future<Result<List<LookupItem>>> getLookupTable(String tableName) async {
    return const Success([]);
  }
}
