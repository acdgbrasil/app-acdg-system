/// W2 RED — `McpServerAdapter` lifecycle contract.
///
/// Validates DESIGN §2.3 boundary: adapter owns the dart_mcp server, exposes
/// `start()` (idempotent guard), `done` (completes on peer close), and
/// `shutdown()` (graceful, idempotent). The adapter must NEVER let dart_mcp
/// types escape — only `McpServerAdapter` imports `package:dart_mcp/...`.
///
/// W3 (impl-agent) creates `apps/cli/lib/src/mcp/mcp_server_adapter.dart`.
/// Until then these imports are unresolved (expected RED).
library;

import 'dart:async';
import 'dart:io';

import 'package:cli/src/mcp/mcp_server_adapter.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'testing/fake_bff_client.dart';
import 'testing/fake_credential_store.dart';
import 'testing/fake_logger.dart';

void main() {
  group('McpServerAdapter — lifecycle', () {
    test(
      'start() connects via injected stdin/stdout (logs "connected")',
      () async {
        final bff = buildFakeBffClient();
        final fakeLogger = FakeLogger();
        addTearDown(fakeLogger.dispose);

        final adapter = McpServerAdapter(
          bffClient: bff.client,
          credentialStore: FakeCredentialStore(),
          logger: Logger('acdg.mcp.test'),
          stdinOverride: const Stream<List<int>>.empty(),
          stdoutOverride: nullIoSink(),
        );

        await adapter.start();

        // DESIGN §2.3 line 244 — `start()` emits an info log on success.
        // Asserting the log proves the adapter wired the channel without
        // touching real `io.stdin` / `io.stdout` (which would fail in the
        // test isolate where stdio is redirected).
        expect(
          fakeLogger.records.any(
            (r) => r.message.toLowerCase().contains('connected'),
          ),
          isTrue,
          reason: 'expected adapter to emit a "connected" info log',
        );

        await adapter.shutdown();
      },
    );

    test(
      'start() is idempotent guarded — second call throws StateError',
      () async {
        final bff = buildFakeBffClient();
        final adapter = McpServerAdapter(
          bffClient: bff.client,
          credentialStore: FakeCredentialStore(),
          logger: Logger('acdg.mcp.test'),
          stdinOverride: const Stream<List<int>>.empty(),
          stdoutOverride: nullIoSink(),
        );

        await adapter.start();

        expect(adapter.start, throwsA(isA<StateError>()));

        await adapter.shutdown();
      },
    );

    test('shutdown() completes the `done` future', () async {
      final bff = buildFakeBffClient();
      final adapter = McpServerAdapter(
        bffClient: bff.client,
        credentialStore: FakeCredentialStore(),
        logger: Logger('acdg.mcp.test'),
        stdinOverride: const Stream<List<int>>.empty(),
        stdoutOverride: nullIoSink(),
      );

      await adapter.start();
      await adapter.shutdown();

      // `done` must complete after a clean shutdown — bounded wait so a
      // regression cannot hang CI indefinitely.
      await expectLater(
        adapter.done.timeout(const Duration(seconds: 2)),
        completes,
      );
    });
  });
}

/// Minimal [IOSink] for the adapter's stdout slot. Dart's [IOSink] is a
/// concrete class wrapping a `StreamSink<List<int>>`; we get a working
/// no-op instance by piping to a [StreamController] and immediately
/// discarding everything written.
IOSink nullIoSink() {
  final controller = StreamController<List<int>>();
  controller.stream.drain<void>();
  return IOSink(controller.sink);
}
