import 'package:drift/drift.dart';

import '../_shared/cache_database.dart';
import '../_shared/tables/patients_table.dart';
import '../_shared/tables/patients_table.drift.dart';
import 'patient_dao.drift.dart';

/// DAO for the [Patients] and [PatientSummaries] tables.
///
/// Hosts every Drift call used by the cache impl — keeping the impl
/// itself a thin `Result` wrapper. Raw exceptions surface here; the
/// impl converts them at the boundary.
@DriftAccessor(tables: [Patients, PatientSummaries])
class PatientDao extends DatabaseAccessor<CacheDatabase> with $PatientDaoMixin {
  PatientDao(super.db);

  // ── Patients ─────────────────────────────────────────────────────────
  Future<Patient?> findPatientById(String patientId) async {
    return (select(
      patients,
    )..where((p) => p.id.equals(patientId))).getSingleOrNull();
  }

  Future<Patient?> findPatientByPersonId(String personId) async {
    return (select(
      patients,
    )..where((p) => p.personId.equals(personId))).getSingleOrNull();
  }

  Future<void> upsertPatient({
    required String id,
    required String personId,
    required String status,
    required String payload,
    required DateTime cachedAt,
    required int version,
  }) {
    return into(patients).insert(
      PatientsCompanion.insert(
        id: id,
        personId: personId,
        status: status,
        payload: payload,
        cachedAt: cachedAt,
        version: version,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deletePatientById(String patientId) async {
    await (delete(patients)..where((p) => p.id.equals(patientId))).go();
  }

  Future<void> clearPatients() => delete(patients).go();

  // ── PatientSummaries ─────────────────────────────────────────────────
  Future<List<PatientSummary>> listSummaries({String? status, int? limit}) {
    final q = select(patientSummaries);
    if (status != null) {
      q.where((s) => s.status.equals(status));
    }
    if (limit != null) {
      q.limit(limit);
    }
    return q.get();
  }

  /// FTS5 search via the `patient_summaries_fts` virtual table. The
  /// caller's `term` is sanitized (single-quote stripped) and a
  /// trailing `*` is appended for prefix-match typeahead UX.
  Future<List<PatientSummary>> searchSummaries(String term) async {
    final sanitized = term.replaceAll("'", '').trim();
    if (sanitized.isEmpty) {
      return const [];
    }
    final result = await customSelect(
      'SELECT s.* FROM patient_summaries s '
      'WHERE s.rowid IN ('
      '  SELECT rowid FROM patient_summaries_fts '
      "  WHERE patient_summaries_fts MATCH '${sanitized.toLowerCase()}*'"
      ')',
      readsFrom: {patientSummaries},
    ).get();
    return result.map((row) => patientSummaries.map(row.data)).toList();
  }

  Future<void> upsertSummary({
    required String patientId,
    required String personId,
    String? firstName,
    String? lastName,
    String? primaryDiagnosis,
    required String status,
    required String payload,
    required DateTime cachedAt,
    required int version,
  }) {
    return into(patientSummaries).insert(
      PatientSummariesCompanion.insert(
        patientId: patientId,
        personId: personId,
        firstName: Value(firstName),
        lastName: Value(lastName),
        primaryDiagnosis: Value(primaryDiagnosis),
        status: status,
        payload: payload,
        cachedAt: cachedAt,
        version: version,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteSummaryById(String patientId) async {
    await (delete(
      patientSummaries,
    )..where((s) => s.patientId.equals(patientId))).go();
  }

  Future<void> clearSummaries() => delete(patientSummaries).go();
}
