import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

/// In-memory marker recognised by Drift's `NativeDatabase` factory; used
/// by tests to spin a transient cache/sync DB without touching disk.
const String _inMemoryMarker = ':memory:';

/// Factory Method abstraction (GoF) for opening a Drift [QueryExecutor].
///
/// Encapsulates the `:memory:` vs disk decision that previously lived
/// inline in `social_care_desktop.dart`. The composition root hands an
/// instance of this factory into `SocialCareDesktop.create()`:
///
///   * Production code uses [production] — disk-backed databases via
///     [NativeDatabase.createInBackground], spawning a dedicated isolate
///     per database (see [_ProductionFactory] for the architectural
///     rationale).
///   * Tests pass [inMemory] when they want to bypass disk entirely
///     regardless of the file path.
///
/// Both factories are `const` singletons; identity is stable across
/// reads. Tests can also implement this interface directly to inject
/// custom executors (e.g. an instrumented wrapper) — the surface is
/// `abstract interface class`, so external implementation is allowed.
abstract interface class DriftExecutorFactory {
  /// Opens a [QueryExecutor] for the given file path. Implementations
  /// decide how to map [filePath] to a concrete executor (disk-backed,
  /// memory-backed, instrumented, etc.).
  QueryExecutor open(String filePath);

  /// Production: opens disk-backed databases via
  /// [NativeDatabase.createInBackground], spawning a dedicated isolate
  /// per database. See ADR-021 for rationale on Drift's first-class
  /// multi-isolate support over Isar.
  ///
  /// Honors the legacy `:memory:` marker — when [open] receives the
  /// literal `':memory:'` string, it delegates to [inMemory] so existing
  /// callers (including tests that pass `cacheFilePath: ':memory:'`
  /// directly) keep working unchanged.
  static const DriftExecutorFactory production = _ProductionFactory();

  /// In-memory: opens transient databases via [NativeDatabase.memory]
  /// regardless of the [filePath] argument. Used by tests; in-memory
  /// databases stay on the calling isolate by design (Drift has no
  /// `createInBackground` for memory-backed databases) and tests rely
  /// on synchronous in-isolate state.
  static const DriftExecutorFactory inMemory = _InMemoryFactory();
}

/// Production factory — disk-backed via background isolate.
///
/// **T1.1 (2026-05-01):** disk-backed databases are opened via
/// [NativeDatabase.createInBackground], which spawns a dedicated
/// background isolate that owns the SQLite handle. The main isolate
/// then communicates with it via `SendPort` — every Drift query runs
/// off the UI/event-loop thread.
///
/// Honors ADR-021's cited rationale (Drift's first-class multi-isolate
/// support) which previously was paid-for-but-unused in production.
///
/// **`:memory:` marker preservation:** the literal `':memory:'`
/// (canonical SQLite in-memory marker) yields [NativeDatabase.memory]
/// for tests; any other string is treated as a real disk path. This
/// preserves backward-compat with callers that pass `cacheFilePath:
/// ':memory:'` directly. In-memory databases stay on the calling
/// isolate by design — Drift has no `createInBackground` for
/// `NativeDatabase.memory()` and tests rely on synchronous in-isolate
/// state.
class _ProductionFactory implements DriftExecutorFactory {
  const _ProductionFactory();

  @override
  QueryExecutor open(String filePath) {
    if (filePath == _inMemoryMarker) {
      return DriftExecutorFactory.inMemory.open(filePath);
    }
    return NativeDatabase.createInBackground(File(filePath));
  }
}

/// In-memory factory — transient executor regardless of [filePath].
///
/// Drift has no `createInBackground` for memory-backed databases, so
/// the executor stays on the calling isolate. Tests rely on this
/// in-isolate behavior for synchronous state observation.
class _InMemoryFactory implements DriftExecutorFactory {
  const _InMemoryFactory();

  @override
  QueryExecutor open(String filePath) => NativeDatabase.memory();
}

/// Resolves the default file path under `path_provider`'s
/// [getApplicationDocumentsDirectory]. Tests that omit
/// `cacheFilePath` / `syncQueueFilePath` fall through here, which
/// throws `MissingPluginException` in unit tests (intentional — the
/// path_provider plugin channel is unwired in pure-Dart `test` runs).
///
/// Tests that rely on the in-memory factory bypass this entirely (they
/// pass `':memory:'` directly or inject [DriftExecutorFactory.inMemory]).
Future<String> defaultDesktopFilePath(String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/$fileName';
}
