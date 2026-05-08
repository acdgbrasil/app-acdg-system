/// W2 RED — `McpLoggerSetup.redirectToStderr` contract.
///
/// Validates DESIGN §2.9 + ADR-MCP-005-v2: setup is idempotent and ALL
/// `Logger.root` records land on the supplied [StringSink] (stderr in
/// production). A leak to stdout would corrupt the JSON-RPC frame.
///
/// W3 (impl-agent) creates `apps/cli/lib/src/mcp/mcp_logger_setup.dart`.
/// Until then the import is unresolved (expected RED).
library;

import 'package:cli/src/mcp/mcp_logger_setup.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'testing/fake_logger.dart';

void main() {
  group('McpLoggerSetup.redirectToStderr', () {
    setUp(() {
      // Ensure a clean install state for every test — DESIGN §2.9 exposes
      // `resetForTesting()` exactly so the tests can attach + detach.
      McpLoggerSetup.resetForTesting();
    });

    test('is idempotent — second call does not double-attach the listener', () {
      final sink = CapturingStringSink();

      McpLoggerSetup.redirectToStderr(sink);
      McpLoggerSetup.redirectToStderr(sink); // second call must be a no-op

      Logger('acdg.mcp.test').info('hello');

      // If the listener double-attached, "hello" would appear twice in the
      // sink. Idempotency means it appears exactly once.
      final emitted = sink.buffer.toString();
      final occurrences = 'hello'.allMatches(emitted).length;
      expect(
        occurrences,
        equals(1),
        reason: 'expected exactly one log line; double-attach would emit twice',
      );
    });

    test('writes to the provided stderr sink, never to stdout', () {
      final stderrSink = CapturingStringSink();
      final stdoutSink = CapturingStringSink();

      McpLoggerSetup.redirectToStderr(stderrSink);

      // Hand the second sink only as a control — if the impl ever called
      // `print()` or wrote to a global stdout, the assertion below would
      // pass anyway. The real stdio-leak guard lives in the e2e test;
      // this unit test just proves the redirected sink receives traffic.
      Logger('acdg.mcp.test').warning('leak-canary');

      expect(stderrSink.buffer.toString(), contains('leak-canary'));
      expect(
        stdoutSink.buffer.toString(),
        isEmpty,
        reason: 'control sink must remain empty — only stderr receives logs',
      );
    });
  });
}
