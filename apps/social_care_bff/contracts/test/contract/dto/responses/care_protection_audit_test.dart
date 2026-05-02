import 'dart:convert';

import 'package:test/test.dart';
import 'package:shared/shared.dart';

void main() {
  group('AppointmentResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'date': '2024-03-15T10:30:00Z',
        'professionalId': '660e8400-e29b-41d4-a716-446655440001',
        'type': 'atendimento_individual',
        'summary': 'Avaliacao inicial do paciente com doenca rara',
        'actionPlan': 'Encaminhar para geneticista e agendar retorno',
      };
      final dto = AppointmentResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('ProgramLinkResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'programId': '550e8400-e29b-41d4-a716-446655440000',
        'observation': 'Beneficio ativo desde 2023',
      };
      final dto = ProgramLinkResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional observation null', () {
      final json = {
        'programId': '550e8400-e29b-41d4-a716-446655440000',
        'observation': null,
      };
      final dto = ProgramLinkResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('IngressInfoResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'ingressTypeId': '550e8400-e29b-41d4-a716-446655440000',
        'originName': 'UBS Jardim Paulista',
        'originContact': '1133334444',
        'serviceReason': 'Diagnostico de doenca rara confirmado',
        'linkedSocialPrograms': [
          {
            'programId': '660e8400-e29b-41d4-a716-446655440001',
            'observation': 'Inscricao realizada em janeiro',
          },
        ],
      };
      final dto = IngressInfoResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });

    test('should round-trip with optional fields null and empty programs', () {
      final json = {
        'ingressTypeId': '550e8400-e29b-41d4-a716-446655440000',
        'originName': null,
        'originContact': null,
        'serviceReason': 'Demanda espontanea',
        'linkedSocialPrograms': [],
      };
      final dto = IngressInfoResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });
  });

  group('PlacementRegistryResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'memberId': '660e8400-e29b-41d4-a716-446655440001',
        'startDate': '2023-01-15',
        'endDate': '2023-07-20',
        'reason': 'Acolhimento institucional por vulnerabilidade',
      };
      final dto = PlacementRegistryResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional endDate null', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'memberId': '660e8400-e29b-41d4-a716-446655440001',
        'startDate': '2024-01-01',
        'endDate': null,
        'reason': 'Em andamento',
      };
      final dto = PlacementRegistryResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('PlacementHistoryResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'individualPlacements': [
          {
            'id': '550e8400-e29b-41d4-a716-446655440000',
            'memberId': '660e8400-e29b-41d4-a716-446655440001',
            'startDate': '2023-01-15',
            'endDate': '2023-07-20',
            'reason': 'Acolhimento institucional',
          },
        ],
        'homeLossReport': 'Familia perdeu moradia em enchente',
        'thirdPartyGuardReport': 'Guarda temporaria concedida a tia',
        'adultInPrison': true,
        'adolescentInInternment': false,
      };
      final dto = PlacementHistoryResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });

    test('should round-trip with empty placements and null reports', () {
      final json = {
        'individualPlacements': [],
        'homeLossReport': null,
        'thirdPartyGuardReport': null,
        'adultInPrison': false,
        'adolescentInInternment': false,
      };
      final dto = PlacementHistoryResponse.fromJson(json);
      final result = jsonDecode(jsonEncode(dto));
      expect(result, equals(json));
    });
  });

  group('ViolationReportResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'reportDate': '2024-03-15',
        'incidentDate': '2024-03-10',
        'victimId': '660e8400-e29b-41d4-a716-446655440001',
        'violationType': 'negligencia',
        'descriptionOfFact': 'Falta de acesso a tratamento medico adequado',
        'actionsTaken': 'Notificacao ao Conselho Tutelar',
      };
      final dto = ViolationReportResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional incidentDate null', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'reportDate': '2024-06-01',
        'incidentDate': null,
        'victimId': '660e8400-e29b-41d4-a716-446655440001',
        'violationType': 'discriminacao',
        'descriptionOfFact': 'Paciente impedido de matricula escolar',
        'actionsTaken': 'Encaminhamento ao Ministerio Publico',
      };
      final dto = ViolationReportResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('ReferralResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'date': '2024-03-15',
        'professionalId': '660e8400-e29b-41d4-a716-446655440001',
        'referredPersonId': '770e8400-e29b-41d4-a716-446655440002',
        'destinationService': 'CRAS Regional Centro',
        'reason': 'Acompanhamento sociofamiliar',
        'status': 'pendente',
      };
      final dto = ReferralResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional professionalId null', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'date': '2024-06-01',
        'professionalId': null,
        'referredPersonId': '770e8400-e29b-41d4-a716-446655440002',
        'destinationService': 'Hospital Regional',
        'reason': 'Avaliacao genetica',
        'status': 'concluido',
      };
      final dto = ReferralResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });

  group('AuditTrailEntryResponse', () {
    test('should round-trip with all fields populated', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'aggregateId': '660e8400-e29b-41d4-a716-446655440001',
        'eventType': 'PatientRegistered',
        'actorId': '770e8400-e29b-41d4-a716-446655440002',
        'payload': {'firstName': 'Maria', 'lastName': 'Silva'},
        'occurredAt': '2024-03-15T10:30:00Z',
        'recordedAt': '2024-03-15T10:30:01Z',
      };
      final dto = AuditTrailEntryResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with optional fields null', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'aggregateId': '660e8400-e29b-41d4-a716-446655440001',
        'eventType': 'PatientDischargeReverted',
        'actorId': null,
        'payload': null,
        'occurredAt': '2024-06-01T14:00:00Z',
        'recordedAt': '2024-06-01T14:00:02Z',
      };
      final dto = AuditTrailEntryResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });

    test('should round-trip with complex nested payload', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'aggregateId': '660e8400-e29b-41d4-a716-446655440001',
        'eventType': 'FamilyMemberAdded',
        'actorId': '770e8400-e29b-41d4-a716-446655440002',
        'payload': {
          'personId': '880e8400-e29b-41d4-a716-446655440003',
          'relationship': 'mae',
          'documents': ['CPF', 'RG'],
        },
        'occurredAt': '2024-03-20T09:15:00Z',
        'recordedAt': '2024-03-20T09:15:00Z',
      };
      final dto = AuditTrailEntryResponse.fromJson(json);
      expect(dto.toJson(), equals(json));
    });
  });
}
