/// Helper to spin up an in-memory `CacheDatabase` per cache test (A17-v2).
///
/// Using `NativeDatabase.memory()` avoids file I/O — every test gets a
/// pristine, isolated database. Each `setUp` calls [newInMemoryDatabase];
/// each `tearDown` calls `close()` on the returned instance.
///
/// IMPORTANT (RED phase): the `CacheDatabase` class does NOT exist yet.
/// W1 (flutter-bff-implementer) is expected to create it at
/// `lib/src/cache/_shared/cache_database.dart` with a `@DriftDatabase`
/// annotation, plus run `dart run build_runner build` to generate
/// `cache_database.g.dart`. Until then, the `import` below will fail —
/// that is the intended RED signal.
///
/// FTS5 note: production code uses `sqlite3_flutter_libs` to ship a
/// SQLite build with FTS5 enabled. Tests rely on the host `sqlite3`
/// binary already including FTS5 (which is the default on macOS/Linux
/// for the `sqlite3` Dart package's bundled binary). If the implementer
/// finds host SQLite lacks FTS5, they must wire `sqlite3` (dev_dep)
/// to load the bundled binary in tests too.
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/cache/_shared/cache_database.dart';

/// Returns a fresh in-memory [CacheDatabase].
///
/// [logStatements] forwards to [NativeDatabase] for debugging — leave at
/// `false` in CI; flip to `true` locally to dump every SQL statement.
CacheDatabase newInMemoryDatabase({bool logStatements = false}) {
  return CacheDatabase(NativeDatabase.memory(logStatements: logStatements));
}

/// Convenience: closes the underlying [QueryExecutor] without bubbling
/// up exceptions if the DB was already closed (idempotent for tearDown).
Future<void> safeClose(CacheDatabase db) async {
  try {
    await db.close();
  } catch (_) {
    // already closed — fine.
  }
}
