import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('FakeHealthBff', () {
    test('implements HealthContract', () {
      final HealthContract fake = FakeHealthBff();
      expect(fake, isA<HealthContract>());
    });

    test('checkHealth: returns Success', () async {
      final fake = FakeHealthBff();

      final result = await fake.checkHealth();

      expect(result, isA<Success<void>>());
    });

    test('checkReady: returns Success', () async {
      final fake = FakeHealthBff();

      final result = await fake.checkReady();

      expect(result, isA<Success<void>>());
    });
  });
}
