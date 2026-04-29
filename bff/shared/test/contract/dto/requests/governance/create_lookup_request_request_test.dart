import 'package:test/test.dart';
import 'package:shared/shared.dart';

/// Round-trip tests for `CreateLookupRequestRequest`.
///
/// Contract A — Ação #36: POST `/api/lookup-requests`.
/// Payload for creating a governance request (social_worker asks admin to
/// add a new lookup item).
/// Shape: `{ tableName, codigo, descricao, justificativa? }`.
///
/// These tests MUST FAIL initially — the DTO class does not yet exist.
void main() {
  group('CreateLookupRequestRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'tableName': 'deficiency_types',
        'codigo': 'DEF_MULTIPLA',
        'descricao': 'Deficiencia multipla',
        'justificativa':
            'Caso clinico registrado em 2026-03 sem opcao adequada na tabela',
      };
      final dto = CreateLookupRequestRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with justificativa null', () {
      final json = {
        'tableName': 'relationship_types',
        'codigo': 'REL_PADRASTO',
        'descricao': 'Padrasto',
        'justificativa': null,
      };
      final dto = CreateLookupRequestRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('fromJson reads canonical BFF shape correctly', () {
      final json = {
        'tableName': 'violation_types',
        'codigo': 'VIOL_DIGITAL',
        'descricao': 'Violacao digital / cyberbullying',
        'justificativa': 'Demanda crescente de casos digitais',
      };

      final dto = CreateLookupRequestRequest.fromJson(json);

      expect(dto.tableName, 'violation_types');
      expect(dto.codigo, 'VIOL_DIGITAL');
      expect(dto.descricao, 'Violacao digital / cyberbullying');
      expect(dto.justificativa, 'Demanda crescente de casos digitais');
    });

    test('toJson produces canonical BFF shape', () {
      final dto = CreateLookupRequestRequest(
        tableName: 'housing_types',
        codigo: 'CASA_COLETIVA',
        descricao: 'Casa coletiva',
        justificativa: 'Usado em abrigos coletivos',
      );

      final json = dto.toJson();

      expect(json['tableName'], 'housing_types');
      expect(json['codigo'], 'CASA_COLETIVA');
      expect(json['descricao'], 'Casa coletiva');
      expect(json['justificativa'], 'Usado em abrigos coletivos');
    });
  });
}
