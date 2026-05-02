import 'package:drift/drift.dart';

import '../_shared/cache_database.dart';
import '../_shared/tables/protection_tables.dart';
import '../_shared/tables/protection_tables.drift.dart';
import 'protection_dao.drift.dart';

@DriftAccessor(tables: [Referrals, ViolationReports, PlacementHistories])
class ProtectionDao extends DatabaseAccessor<CacheDatabase>
    with $ProtectionDaoMixin {
  ProtectionDao(super.db);

  // ── Referrals ────────────────────────────────────────────────────────
  Future<Referral?> findReferralById(String patientId, String referralId) {
    return (select(referrals)..where(
          (r) => r.patientId.equals(patientId) & r.id.equals(referralId),
        ))
        .getSingleOrNull();
  }

  Future<List<Referral>> listReferrals(String patientId) {
    return (select(
      referrals,
    )..where((r) => r.patientId.equals(patientId))).get();
  }

  Future<void> upsertReferral({
    required String patientId,
    required String id,
    required String payload,
    required DateTime cachedAt,
    required int version,
  }) {
    return into(referrals).insert(
      ReferralsCompanion.insert(
        patientId: patientId,
        id: id,
        payload: payload,
        cachedAt: cachedAt,
        version: version,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteReferral(String patientId, String referralId) async {
    await (delete(referrals)..where(
          (r) => r.patientId.equals(patientId) & r.id.equals(referralId),
        ))
        .go();
  }

  Future<void> clearReferrals() => delete(referrals).go();

  // ── ViolationReports ─────────────────────────────────────────────────
  Future<ViolationReport?> findViolationReportById(
    String patientId,
    String reportId,
  ) {
    return (select(violationReports)
          ..where((v) => v.patientId.equals(patientId) & v.id.equals(reportId)))
        .getSingleOrNull();
  }

  Future<List<ViolationReport>> listViolationReports(String patientId) {
    return (select(
      violationReports,
    )..where((v) => v.patientId.equals(patientId))).get();
  }

  Future<void> upsertViolationReport({
    required String patientId,
    required String id,
    required String payload,
    required DateTime cachedAt,
    required int version,
  }) {
    return into(violationReports).insert(
      ViolationReportsCompanion.insert(
        patientId: patientId,
        id: id,
        payload: payload,
        cachedAt: cachedAt,
        version: version,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteViolationReport(String patientId, String reportId) async {
    await (delete(violationReports)
          ..where((v) => v.patientId.equals(patientId) & v.id.equals(reportId)))
        .go();
  }

  Future<void> clearViolationReports() => delete(violationReports).go();

  // ── PlacementHistory (one-per-patient) ───────────────────────────────
  Future<PlacementHistory?> findPlacementHistory(String patientId) {
    return (select(
      placementHistories,
    )..where((p) => p.patientId.equals(patientId))).getSingleOrNull();
  }

  Future<void> upsertPlacementHistory({
    required String patientId,
    required String payload,
    required DateTime cachedAt,
    required int version,
  }) {
    return into(placementHistories).insert(
      PlacementHistoriesCompanion.insert(
        patientId: patientId,
        payload: payload,
        cachedAt: cachedAt,
        version: version,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deletePlacementHistory(String patientId) async {
    await (delete(
      placementHistories,
    )..where((p) => p.patientId.equals(patientId))).go();
  }

  Future<void> clearPlacementHistories() => delete(placementHistories).go();
}
