import 'package:test/test.dart';
import 'package:shared/shared.dart';

/// Round-trip tests for `AdmitPatientRequest`.
///
/// Contract A — Ação #9: POST `/api/patients/{id}/admit`.
/// Payload: `AdmitPayload { reason, admittedAt }`.
///
/// These tests MUST FAIL initially — the DTO class does not yet exist.
/// Wave 1 (implementer) creates `AdmitPatientRequest` and exports it from
/// `package:shared/shared.dart`, making these tests pass.
void main() {
  group('AdmitPatientRequest', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'reason': 'Primeira admissao apos triagem',
        'admittedAt': '2026-04-17T10:00:00.000Z',
        'notes': 'Paciente encaminhado pela UBS central',
      };
      final dto = AdmitPatientRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with notes null', () {
      final json = {
        'reason': 'Admissao por agravamento clinico',
        'admittedAt': '2026-01-05T08:30:00.000Z',
        'notes': null,
      };
      final dto = AdmitPatientRequest.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('fromJson reads canonical BFF shape correctly', () {
      final json = {
        'reason': 'readmissao planejada',
        'admittedAt': '2026-04-17T10:00:00.000Z',
        'notes': null,
      };

      final dto = AdmitPatientRequest.fromJson(json);

      expect(dto.reason, 'readmissao planejada');
      expect(dto.admittedAt, '2026-04-17T10:00:00.000Z');
      expect(dto.notes, isNull);
    });

    test('toJson produces canonical BFF shape', () {
      final dto = AdmitPatientRequest(
        reason: 'Admissao inicial',
        admittedAt: '2026-04-17T10:00:00.000Z',
        notes: 'Observacoes da equipe',
      );

      final json = dto.toJson();

      expect(json['reason'], 'Admissao inicial');
      expect(json['admittedAt'], '2026-04-17T10:00:00.000Z');
      expect(json['notes'], 'Observacoes da equipe');
    });
  });
}
