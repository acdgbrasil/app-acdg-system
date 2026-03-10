import 'package:core/core.dart';

import '../models/audit_event.dart';
import '../models/lookup_item.dart';
import '../models/patient.dart';
import 'dto/requests/assessment_requests.dart';
import 'dto/requests/care_requests.dart';
import 'dto/requests/protection_requests.dart';
import 'dto/requests/registry_requests.dart';

/// Abstract contract defining all operations available in the Social Care BFF.
///
/// Flutter micro-apps depend on this interface. Concrete implementations:
/// - [InProcessBff] — desktop (direct Dart calls via API client)
/// - Darto HTTP server — web (future)
abstract class SocialCareContract {
  // ──────────────────────────── Registry ────────────────────────────

  /// Registers a new patient. Returns the created patient ID.
  Future<Result<String>> registerPatient({
    required String actorId,
    required RegisterPatientRequest request,
  });

  /// Gets a patient by their patient ID.
  Future<Result<Patient>> getPatientById(String patientId);

  /// Gets a patient by their person ID.
  Future<Result<Patient>> getPatientByPersonId(String personId);

  /// Adds a family member to a patient.
  Future<Result<void>> addFamilyMember({
    required String patientId,
    required String actorId,
    required AddFamilyMemberRequest request,
  });

  /// Removes a family member from a patient.
  Future<Result<void>> removeFamilyMember({
    required String patientId,
    required String memberId,
    required String actorId,
  });

  /// Assigns a family member as the primary caregiver.
  Future<Result<void>> assignPrimaryCaregiver({
    required String patientId,
    required String actorId,
    required AssignPrimaryCaregiverRequest request,
  });

  /// Updates the social identity classification.
  Future<Result<void>> updateSocialIdentity({
    required String patientId,
    required String actorId,
    required UpdateSocialIdentityRequest request,
  });

  // ──────────────────────────── Audit ────────────────────────────

  /// Returns the event history for a patient aggregate.
  Future<Result<List<AuditEvent>>> getAuditTrail(
    String patientId, {
    String? eventType,
  });

  // ──────────────────────────── Assessment ────────────────────────────

  /// Updates housing condition assessment.
  Future<Result<void>> updateHousingCondition({
    required String patientId,
    required String actorId,
    required UpdateHousingConditionRequest request,
  });

  /// Updates socioeconomic situation assessment.
  Future<Result<void>> updateSocioEconomicSituation({
    required String patientId,
    required String actorId,
    required UpdateSocioEconomicSituationRequest request,
  });

  /// Updates work and income assessment.
  Future<Result<void>> updateWorkAndIncome({
    required String patientId,
    required String actorId,
    required UpdateWorkAndIncomeRequest request,
  });

  /// Updates educational status assessment.
  Future<Result<void>> updateEducationalStatus({
    required String patientId,
    required String actorId,
    required UpdateEducationalStatusRequest request,
  });

  /// Updates health status assessment.
  Future<Result<void>> updateHealthStatus({
    required String patientId,
    required String actorId,
    required UpdateHealthStatusRequest request,
  });

  /// Updates community support network assessment.
  Future<Result<void>> updateCommunitySupportNetwork({
    required String patientId,
    required String actorId,
    required UpdateCommunitySupportNetworkRequest request,
  });

  /// Updates social health summary.
  Future<Result<void>> updateSocialHealthSummary({
    required String patientId,
    required String actorId,
    required UpdateSocialHealthSummaryRequest request,
  });

  // ──────────────────────────── Care ────────────────────────────

  /// Registers a social care appointment. Returns the appointment ID.
  Future<Result<String>> registerAppointment({
    required String patientId,
    required String actorId,
    required RegisterAppointmentRequest request,
  });

  /// Registers intake/ingress information.
  Future<Result<void>> registerIntakeInfo({
    required String patientId,
    required String actorId,
    required RegisterIntakeInfoRequest request,
  });

  // ──────────────────────────── Protection ────────────────────────────

  /// Updates institutional placement history.
  Future<Result<void>> updatePlacementHistory({
    required String patientId,
    required String actorId,
    required UpdatePlacementHistoryRequest request,
  });

  /// Reports a rights violation. Returns the report ID.
  Future<Result<String>> reportRightsViolation({
    required String patientId,
    required String actorId,
    required ReportRightsViolationRequest request,
  });

  /// Creates a referral to another service. Returns the referral ID.
  Future<Result<String>> createReferral({
    required String patientId,
    required String actorId,
    required CreateReferralRequest request,
  });

  // ──────────────────────────── Lookup ────────────────────────────

  /// Returns active items from a domain lookup table.
  Future<Result<List<LookupItem>>> listLookupItems(String tableName);
}
