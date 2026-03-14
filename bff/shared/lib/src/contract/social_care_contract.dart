import 'package:core/core.dart';
import '../domain/assessment/assessment_vos.dart';
import '../domain/assessment/community_support.dart';
import '../domain/assessment/educational_status.dart';
import '../domain/assessment/health_status.dart';
import '../domain/assessment/social_health_summary.dart';
import '../domain/assessment/work_and_income.dart';
import '../domain/care/care_vos.dart';
import '../domain/kernel/ids.dart';
import '../domain/models/lookup.dart';
import '../domain/registry/family_member.dart';
import '../domain/registry/patient.dart';
import '../domain/registry/registry_vos.dart';
import '../domain/protection/protection_vos.dart';

/// Main Backend For Frontend (BFF) contract for the Social Care module.
/// 
/// All implementations (Web/Desktop) must adhere to this interface,
/// ensuring the application logic layer remains platform agnostic.
abstract interface class SocialCareContract {
  // ==========================================
  // HEALTH (Public)
  // ==========================================

  /// Liveness probe - returns success if the service is running.
  Future<Result<void>> checkHealth();

  /// Readiness probe - checks connectivity with dependencies (e.g., database).
  Future<Result<void>> checkReady();

  // ==========================================
  // REGISTRY (Patients & Family)
  // ==========================================

  /// Registers a new patient. Returns the generated [PatientId].
  Future<Result<PatientId>> registerPatient(Patient patient);

  /// Retrieves a patient by their unique [id].
  Future<Result<Patient>> getPatient(PatientId id);

  /// Retrieves a patient by their associated [personId].
  Future<Result<Patient>> getPatientByPersonId(PersonId personId);

  /// Adds a new family member to a patient's record.
  Future<Result<void>> addFamilyMember(PatientId patientId, FamilyMember member, LookupId prRelationshipId);

  /// Removes a family member from a patient's record.
  Future<Result<void>> removeFamilyMember(PatientId patientId, PersonId memberId);

  /// Assigns a primary caregiver for the patient.
  Future<Result<void>> assignPrimaryCaregiver(PatientId patientId, PersonId memberId);

  /// Updates the social identity of a patient.
  Future<Result<void>> updateSocialIdentity(PatientId patientId, SocialIdentity identity);

  /// Retrieves the audit trail for a specific patient.
  /// TODO: Define AuditEvent model.
  Future<Result<List<dynamic>>> getAuditTrail(PatientId patientId, {String? eventType});

  // ==========================================
  // ASSESSMENT (Evaluations)
  // ==========================================

  /// Updates housing condition assessment.
  Future<Result<void>> updateHousingCondition(PatientId patientId, HousingCondition condition);

  /// Updates socioeconomic situation assessment.
  Future<Result<void>> updateSocioEconomicSituation(PatientId patientId, SocioEconomicSituation situation);

  /// Updates work and income assessment.
  Future<Result<void>> updateWorkAndIncome(PatientId patientId, WorkAndIncome data);

  /// Updates educational status assessment.
  Future<Result<void>> updateEducationalStatus(PatientId patientId, EducationalStatus status);

  /// Updates health status assessment.
  Future<Result<void>> updateHealthStatus(PatientId patientId, HealthStatus status);

  /// Updates community support network assessment.
  Future<Result<void>> updateCommunitySupportNetwork(PatientId patientId, CommunitySupportNetwork network);

  /// Updates social health summary assessment.
  Future<Result<void>> updateSocialHealthSummary(PatientId patientId, SocialHealthSummary summary);

  // ==========================================
  // CARE (Appointments & Intake)
  // ==========================================

  /// Registers a new social care appointment. Returns the generated [AppointmentId].
  Future<Result<AppointmentId>> registerAppointment(PatientId patientId, SocialCareAppointment appointment);

  /// Updates the intake (acolhimento) information.
  Future<Result<void>> updateIntakeInfo(PatientId patientId, IngressInfo info);

  // ==========================================
  // PROTECTION (Referrals & Violations)
  // ==========================================

  /// Updates the institutional placement history.
  Future<Result<void>> updatePlacementHistory(PatientId patientId, PlacementHistory history);

  /// Reports a new rights violation. Returns the generated [ViolationReportId].
  Future<Result<ViolationReportId>> reportViolation(PatientId patientId, RightsViolationReport report);

  /// Creates a new referral. Returns the generated [ReferralId].
  Future<Result<ReferralId>> createReferral(PatientId patientId, Referral referral);

  // ==========================================
  // LOOKUP (Domain Tables)
  // ==========================================

  /// Fetches items from a domain table (e.g., `dominio_parentesco`).
  Future<Result<List<LookupItem>>> getLookupTable(String tableName);
}
