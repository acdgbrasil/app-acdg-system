import 'package:drift_flutter/drift_flutter.dart';
import 'package:persistence/persistence.dart';

/// Service responsible for managing the Drift database lifecycle.
///
/// Replaces the former IsarService. Uses [drift_flutter] for
/// platform-aware database initialization (file on Desktop, IndexedDB on Web).
class DriftDatabaseService {
  AcdgDatabase? _db;

  /// Returns whether the database is currently open.
  bool get isOpen => _db != null;

  /// Returns the current database instance.
  ///
  /// Throws if [init] has not been called.
  AcdgDatabase get db {
    final database = _db;
    if (database == null) {
      throw StateError(
        'Drift database has not been initialized. Call init() first.',
      );
    }
    return database;
  }

  /// Initializes the database.
  ///
  /// Uses [driftDatabase] from drift_flutter which automatically
  /// selects the right backend (native SQLite on Desktop, Web Worker on Web).
  Future<void> init() async {
    if (_db != null) return;

    _db = AcdgDatabase(driftDatabase(name: 'acdg_offline_db'));
  }

  /// Initializes the database with a custom [QueryExecutor].
  ///
  /// Used for testing with in-memory databases.
  void initWith(AcdgDatabase database) {
    _db = database;
  }

  /// Removes all cached patients from the database.
  Future<void> clearAllPatients() async {
    await db.delete(db.cachedPatients).go();
  }

  /// Closes the database connection.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
