/// W2 RED — `PatientGetTool.invoke` envelope-extraction contract.
///
/// Validates DESIGN §2.6 line 532-535: the BFF wraps the patient document
/// inside a `{ "data": ... }` envelope. The handler must surface only the
/// inner `data` payload to the AI host.
///
/// W3 creates `apps/cli/lib/src/mcp/handlers/patient_get_tool.dart`.
library;

import 'package:cli/src/mcp/handlers/patient_get_tool.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import '../testing/fake_bff_client.dart';

const String _kFakePatientId = 'patient-FAKE-1234';

void main() {
  group('PatientGetTool.invoke', () {
    test(
      'extracts the `data` envelope and returns it as the Success value',
      () async {
        final bff = buildFakeBffClient(
          body:
              '{"data":{"id":"$_kFakePatientId","name":"Fake Patient"},'
              '"meta":{"timestamp":"2026-05-07T00:00:00Z"}}',
          status: 200,
        );
        final tool = PatientGetTool(bffClient: bff.client);

        final result = await tool.invoke(const {'patientId': _kFakePatientId});

        // P5 §H6 — fail-fast cast.
        final value = (result as Success<Object>).value as Map<String, Object?>;
        // The AI host must see the patient document, NOT the envelope.
        expect(value['id'], equals(_kFakePatientId));
        expect(
          value.containsKey('meta'),
          isFalse,
          reason: 'meta envelope must be stripped before reaching the host',
        );
        expect(
          bff.adapter.lastOptions!.path,
          equals('/patients/$_kFakePatientId'),
        );
      },
    );
  });
}
