import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:persistence/persistence.dart';

/// Service responsible for managing the Isar database instance.
class IsarService {
  Isar? _isar;

  /// Returns whether the database is currently open.
  bool get isOpen => _isar != null;

  /// Returns the current Isar instance.
  /// Throws an exception if the database has not been initialized.
  Isar get db {
    if (_isar == null) {
      throw Exception(
        'Isar database has not been initialized. Call init() first.',
      );
    }
    return _isar!;
  }

  /// Initializes the Isar database.
  /// On Web, it uses the default configuration (IndexedDB).
  /// On Desktop/Mobile, it uses the application documents directory if [directory] is not provided.
  Future<void> init({String? directory}) async {
    if (_isar != null) return;

    String? path = directory;
    if (path == null && !kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      path = dir.path;
    }

    _isar = await Isar.open(
      IsarSchemas.all,
      directory: path ?? '',
      name: 'acdg_offline_db',
    );
  }

  /// Closes the Isar database instance.
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
