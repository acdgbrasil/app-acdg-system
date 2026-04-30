import 'package:drift/drift.dart';

/// Drift table holding `LookupItemResponse` projections, scoped per
/// lookup table name. Composite PK `(lookupName, id)` isolates items.
///
/// `lookupName` mirrors the DTO's `tableName` field but is renamed in
/// the Drift schema to avoid colliding with Drift's `Table.tableName`
/// SQL-name getter. The cache impl handles the rename transparently
/// — callers always speak in DTO terms (`tableName`).
@TableIndex(name: 'lookup_items_lookupName_idx', columns: {#lookupName})
class LookupItems extends Table {
  TextColumn get lookupName => text()();
  TextColumn get id => text()();
  TextColumn get payload => text()();
  DateTimeColumn get cachedAt => dateTime()();
  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {lookupName, id};
}

/// Drift table holding `LookupRequestResponse` projections (governance
/// approval workflow).
@TableIndex(name: 'lookup_requests_lookupName_idx', columns: {#lookupName})
@TableIndex(name: 'lookup_requests_status_idx', columns: {#status})
class LookupRequests extends Table {
  TextColumn get id => text()();
  TextColumn get lookupName => text()();
  TextColumn get status => text()();
  TextColumn get payload => text()();
  DateTimeColumn get cachedAt => dateTime()();
  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
