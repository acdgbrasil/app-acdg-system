/// W2 RED — `PatientListTool` schema validation contract (DESIGN §6).
///
/// The `limit` argument has the constraint `minimum: 1, maximum: 50` —
/// values above 50 must be rejected by the JSON Schema validator at the
/// definition level (NOT inside `invoke`).
///
/// W3 creates `apps/cli/lib/src/mcp/handlers/patient_list_tool.dart`.
library;

import 'package:cli/src/mcp/handlers/patient_list_tool.dart';
import 'package:test/test.dart';

void main() {
  group('PatientListTool — JSON Schema', () {
    test('rejects limit > 50 via schema validation', () {
      // DESIGN §6 — `limit: { minimum: 1, maximum: 50 }`. The static
      // definition's `validateArgs` MUST reject 51 with a non-null
      // (error) string. The handler is never invoked for invalid args.
      final error = PatientListTool.definition.validateArgs(const {
        'limit': 51,
      });

      expect(
        error,
        isNotNull,
        reason: 'limit > 50 must be rejected by the schema',
      );
      // Defensive: the message should at least mention "limit" so an
      // operator (or AI host) can fix the call. Exact wording is left to
      // the impl.
      expect(error!.toLowerCase(), contains('limit'));
    });
  });
}
