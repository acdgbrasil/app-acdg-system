/// W2 RED — `AuthStatusTool.invoke` contract (DESIGN §2.6).
///
/// AuthStatusTool reads the local CredentialStore and returns the
/// authentication snapshot. With no session present, the response shape
/// is `{ authenticated: false }` and NO BFF call is issued.
///
/// W3 creates `apps/cli/lib/src/mcp/handlers/auth_status_tool.dart`.
library;

import 'package:cli/src/mcp/handlers/auth_status_tool.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import '../testing/fake_credential_store.dart';

void main() {
  group('AuthStatusTool.invoke', () {
    test(
      'returns { authenticated: false } when CredentialStore yields null',
      () async {
        final store = FakeCredentialStore();
        final tool = AuthStatusTool(credentialStore: store);

        final result = await tool.invoke(const <String, Object?>{});

        // Cast-and-fail — P5 §H6 idiom.
        final payload =
            (result as Success<Object>).value as Map<String, Object?>;
        expect(payload['authenticated'], equals(false));
      },
    );
  });
}
