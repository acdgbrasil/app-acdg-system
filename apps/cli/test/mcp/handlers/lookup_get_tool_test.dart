/// W2 RED — `LookupGetTool.invoke` failure-propagation contract.
///
/// The handler must NOT swallow BFF failures. A 404 response from the BFF
/// surfaces as `Failure(ServerError(404, ...))`, which the registry will
/// later redact at the boundary. The handler's job is to forward.
///
/// W3 creates `apps/cli/lib/src/mcp/handlers/lookup_get_tool.dart`.
library;

import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/mcp/handlers/lookup_get_tool.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import '../testing/fake_bff_client.dart';

const String _kFakeLookupId = 'lookup-FAKE-9999';

void main() {
  group('LookupGetTool.invoke', () {
    test('propagates Failure(ServerError(404)) when BFF returns 404', () async {
      final bff = buildFakeBffClient(
        body: '{"error":"not_found"}',
        status: 404,
      );
      final tool = LookupGetTool(bffClient: bff.client);

      final result = await tool.invoke(const {'lookupId': _kFakeLookupId});

      // P5 §H6 — fail-fast cast at the test boundary.
      final failure = result as Failure<Object>;
      final error = failure.error as ServerError;
      expect(error.statusCode, equals(404));
    });
  });
}
