import 'package:drift/drift.dart';

/// `ReferralResponse` projection, scoped per patient.
@TableIndex(name: 'referrals_patientId_idx', columns: {#patientId})
class Referrals extends Table {
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  TextColumn get payload => text()();
  DateTimeColumn get cachedAt => dateTime()();
  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {patientId, id};
}

/// `ViolationReportResponse` projection, scoped per patient.
@TableIndex(name: 'violation_reports_patientId_idx', columns: {#patientId})
class ViolationReports extends Table {
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  TextColumn get payload => text()();
  DateTimeColumn get cachedAt => dateTime()();
  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {patientId, id};
}

/// `PlacementHistoryResponse` projection — one-per-patient (not an
/// individual placement registry, but the wrapping history object that
/// owns multiple placements).
class PlacementHistories extends Table {
  TextColumn get patientId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get cachedAt => dateTime()();
  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {patientId};
}
