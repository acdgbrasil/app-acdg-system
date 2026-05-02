import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('PatientRemote.fromJson — diagnoses field aliasing', () {
    final baseJson = <String, dynamic>{
      'patientId': '550e8400-e29b-41d4-a716-446655440000',
      'personId': '660e8400-e29b-41d4-a716-446655440001',
    };

    test('parses diagnoses from "initialDiagnoses" key (frontend format)', () {
      final json = {
        ...baseJson,
        'initialDiagnoses': [
          {
            'icdCode': 'E70.0',
            'date': '2025-01-01T00:00:00Z',
            'description': 'PKU',
          },
        ],
      };

      final remote = PatientRemote.fromJson(json);

      expect(remote.diagnoses, hasLength(1));
      expect(remote.diagnoses[0]['icdCode'], equals('E70.0'));
    });

    test('parses diagnoses from "diagnoses" key (backend format)', () {
      final json = {
        ...baseJson,
        'diagnoses': [
          {
            'icdCode': 'Q90.0',
            'date': '2024-06-15T00:00:00Z',
            'description': 'Down',
          },
        ],
      };

      final remote = PatientRemote.fromJson(json);

      expect(remote.diagnoses, hasLength(1));
      expect(remote.diagnoses[0]['icdCode'], equals('Q90.0'));
    });

    test('defaults to empty list when neither key is present', () {
      final remote = PatientRemote.fromJson(baseJson);

      expect(remote.diagnoses, isEmpty);
    });

    test('prefers initialDiagnoses over diagnoses when both present', () {
      final json = {
        ...baseJson,
        'initialDiagnoses': [
          {
            'icdCode': 'E70.0',
            'date': '2025-01-01T00:00:00Z',
            'description': 'PKU',
          },
        ],
        'diagnoses': [
          {
            'icdCode': 'WRONG',
            'date': '2020-01-01T00:00:00Z',
            'description': 'Should not be used',
          },
        ],
      };

      final remote = PatientRemote.fromJson(json);

      expect(remote.diagnoses, hasLength(1));
      expect(remote.diagnoses[0]['icdCode'], equals('E70.0'));
    });
  });
}
