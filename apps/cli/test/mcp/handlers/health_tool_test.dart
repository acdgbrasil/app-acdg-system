/// W2 RED — `HealthTool.invoke` contract (DESIGN §2.6 + §6).
///
/// Validates the simplest tool: GET /health/ready → Success<Object> wrapping
/// the BFF payload. No auth, no schema args — the smoke test.
///
/// W3 creates `apps/cli/lib/src/mcp/handlers/health_tool.dart`.
library;

import 'package:cli/src/mcp/handlers/health_tool.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import '../testing/fake_bff_client.dart';

void main() {
  group('HealthTool.invoke', () {
    test('returns Success on BFF 200 — payload propagated as Object', () async {
      final bff = buildFakeBffClient(
        body: '{"status":"ok","version":"v1.0.0"}',
        status: 200,
      );
      final tool = HealthTool(bffClient: bff.client);

      final result = await tool.invoke(const <String, Object?>{});

      // P5 §H6 — `as Success<Object>` is the canonical fail-fast cast in
      // tests. Defensive switch is anti-idiomatic here.
      expect(result, isA<Success<Object>>());
      expect(bff.adapter.lastOptions!.path, equals('/health/ready'));
      expect(bff.adapter.lastOptions!.method.toUpperCase(), equals('GET'));
    });
  });
}
