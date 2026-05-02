import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('LookupItemResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'codigo': 'P',
        'descricao': 'Pai',
      };
      final dto = LookupItemResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should expose canonical BFF shape (id, codigo, descricao)', () {
      final json = {
        'id': 'abc-123',
        'codigo': 'M',
        'descricao': 'Mae',
      };
      final dto = LookupItemResponse.fromJson(json);
      expect(dto.id, equals('abc-123'));
      expect(dto.codigo, equals('M'));
      expect(dto.descricao, equals('Mae'));
    });

    test('should accept empty string descricao (unusual but valid)', () {
      final json = {
        'id': '1',
        'codigo': 'X',
        'descricao': '',
      };
      final dto = LookupItemResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('two responses with same payload should be equal (value semantics)', () {
      final json = {
        'id': '1',
        'codigo': 'P',
        'descricao': 'Pai',
      };
      final a = LookupItemResponse.fromJson(json);
      final b = LookupItemResponse.fromJson(json);
      expect(a, equals(b));
    });
  });
}
