import 'package:drift/drift.dart';

/// Drift table holding `AppointmentResponse` projections, scoped per
/// patient. PK is composite `(patientId, id)` so the same appointment
/// id under another patient is a different row (cache isolates).
@TableIndex(name: 'appointments_patientId_idx', columns: {#patientId})
class Appointments extends Table {
  TextColumn get patientId => text()();
  TextColumn get id => text()();
  TextColumn get payload => text()();
  DateTimeColumn get cachedAt => dateTime()();
  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {patientId, id};
}
