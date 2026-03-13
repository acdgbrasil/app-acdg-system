import 'package:core/core.dart';
import 'package:shared/src/domain/value_objects/nis.dart';
import 'package:test/test.dart';

void main() {
  group('Nis Value Object', () {
    test('creates successfully for a valid NIS', () {
      final valid = '120.66020.58-5';
      final result = Nis.create(valid);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.value, '12066020585');
      expect(result.valueOrNull!.formatted, valid);
    });

    test('fails for empty input', () {
      final result = Nis.create('   ');
      expect(result.isFailure, isTrue);
    });

    test('fails for invalid length', () {
      final result = Nis.create('1234');
      expect(result.isFailure, isTrue);
    });

    test('fails for blacklisted sequence', () {
      final result = Nis.create('22222222222');
      expect(result.isFailure, isTrue);
    });

    test('fails for invalid checksum', () {
      final result = Nis.create('12066020581');
      expect(result.isFailure, isTrue);
    });
  });
}
