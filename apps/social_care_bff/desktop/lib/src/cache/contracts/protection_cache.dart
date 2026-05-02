import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Desktop-only Read Model for the three Protection-context aggregates:
/// Referrals, ViolationReports, and PlacementHistory. PlacementHistory
/// is one-per-patient (a single response object that wraps multiple
/// `PlacementRegistryResponse` entries internally), so the cache stores
/// it as a single row keyed by patientId.
abstract interface class ProtectionCache {
  // ── Referrals ────────────────────────────────────────────────────────
  Future<Result<ReferralResponse?>> findReferralById(
    String patientId,
    String referralId,
  );

  Future<Result<List<ReferralResponse>>> listReferrals(String patientId);

  Future<Result<void>> upsertReferral(
    String patientId,
    ReferralResponse dto, {
    required int version,
  });

  Future<Result<void>> deleteReferral(String patientId, String referralId);

  // ── ViolationReports ─────────────────────────────────────────────────
  Future<Result<ViolationReportResponse?>> findViolationReportById(
    String patientId,
    String reportId,
  );

  Future<Result<List<ViolationReportResponse>>> listViolationReports(
    String patientId,
  );

  Future<Result<void>> upsertViolationReport(
    String patientId,
    ViolationReportResponse dto, {
    required int version,
  });

  Future<Result<void>> deleteViolationReport(String patientId, String reportId);

  // ── PlacementHistory (one-per-patient) ───────────────────────────────
  Future<Result<PlacementHistoryResponse?>> findPlacementHistory(
    String patientId,
  );

  Future<Result<void>> upsertPlacementHistory(
    String patientId,
    PlacementHistoryResponse dto, {
    required int version,
  });

  Future<Result<void>> deletePlacementHistory(String patientId);

  // ── Cross-cutting ────────────────────────────────────────────────────
  /// Wipe all three protection tables.
  Future<Result<void>> clear();
}
