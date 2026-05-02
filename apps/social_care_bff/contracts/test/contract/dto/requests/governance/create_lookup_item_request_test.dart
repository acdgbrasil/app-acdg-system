import 'package:test/test.dart';
import 'package:shared/shared.dart';

/// Round-trip tests for `CreateLookupItemRequest`.
///
/// Contract A — Ação #32: POST `/api/lookups/{tableName}` (admin).
/// Payload: `CreateLookupItemPayload { codigo, descricao }`.
///
/// These tests MUST FAIL initially — the DTO class does not yet exist.
void main() {
  group('CreateLookupItemRequest', () {
    test('should round-trip with required fields', () {
      final json = {
        'codigo': 'DEF_NEUROLOGICA',
        'descricao': 'Deficiencia neurologica',
      };
      final dto = CreateLookupItemRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('fromJson reads canonical BFF shape correctly', () {
      final json = {
        'codigo': 'REL_MAE',
        'descricao': 'Mae',
      };

      final dto = CreateLookupItemRequest.fromJson(json);

      expect(dto.codigo, 'REL_MAE');
      expect(dto.descricao, 'Mae');
    });

    test('toJson produces canonical BFF shape', () {
      final dto = CreateLookupItemRequest(
        codigo: 'VIOLACAO_FISICA',
        descricao: 'Violacao fisica',
      );

      final json = dto.toJson();

      expect(json['codigo'], 'VIOLACAO_FISICA');
      expect(json['descricao'], 'Violacao fisica');
    });
  });
}
