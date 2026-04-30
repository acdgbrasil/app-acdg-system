import 'package:drift/drift.dart';

/// Drift table holding a per-patient JSON projection of `PatientResponse`.
///
/// One row per patient. The `payload` column stores the full DTO encoded
/// as JSON; indexed columns expose lookup paths used by the cache impl
/// (`findById`, `findByPersonId`, future `status` filtering).
@TableIndex(name: 'patients_personId_idx', columns: {#personId})
@TableIndex(name: 'patients_status_idx', columns: {#status})
class Patients extends Table {
  TextColumn get id => text()();
  TextColumn get personId => text()();
  TextColumn get status => text()();
  TextColumn get payload => text()();
  DateTimeColumn get cachedAt => dateTime()();
  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Drift table mirroring `PatientSummaryResponse` for list views.
///
/// Decoupled from [Patients] (one row per patient does NOT imply one
/// summary — summaries can land before the full DTO and vice versa).
/// The `payload` column stores the full summary DTO; `firstName`,
/// `lastName`, `primaryDiagnosis` are duplicated as columns to make
/// FTS5 trigger derivation deterministic and keep the search index
/// small.
@TableIndex(name: 'patient_summaries_status_idx', columns: {#status})
class PatientSummaries extends Table {
  TextColumn get patientId => text()();
  TextColumn get personId => text()();
  TextColumn get firstName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  TextColumn get primaryDiagnosis => text().nullable()();
  TextColumn get status => text()();
  TextColumn get payload => text()();
  DateTimeColumn get cachedAt => dateTime()();
  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {patientId};
}
