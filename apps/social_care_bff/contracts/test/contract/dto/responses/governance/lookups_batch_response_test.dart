import 'dart:convert';

import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('LookupsBatchResponse', () {
    test('should round-trip with 2 tables and 2 items each', () {
      final json = {
        'tables': {
          'parentesco': [
            {'id': '1', 'codigo': 'P', 'descricao': 'Pai'},
            {'id': '2', 'codigo': 'M', 'descricao': 'Mae'},
          ],
          'ingresso': [
            {'id': '1', 'codigo': 'D', 'descricao': 'Demanda espontanea'},
            {'id': '2', 'codigo': 'E', 'descricao': 'Encaminhamento'},
          ],
        },
      };
      final dto = LookupsBatchResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto)) as Map<String, dynamic>;
      expect(result, equals(json));
    });

    test('should expose tables map keyed by table name', () {
      final json = {
        'tables': {
          'parentesco': [
            {'id': '1', 'codigo': 'P', 'descricao': 'Pai'},
          ],
        },
      };
      final dto = LookupsBatchResponse.fromJson(json);
      expect(dto.tables.keys, contains('parentesco'));
      expect(dto.tables['parentesco'], hasLength(1));
      expect(dto.tables['parentesco']!.first.codigo, equals('P'));
      expect(dto.tables['parentesco']!.first.descricao, equals('Pai'));
    });

    test('should round-trip with empty tables map', () {
      final json = {'tables': <String, dynamic>{}};
      final dto = LookupsBatchResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto)) as Map<String, dynamic>;
      expect(result, equals(json));
      expect(dto.tables, isEmpty);
    });

    test('should round-trip with table containing empty list', () {
      final json = {
        'tables': {
          'parentesco': <Map<String, dynamic>>[],
        },
      };
      final dto = LookupsBatchResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto)) as Map<String, dynamic>;
      expect(result, equals(json));
      expect(dto.tables['parentesco'], isEmpty);
    });

    test('items inside batch should be LookupItemResponse', () {
      final json = {
        'tables': {
          'parentesco': [
            {'id': '1', 'codigo': 'P', 'descricao': 'Pai'},
          ],
        },
      };
      final dto = LookupsBatchResponse.fromJson(json);
      final first = dto.tables['parentesco']!.first;
      expect(first, isA<LookupItemResponse>());
      expect(first.id, equals('1'));
    });
  });
}
