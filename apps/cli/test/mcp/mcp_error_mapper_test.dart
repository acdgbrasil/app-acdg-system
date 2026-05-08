/// W2 RED — `McpErrorMapper.toAdapterError` switch contract.
///
/// Validates DESIGN §2.7: the mapper has TWO branches:
///   * Known categorisable errors → typed [McpAdapterError] subtype
///     (`StateError` mentioning stdio/peer-closed → [McpTransportError];
///      `FormatException` → [McpProtocolError]).
///   * Anything else → fallback [McpProtocolError] carrying the runtime
///     type name.
///
/// W3 (impl-agent) creates `apps/cli/lib/src/mcp/mcp_error_mapper.dart`.
/// Until then the import is unresolved (expected RED).
library;

import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/mcp/mcp_error_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('McpErrorMapper.toAdapterError', () {
    test(
      'switches over known error types — stdio StateError → McpTransportError, '
      'FormatException → McpProtocolError',
      () {
        final transport = McpErrorMapper.toAdapterError(
          StateError('peer closed the stdio channel'),
        );
        expect(transport, isA<McpTransportError>());

        final protocol = McpErrorMapper.toAdapterError(
          const FormatException('bad JSON-RPC frame'),
        );
        expect(protocol, isA<McpProtocolError>());
      },
    );

    test('falls back to McpProtocolError for unrecognised exception types', () {
      // Anything that does not match the explicit switch arms (DESIGN
      // §2.7) must land on the `_` arm → `McpProtocolError` with
      // runtimeType in the message. Using a one-off sentinel exception
      // type guarantees we hit the fallback regardless of how the
      // mapper evolves its known-arms set.
      final mapped = McpErrorMapper.toAdapterError(_SentinelException());

      expect(mapped, isA<McpProtocolError>());
      expect(mapped.message, contains('_SentinelException'));
    });
  });
}

/// Distinct, non-builtin exception type so the test cannot accidentally
/// match a future arm the mapper might add for `Exception` or `Error`.
final class _SentinelException implements Exception {
  @override
  String toString() => '_SentinelException';
}
