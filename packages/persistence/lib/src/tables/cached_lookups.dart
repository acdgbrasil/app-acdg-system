import 'package:drift/drift.dart';

/// Local cache of domain lookup tables (e.g. dominio_parentesco).
///
/// Each row caches the full list of items for one lookup table,
/// serialized as a JSON array.
class CachedLookups extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Domain table name, e.g. "dominio_parentesco".
  TextColumn get lookupName => text().unique()();

  /// JSON array of {id, codigo, descricao} objects.
  TextColumn get itemsJson => text()();

  DateTimeColumn get lastFetchedAt => dateTime()();
}
