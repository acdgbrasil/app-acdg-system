/// RED-phase tests for `DriftExecutorFactory` (D01 W0.5).
///
/// `DriftExecutorFactory` is a Factory Method abstraction that encapsulates
/// the `:memory:` vs disk decision currently buried in
/// `_openDriftExecutor` inside `social_care_desktop.dart` (line 705). D01
/// extracts it to `lib/src/facade/composition/db_executor.dart` so the
/// facade no longer owns the construction strategy — composition root
/// hands it in (default `production`, tests pass `inMemory`).
///
/// `defaultDesktopFilePath` is a tiny helper that resolves a file under
/// `path_provider`'s `getApplicationDocumentsDirectory()`. Currently lives
/// at line 684 as `_defaultPath`; D01 promotes it to a free top-level
/// function in the same file.
///
/// ── Surface under test ────────────────────────────────────────────────
///   * `abstract interface class DriftExecutorFactory`
///       - `QueryExecutor open(String filePath)`
///       - `static const DriftExecutorFactory production`
///       - `static const DriftExecutorFactory inMemory`
///   * `Future<String> defaultDesktopFilePath(String fileName)`
///
/// ── Contract notes ────────────────────────────────────────────────────
///   * The `production` factory MUST recognise `':memory:'` as the
///     in-memory marker (preserves the contract documented at facade
///     line 23-24, where `cacheFilePath: ':memory:'` already forces an
///     in-memory database). The 000-request.md (D01 spec) explicitly
///     calls this edge case out — `_ProductionFactory.open(':memory:')`
///     delegates to `_InMemoryFactory.open()`.
///   * The `inMemory` factory IGNORES the file path entirely — every
///     call yields a transient `NativeDatabase.memory()`. We assert no
///     file is created on disk even when a real path is passed.
///   * Both factories are documented as `const` singletons in the spec —
///     identity assertion pins that intent.
///
/// ── REGRA #2: defaultDesktopFilePath ──────────────────────────────────
/// The helper depends on `path_provider`, which is a Flutter plugin. In
/// pure-Dart `test` runs (no Flutter plugin host), the call throws
/// `MissingPluginException`. Tests #10–11 assert that exception — same
/// pattern used elsewhere when path_provider is unmocked. If W1 wants
/// to keep the helper Flutter-only, that's fine; if W1 chooses a
/// Flutter-independent default (e.g. `Directory.systemTemp`), it MUST
/// surface that change in the implementation report so the assertion
/// here is updated deliberately, not silently.
///
/// IMPORTANT (RED phase): the import below resolves to a file that does
/// NOT exist yet — `lib/src/facade/composition/db_executor.dart` is W1's
/// output. Until then, this file fails to analyze. That is the intended
/// RED signal.
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/facade/composition/db_executor.dart';

/// Custom test impl — proves the abstract interface is implementable
/// from outside the file (i.e. `abstract interface class`, not
/// `abstract class`/`base class`/`final class` — covered by test #9).
class _StubFactory implements DriftExecutorFactory {
  _StubFactory();
  int openCalls = 0;
  String? lastPath;

  @override
  QueryExecutor open(String filePath) {
    openCalls++;
    lastPath = filePath;
    return NativeDatabase.memory();
  }
}

/// Minimal `GeneratedDatabase` shim used by the disk-backed tests below.
///
/// REGRA #2 exception (fixture invalid): the original tests #5–#6
/// called `executor.runCustom(...)` directly on the [LazyDatabase]
/// returned by [NativeDatabase.createInBackground]. `LazyDatabase`'s
/// internal `_delegate` is initialized only when a [GeneratedDatabase]
/// triggers `ensureOpen()` — calling `runCustom` raw skips the handshake
/// and surfaces `LateInitializationError` (proved empirically:
/// `LazyDatabase._delegate@... has not been initialized.`).
///
/// This shim provides the tiniest possible [GeneratedDatabase] (no
/// tables, schemaVersion 1) so the test can exercise the executor via
/// `customStatement` / `customSelect` and trigger `ensureOpen()`. The
/// shim does NOT alter the test intent — we still validate that
/// `DriftExecutorFactory.production.open(real path)` produces a working
/// disk-backed executor that round-trips data and materialises a file.
class _ProbeDb extends GeneratedDatabase {
  _ProbeDb(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  int get schemaVersion => 1;
}

void main() {
  group('DriftExecutorFactory', () {
    group('inMemory factory', () {
      test('open(any path) returns a QueryExecutor', () {
        final executor = DriftExecutorFactory.inMemory.open('/some/random/path');
        expect(executor, isA<QueryExecutor>());
      });

      test('open(":memory:") returns a QueryExecutor', () {
        final executor = DriftExecutorFactory.inMemory.open(':memory:');
        expect(executor, isA<QueryExecutor>());
      });

      test(
        'open(any path) does NOT create a file on disk — fully transient',
        () {
          final tmpDir = Directory.systemTemp.createTempSync('d01_inmem_');
          addTearDown(() {
            try {
              tmpDir.deleteSync(recursive: true);
            } catch (_) {}
          });

          final phantomPath = '${tmpDir.path}/should_not_exist.sqlite';
          // Open and immediately discard — we don't care about the executor,
          // only that no file appears on disk.
          DriftExecutorFactory.inMemory.open(phantomPath);

          expect(
            File(phantomPath).existsSync(),
            isFalse,
            reason:
                'inMemory factory ignores filePath; no .sqlite must materialize',
          );
        },
      );
    });

    group('production factory', () {
      test(
        'open(":memory:") returns a memory-backed executor (preserves marker)',
        () async {
          final tmpDir = Directory.systemTemp.createTempSync('d01_prod_mem_');
          addTearDown(() {
            try {
              tmpDir.deleteSync(recursive: true);
            } catch (_) {}
          });

          // Even though we pass a tmp directory path we ALSO want to verify
          // the literal `:memory:` marker takes the in-memory branch — no
          // .sqlite should appear at the cwd or any other location.
          final executor = DriftExecutorFactory.production.open(':memory:');
          expect(executor, isA<QueryExecutor>());

          // The marker contract is observable: a memory-backed executor
          // never touches the filesystem. We probe by listing the tmp dir
          // (which is fresh and empty); after creating an executor with
          // `:memory:`, the dir must still be empty.
          expect(
            tmpDir.listSync(),
            isEmpty,
            reason:
                'production factory MUST honor the `:memory:` marker by '
                'delegating to the in-memory branch (per D01 spec edge case)',
          );
        },
      );

      test(
        'open(real disk path) opens a file-backed executor that round-trips '
        'through the filesystem',
        () async {
          // REGRA #2 exception (fixture invalid): the original assertion
          // exercised the [LazyDatabase] returned by
          // [NativeDatabase.createInBackground] via raw `runCustom`, which
          // skips the `ensureOpen()` handshake that initialises
          // `LazyDatabase._delegate`. We route through the [_ProbeDb]
          // [GeneratedDatabase] shim (mirrors how production wires through
          // [CacheDatabase] — see file_backed_db_test.dart for the
          // production wrapper). Intent preserved: we still validate that
          // `production.open(real disk path)` round-trips data through the
          // filesystem.
          final tmpDir = Directory.systemTemp.createTempSync('d01_prod_disk_');
          addTearDown(() {
            try {
              tmpDir.deleteSync(recursive: true);
            } catch (_) {}
          });

          final dbPath = '${tmpDir.path}/round_trip.sqlite';

          // Open the file-backed executor wrapped in the probe DB, run a
          // tiny DDL + DML, then close.
          final db = _ProbeDb(DriftExecutorFactory.production.open(dbPath));
          await db
              .customStatement(
                'CREATE TABLE IF NOT EXISTS probe (k TEXT PRIMARY KEY, v INT)',
              )
              .timeout(const Duration(seconds: 10));
          await db
              .customStatement("INSERT INTO probe (k, v) VALUES ('answer', 42)")
              .timeout(const Duration(seconds: 5));
          await db.close();

          // Re-open the SAME file with a fresh executor and read the row
          // back. If the production factory were not file-backed, the row
          // would be gone — proving end-to-end disk persistence.
          final db2 = _ProbeDb(DriftExecutorFactory.production.open(dbPath));
          final rows = await db2
              .customSelect(
                'SELECT v FROM probe WHERE k = ?',
                variables: [Variable<String>('answer')],
              )
              .get()
              .timeout(const Duration(seconds: 5));
          await db2.close();

          expect(rows, hasLength(1));
          expect(rows.first.read<int>('v'), 42);
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );

      test(
        'open(real disk path) materializes a file at the given path',
        () async {
          // REGRA #2 exception (fixture invalid): same root cause as the
          // round-trip test above — raw `runCustom` on the [LazyDatabase]
          // skips the `ensureOpen()` handshake. Routed through the
          // [_ProbeDb] [GeneratedDatabase] shim instead. Intent preserved:
          // we still validate that the production factory creates a file
          // at the requested path on disk.
          final tmpDir = Directory.systemTemp.createTempSync('d01_prod_file_');
          addTearDown(() {
            try {
              tmpDir.deleteSync(recursive: true);
            } catch (_) {}
          });

          final dbPath = '${tmpDir.path}/materialize.sqlite';
          final db = _ProbeDb(DriftExecutorFactory.production.open(dbPath));

          // Drift creates the file lazily on first query — force one
          // through the shim so the `ensureOpen()` handshake fires.
          await db
              .customStatement('CREATE TABLE IF NOT EXISTS x (k TEXT PRIMARY KEY)')
              .timeout(const Duration(seconds: 10));
          await db.close();

          expect(
            File(dbPath).existsSync(),
            isTrue,
            reason: 'production factory MUST persist to the requested path',
          );
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    });

    group('factory contract', () {
      test('production is a const singleton (identity stable across reads)', () {
        final a = DriftExecutorFactory.production;
        final b = DriftExecutorFactory.production;
        expect(
          identical(a, b),
          isTrue,
          reason: 'spec declares `static const DriftExecutorFactory production`',
        );
      });

      test('inMemory is a const singleton (identity stable across reads)', () {
        final a = DriftExecutorFactory.inMemory;
        final b = DriftExecutorFactory.inMemory;
        expect(
          identical(a, b),
          isTrue,
          reason: 'spec declares `static const DriftExecutorFactory inMemory`',
        );
      });

      test(
        'is implementable from outside the file (abstract interface class)',
        () {
          final stub = _StubFactory();
          expect(stub, isA<DriftExecutorFactory>());

          final executor = stub.open('/whatever/path.sqlite');
          expect(executor, isA<QueryExecutor>());
          expect(stub.openCalls, 1);
          expect(stub.lastPath, '/whatever/path.sqlite');
        },
      );
    });
  });

  group('defaultDesktopFilePath', () {
    test(
      'resolves a path ending with the requested fileName, OR throws a '
      'plugin/binding-related error when path_provider is not bound',
      () async {
        // REGRA #2 exception (fixture invalid): the original assertion
        // caught only `MissingPluginException`, but in `flutter test`
        // runtime the binding raises `FlutterError("Binding has not yet
        // been initialized")` BEFORE the plugin channel is even probed
        // (proved empirically: stack shows `BindingBase.checkInstance` →
        // `ServicesBinding.instance` → `MethodChannel._invokeMethod`).
        // We broaden the catch to `Object` and substring-match the
        // message — same pattern used at
        // social_care_desktop_test.dart:455-505. Intent preserved: the
        // helper either resolves a path under the docs dir, OR fails
        // gracefully because path_provider is unavailable in this
        // runtime — never silently echoes the input.
        try {
          final path = await defaultDesktopFilePath('app_cache.sqlite');
          expect(
            path,
            endsWith('app_cache.sqlite'),
            reason: 'helper must append the requested fileName to the dir',
          );
          expect(path, isNot(equals('app_cache.sqlite')),
              reason: 'helper must prepend a directory, not just echo input');
        } on Object catch (e) {
          // Expected in unit-test runtime — either MissingPluginException
          // (no binding init) or FlutterError ("Binding has not yet been
          // initialized"). Both indicate path_provider is unbound here.
          final msg = e.toString();
          expect(
            msg.contains('plugin') ||
                msg.contains('Binding') ||
                msg.contains('initialized'),
            isTrue,
            reason:
                'Expected plugin/binding-related error in test runtime; got: '
                '$msg',
          );
        }
      },
    );

    test(
      'two calls with the same fileName produce the same path (deterministic), '
      'OR both fail consistently with the same error type',
      () async {
        // REGRA #2 exception (fixture invalid): same root cause as the
        // single-call test above — `flutter test` runtime raises
        // `FlutterError("Binding has not yet been initialized")` rather
        // than `MissingPluginException`. We broaden to `Object` and
        // assert determinism by comparing runtime types of the two
        // failures. Intent preserved: either both calls succeed and
        // yield the same path, or both fail with the same exception type
        // (no partially initialized state bug).
        String? path1;
        String? path2;
        Object? err1;
        Object? err2;

        try {
          path1 = await defaultDesktopFilePath('app_sync_queue.sqlite');
        } on Object catch (e) {
          err1 = e;
        }
        try {
          path2 = await defaultDesktopFilePath('app_sync_queue.sqlite');
        } on Object catch (e) {
          err2 = e;
        }

        if (path1 != null && path2 != null) {
          expect(
            path1,
            equals(path2),
            reason:
                'helper must be deterministic for a given fileName — the docs '
                'directory does not change mid-process',
          );
        } else {
          // Both failed in unit-test runtime — that's also deterministic.
          expect(err1, isNotNull);
          expect(err2, isNotNull);
          expect(
            err1.runtimeType,
            equals(err2.runtimeType),
            reason:
                'Both calls must fail with the same error type — no partially '
                'initialized state bug.',
          );
        }
      },
    );
  });
}
