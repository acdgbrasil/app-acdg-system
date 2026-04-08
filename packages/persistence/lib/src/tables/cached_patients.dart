import 'package:drift/drift.dart';

/// Local cache of patient records from the backend.
///
/// Stores the full patient JSON blob for offline access,
/// along with indexed fields for efficient lookups.
///
/// CPF uniqueness is enforced at the repository layer via
/// a query-before-insert check. A DB-level partial unique index
/// is not used because Drift's build_runner generates the schema
/// and SQLite partial indexes require raw SQL migrations.
class CachedPatients extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get patientId => text().unique()();

  TextColumn get personId => text()();

  TextColumn get firstName => text().withDefault(const Constant(''))();

  TextColumn get lastName => text().withDefault(const Constant(''))();

  /// CPF — empty string when not provided. Uniqueness enforced
  /// at repository layer (query-before-insert) to allow multiple
  /// patients without CPF.
  TextColumn get cpf => text().withDefault(const Constant(''))();

  /// Complete patient aggregate serialized as JSON.
  TextColumn get fullRecordJson => text()();

  /// Server version for optimistic concurrency control.
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Whether this record has local modifications pending sync.
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

  DateTimeColumn get lastSyncAt => dateTime()();
}
