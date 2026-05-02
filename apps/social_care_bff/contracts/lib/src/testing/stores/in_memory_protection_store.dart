import '../../contract/dto/responses/protection/placement_history_response.dart';
import '../../contract/dto/responses/protection/referral_response.dart';
import '../../contract/dto/responses/protection/violation_report_response.dart';

/// In-memory collaborator that stores protection-context state:
/// - a list of [ViolationReportResponse] (rights violations),
/// - a list of [ReferralResponse],
/// - a [PlacementHistoryResponse] per patient.
class InMemoryProtectionStore {
  InMemoryProtectionStore();

  /// Rights violation reports, stored in insertion order.
  final List<ViolationReportResponse> violations = [];

  /// Referrals, stored in insertion order.
  final List<ReferralResponse> referrals = [];

  /// Placement history keyed by `patientId`.
  final Map<String, PlacementHistoryResponse> placementByPatient = {};

  /// Appends a violation report.
  void reportViolation(ViolationReportResponse violation) {
    violations.add(violation);
  }

  /// Appends a referral.
  void createReferral(ReferralResponse referral) {
    referrals.add(referral);
  }

  /// Replaces the placement history for the patient.
  void setPlacement(String patientId, PlacementHistoryResponse placement) {
    placementByPatient[patientId] = placement;
  }

  /// Snapshot of stored violations.
  List<ViolationReportResponse> listViolations() =>
      List<ViolationReportResponse>.from(violations);

  /// Snapshot of stored referrals.
  List<ReferralResponse> listReferrals() =>
      List<ReferralResponse>.from(referrals);

  /// Returns the placement for a patient, or `null`.
  PlacementHistoryResponse? getPlacement(String patientId) =>
      placementByPatient[patientId];

  /// Resets the store between tests.
  void clear() {
    violations.clear();
    referrals.clear();
    placementByPatient.clear();
  }
}
