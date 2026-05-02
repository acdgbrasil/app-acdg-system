import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAuthBff', () {
    test('implements AuthContract', () {
      final AuthContract fake = FakeAuthBff();
      expect(fake, isA<AuthContract>());
    });

    test('login: returns Success with a redirect URL', () async {
      final fake = FakeAuthBff();

      final result = await fake.login();

      expect(result, isA<Success<String>>());
      switch (result) {
        case Success(:final value):
          expect(value, isNotEmpty);
        case Failure():
          fail('login should succeed for a fake');
      }
    });

    test('me: returns Success with a mocked MeResponse', () async {
      final fake = FakeAuthBff();

      final result = await fake.me();

      expect(result, isA<Success<StandardResponse<MeResponse>>>());
      switch (result) {
        case Success(:final value):
          expect(value.data.userId, isNotEmpty);
          expect(value.data.email, isNotEmpty);
          expect(value.data.roles, isA<List<String>>());
        case Failure():
          fail('me should succeed for a fake');
      }
    });
  });
}
