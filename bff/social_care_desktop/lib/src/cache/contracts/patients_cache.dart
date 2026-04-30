import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../_shared/cached.dart';

/// Desktop-only Read Model for the Patient aggregate (with embedded
/// Assessment fichas) plus the lighter `PatientSummaryResponse` rows
/// used in list views.
///
/// Implementations are pure persistence — no business logic, no
/// orchestration of remote calls. Mutations of domain go through the
/// SyncQueue (A18-v2), which writes to this cache after a remote
/// success. Missing rows are `Success(null)`, never `Failure`.
///
/// `findById` and `findByPersonId` return a [Cached] envelope so
/// orchestrating use cases (A18b-v2) can read `cachedAt` (staleness
/// check) and `version` (optimistic-locking on writes) without a
/// second round-trip.
abstract interface class PatientsCache {
  /// Returns the cached `PatientResponse` (wrapped in [Cached]) for
  /// [patientId], or `Success(null)` when no row exists.
  Future<Result<Cached<PatientResponse>?>> findById(String patientId);

  /// Returns the cached patient whose `personId` matches (wrapped in
  /// [Cached]), or `Success(null)`. Backed by a B-Tree index —
  /// O(log N).
  Future<Result<Cached<PatientResponse>?>> findByPersonId(String personId);

  /// Lists `PatientSummaryResponse` rows. Filters use B-Tree indices.
  Future<Result<List<PatientSummaryResponse>>> listSummaries({
    String? status,
    String? cursor,
    int? limit,
  });

  /// FTS5 search over `firstName`, `lastName`, `primaryDiagnosis`.
  /// Prefix matches (`Mari*`) are supported when [term] omits a
  /// trailing wildcard (the impl appends one to enable typeahead UX).
  Future<Result<List<PatientSummaryResponse>>> searchSummaries(String term);

  /// Upsert the full patient DTO. `version` is caller-controlled and
  /// stored verbatim — A18-v2's SyncEngine owns increment via the
  /// optimistic-locking remote write.
  Future<Result<void>> upsertPatient(
    PatientResponse dto, {
    required int version,
  });

  /// Upsert the lighter summary DTO used in list views.
  Future<Result<void>> upsertSummary(
    PatientSummaryResponse dto, {
    required int version,
  });

  /// Delete the patient row. No-op (`Success`) if the row is missing.
  Future<Result<void>> deletePatient(String patientId);

  /// Delete the summary row. No-op (`Success`) if the row is missing.
  Future<Result<void>> deleteSummary(String patientId);

  /// Wipe both tables (`patients` + `patient_summaries`).
  Future<Result<void>> clear();
}
