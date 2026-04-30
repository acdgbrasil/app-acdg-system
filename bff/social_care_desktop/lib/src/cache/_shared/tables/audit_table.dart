import 'package:drift/drift.dart';

/// Drift table holding `AuditTrailEntryResponse` projections.
///
/// `patientId` is the cache scope (== aggregateId for registry-level
/// audits). The full DTO including `aggregateId` is round-tripped via
/// `payload`; `eventType` is a duplicated column to support efficient
/// B-Tree filtering in `listByPatient(... eventType: ...)`.
@TableIndex(name: 'audit_entries_patientId_idx', columns: {#patientId})
@TableIndex(name: 'audit_entries_eventType_idx', columns: {#eventType})
class AuditEntries extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get eventType => text()();
  TextColumn get payload => text()();
  DateTimeColumn get cachedAt => dateTime()();
  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
