import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/data/services/patient_service.dart';
import 'package:social_care/src/ui/home/models/patient_summary.dart';

import 'patient_repository.dart';

/// [PatientRepository] implementation backed by the Social Care BFF.
///
/// Uses [PatientService] for raw BFF calls, then maps API models
/// to typed domain/UI models.
class BffPatientRepository implements PatientRepository {
  BffPatientRepository({
    required SocialCareContract bff,
    required PatientService patientService,
  }) : _bff = bff,
       _patientService = patientService;

  final SocialCareContract _bff;
  final PatientService _patientService;

  @override
  Future<Result<List<PatientSummary>>> listPatients() async {
    final result = await _patientService.fetchPatients();

    return switch (result) {
      Success(:final value) => Success(
        value
            .map(
              (dto) => PatientSummary(
                patientId: dto.patientId,
                firstName: dto.firstName ?? '—',
                lastName: dto.lastName ?? '—',
                fullName:
                    dto.fullName ??
                    '${dto.firstName ?? '—'} ${dto.lastName ?? '—'}',
                primaryDiagnosis: dto.primaryDiagnosis,
                memberCount: dto.memberCount,
              ),
            )
            .toList(),
      ),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<PatientId>> registerPatient(Patient patient) {
    return _bff.registerPatient(patient);
  }

  @override
  Future<Result<Patient>> getPatient(PatientId id) async {
    final result = await _patientService.fetchPatient(id);

    return switch (result) {
      Success(:final value) => PatientTranslator.toDomain(value),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<Patient>> getPatientByPersonId(PersonId personId) async {
    final result = await _bff.fetchPatientByPersonId(personId);

    return switch (result) {
      Success(:final value) => PatientTranslator.toDomain(value),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> addFamilyMember(
    PatientId patientId,
    FamilyMember member,
    LookupId prRelationshipId,
  ) {
    return _bff.addFamilyMember(patientId, member, prRelationshipId);
  }

  @override
  Future<Result<void>> removeFamilyMember(
    PatientId patientId,
    PersonId memberId,
  ) {
    return _bff.removeFamilyMember(patientId, memberId);
  }

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    PatientId patientId,
    PersonId memberId,
  ) {
    return _bff.assignPrimaryCaregiver(patientId, memberId);
  }

  @override
  Future<Result<void>> updateSocialIdentity(
    PatientId patientId,
    SocialIdentity identity,
  ) {
    return _bff.updateSocialIdentity(patientId, identity);
  }

  @override
  Future<Result<List<AuditEvent>>> getAuditTrail(
    PatientId patientId, {
    String? eventType,
  }) {
    return _bff.getAuditTrail(patientId, eventType: eventType);
  }

  @override
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  ) {
    return _bff.updateHousingCondition(patientId, condition);
  }

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    PatientId patientId,
    SocioEconomicSituation situation,
  ) {
    return _bff.updateSocioEconomicSituation(patientId, situation);
  }

  @override
  Future<Result<void>> updateWorkAndIncome(
    PatientId patientId,
    WorkAndIncome data,
  ) {
    return _bff.updateWorkAndIncome(patientId, data);
  }

  @override
  Future<Result<void>> updateEducationalStatus(
    PatientId patientId,
    EducationalStatus status,
  ) {
    return _bff.updateEducationalStatus(patientId, status);
  }

  @override
  Future<Result<void>> updateHealthStatus(
    PatientId patientId,
    HealthStatus status,
  ) {
    return _bff.updateHealthStatus(patientId, status);
  }

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    PatientId patientId,
    CommunitySupportNetwork network,
  ) {
    return _bff.updateCommunitySupportNetwork(patientId, network);
  }

  @override
  Future<Result<void>> updateSocialHealthSummary(
    PatientId patientId,
    SocialHealthSummary summary,
  ) {
    return _bff.updateSocialHealthSummary(patientId, summary);
  }

  @override
  Future<Result<AppointmentId>> registerAppointment(
    PatientId patientId,
    SocialCareAppointment appointment,
  ) {
    return _bff.registerAppointment(patientId, appointment);
  }

  @override
  Future<Result<void>> updateIntakeInfo(PatientId patientId, IngressInfo info) {
    return _bff.updateIntakeInfo(patientId, info);
  }

  @override
  Future<Result<void>> updatePlacementHistory(
    PatientId patientId,
    PlacementHistory history,
  ) {
    return _bff.updatePlacementHistory(patientId, history);
  }

  @override
  Future<Result<ViolationReportId>> reportViolation(
    PatientId patientId,
    RightsViolationReport report,
  ) {
    return _bff.reportViolation(patientId, report);
  }

  @override
  Future<Result<ReferralId>> createReferral(
    PatientId patientId,
    Referral referral,
  ) {
    return _bff.createReferral(patientId, referral);
  }
}
