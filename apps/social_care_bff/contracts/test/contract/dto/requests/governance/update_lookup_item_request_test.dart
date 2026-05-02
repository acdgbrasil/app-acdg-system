import 'package:test/test.dart';
import 'package:shared/shared.dart';

/// Round-trip tests for `UpdateLookupItemRequest`.
///
/// Contract A — Ação #33: PUT `/api/lookups/{tableName}/{id}` (admin).
/// Payload: `UpdateLookupItemPayload { codigo?, descricao? }`.
/// Both fields optional — supports partial updates.
///
/// These tests MUST FAIL initially — the DTO class does not yet exist.
void main() {
  group('UpdateLookupItemRequest', () {
    test('should round-trip with both fields populated', () {
      final json = {
        'codigo': 'DEF_INTELECTUAL',
        'descricao': 'Deficiencia intelectual',
      };
      final dto = UpdateLookupItemRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with only codigo populated', () {
      final json = {
        'codigo': 'DEF_VISUAL',
        'descricao': null,
      };
      final dto = UpdateLookupItemRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with only descricao populated', () {
      final json = {
        'codigo': null,
        'descricao': 'Deficiencia auditiva',
      };
      final dto = UpdateLookupItemRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with both fields null', () {
      final json = {
        'codigo': null,
        'descricao': null,
      };
      final dto = UpdateLookupItemRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('fromJson reads canonical BFF shape correctly', () {
      final json = {
        'codigo': 'REL_PAI',
        'descricao': 'Pai',
      };

      final dto = UpdateLookupItemRequest.fromJson(json);

      expect(dto.codigo, 'REL_PAI');
      expect(dto.descricao, 'Pai');
    });
  });
}
