import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'package:social_care/src/ui/home/models/patient_summary.dart';

/// Repository contract for Patient-related operations.
///
/// Abstracts how patient data is fetched and persisted,
/// allowing the UseCase layer to remain agnostic of infrastructure.
abstract class PatientRepository {
  /// Lists all patients as typed summaries.
  Future<Result<List<PatientSummary>>> listPatients();

  /// Registers a new patient. Returns the generated [PatientId].
  Future<Result<PatientId>> registerPatient(Patient patient);

  /// Retrieves a patient by their unique [id].
  Future<Result<Patient>> getPatient(PatientId id);

  /// Retrieves a patient by their associated [personId].
  Future<Result<Patient>> getPatientByPersonId(PersonId personId);

  /// Adds a new family member to a patient's record.
  Future<Result<void>> addFamilyMember(
    PatientId patientId,
    FamilyMember member,
    LookupId prRelationshipId);

  /// Removes a family member from a patient's record.
  Future<Result<void>> removeFamilyMember(
    PatientId patientId,
    PersonId memberId,
  );

  /// Assigns a primary caregiver for the patient.
  Future<Result<void>> assignPrimaryCaregiver(
    PatientId patientId,
    PersonId memberId,
  );

  /// Updates the social identity of a patient.
  Future<Result<void>> updateSocialIdentity(
    PatientId patientId,
    SocialIdentity identity,
  );

  /// Retrieves the audit trail for a specific patient.
  Future<Result<List<AuditEvent>>> getAuditTrail(
    PatientId patientId, {
    String? eventType,
  });

  /// Updates housing condition assessment.
  Future<Result<void>> updateHousingCondition(
    PatientId patientId,
    HousingCondition condition,
  );

  /// Updates socioeconomic situation assessment.
  Future<Result<void>> updateSocioEconomicSituation(
    PatientId patientId,
    SocioEconomicSituation situation,
  );

  /// Updates work and income assessment.
  Future<Result<void>> updateWorkAndIncome(
    PatientId patientId,
    WorkAndIncome data,
  );

  /// Updates educational status assessment.
  Future<Result<void>> updateEducationalStatus(
    PatientId patientId,
    EducationalStatus status,
  );

  /// Updates health status assessment.
  Future<Result<void>> updateHealthStatus(
    PatientId patientId,
    HealthStatus status,
  );

  /// Updates community support network assessment.
  Future<Result<void>> updateCommunitySupportNetwork(
    PatientId patientId,
    CommunitySupportNetwork network,
  );

  /// Updates social health summary assessment.
  Future<Result<void>> updateSocialHealthSummary(
    PatientId patientId,
    SocialHealthSummary summary,
  );

  /// Registers a new social care appointment. Returns the generated [AppointmentId].
  Future<Result<AppointmentId>> registerAppointment(
    PatientId patientId,
    SocialCareAppointment appointment,
  );

  /// Updates the intake (acolhimento) information.
  Future<Result<void>> updateIntakeInfo(PatientId patientId, IngressInfo info);

  /// Updates the institutional placement history.
  Future<Result<void>> updatePlacementHistory(
    PatientId patientId,
    PlacementHistory history,
  );

  /// Reports a new rights violation. Returns the generated [ViolationReportId].
  Future<Result<ViolationReportId>> reportViolation(
    PatientId patientId,
    RightsViolationReport report,
  );

  /// Creates a new referral. Returns the generated [ReferralId].
  Future<Result<ReferralId>> createReferral(
    PatientId patientId,
    Referral referral,
  );
}
