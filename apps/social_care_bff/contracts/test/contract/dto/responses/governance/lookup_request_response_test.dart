import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('LookupRequestResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'tableName': 'parentesco',
        'codigo': 'TIO',
        'descricao': 'Tio',
        'justificativa': 'Faltando no cadastro de familiares',
        'status': 'pending',
        'createdAt': '2024-04-01T10:30:00Z',
        'requestedBy': '660e8400-e29b-41d4-a716-446655440001',
      };
      final dto = LookupRequestResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional justificativa null', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'tableName': 'ingresso',
        'codigo': 'W',
        'descricao': 'WhatsApp',
        'justificativa': null,
        'status': 'approved',
        'createdAt': '2024-04-05T09:15:00Z',
        'requestedBy': '660e8400-e29b-41d4-a716-446655440001',
      };
      final dto = LookupRequestResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should accept rejected status', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'tableName': 'parentesco',
        'codigo': 'XPTO',
        'descricao': 'Invalido',
        'justificativa': 'teste',
        'status': 'rejected',
        'createdAt': '2024-04-10T14:00:00Z',
        'requestedBy': '660e8400-e29b-41d4-a716-446655440001',
      };
      final dto = LookupRequestResponse.fromJson(json);
      expect(dto.status, equals('rejected'));
    });

    test('should preserve ISO-8601 createdAt verbatim', () {
      final json = {
        'id': '1',
        'tableName': 'parentesco',
        'codigo': 'C',
        'descricao': 'Cuidador',
        'justificativa': null,
        'status': 'pending',
        'createdAt': '2024-04-16T18:45:33.123Z',
        'requestedBy': 'worker-1',
      };
      final dto = LookupRequestResponse.fromJson(json);
      expect(dto.createdAt, equals('2024-04-16T18:45:33.123Z'));
    });
  });
}
